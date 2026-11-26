import 'package:flutter/foundation.dart';

import '../externes/agent_ia.dart';
import '../modeles/catalogue.dart';
import '../modeles/enumerations.dart';
import '../modeles/planning_semaine.dart';
import '../modeles/profil_nutritionnel.dart';
import '../modeles/recette.dart';
import '../modeles/referentiel.dart';
import '../modeles/repas.dart';
import '../modeles/utilisateur.dart';
import '../outils/horloge.dart';
import 'service_authentification.dart';
import 'service_courses.dart';

/// «contrôleur» ServicePlanning — cas « Générer le planning » (séquence 3) et
/// « Remplacer un repas » (séquence 4). Il utilise l'agent IA, mais c'est lui seul
/// qui décide qu'une recette est sûre : « l'IA propose, le code vérifie ».
class ServicePlanning extends ChangeNotifier {
  ServicePlanning(this._agent, this._auth, this._courses, this._referentiel);

  final AgentIA _agent;
  final ServiceAuthentification _auth;
  final ServiceCourses _courses;
  final Referentiel _referentiel;

  bool _enCours = false;
  String? _erreur;
  Depassement? _depassement;

  bool get enCours => _enCours;

  /// Message à afficher avec le bouton « Réessayer » si l'agent n'a pas répondu.
  String? get erreur => _erreur;

  /// Écart au budget et repas les plus chers, si le panier dépasse le budget.
  Depassement? get depassement => _depassement;

  PlanningSemaine? get planning => _auth.utilisateurCourant?.planningCourant;

  /// Séquence 3. En cas d'erreur de l'agent, l'ancien planning reste en place
  /// et [erreur] est rempli (alt « pas de réponse »).
  Future<PlanningSemaine> genererSemaine(Utilisateur u) async {
    final p = u.profil;
    if (p == null || !p.estComplet()) throw StateError('Profil incomplet');
    _enCours = true;
    _erreur = null;
    notifyListeners();
    try {
      final menus = await _agent.composerMenus(p); // 5 : composerMenus(profil)
      if (menus.length != PlanningSemaine.nombreDeRepas) {
        throw ErreurAgentIA('L’agent IA n’a pas proposé 21 repas.');
      }
      for (final repas in menus) {
        await _rendreSur(repas, p, menus); // 10 à 17 : filtre strict et équipement
      }
      final planning = PlanningSemaine( // 18 : créer(dateDebut, cibleKcal, 21 repas)
        dateDebut: lundiDe(maintenant()),
        cibleKcalJour: p.besoinKcal,
        repas: menus,
        catalogue: p.enseigne?.catalogue,
      );
      _calculerDepassement(planning, p); // 19 à 21 : coutEstime(), écart au budget
      u.ajouterPlanning(planning);
      await _auth.enregistrer(u); // 22 : enregistrer(planning)
      await _courses.oublierListe();
      return planning; // 23 : planning
    } on ErreurAgentIA catch (e) {
      _erreur = e.message; // 6 à 8 : échec, bouton « Réessayer », ancien planning conservé
      rethrow;
    } catch (e) {
      _erreur = e is ErreurPlanning ? e.message : 'La génération a échoué. Réessayez.';
      rethrow;
    } finally {
      _enCours = false;
      notifyListeners();
    }
  }

  /// Vérifie un repas proposé par l'agent ; le remplace tant qu'il n'est pas sûr.
  Future<void> _rendreSur(Repas repas, ProfilNutritionnel p, List<Repas> menus) async {
    final essayees = <Recette>{};
    while (true) {
      final r = repas.recette;
      essayees.add(r);
      final interdit = r.contientAllergene(p.allergies) || // 10
          r.contientIngredient(p.exclus) || // 11
          !r.convientAuRegime(p.regime);
      if (!interdit) {
        final manquants = r.equipementsManquants(p.equipements); // 14-15
        final adaptations = await _agent.adapterRecette(r, manquants); // 16-17
        final adaptees = adaptations.where((a) => a.type == TypeAdaptation.equipement).length;
        if (adaptees >= manquants.length) {
          repas.ajouterAdaptations(adaptations);
          return;
        }
        // Un appareil manque et aucune méthode ne le remplace : la recette est retirée.
      }
      final memeJour = {
        for (final x in menus)
          if (!identical(x, repas) && memeJourQue(x, repas)) x.recette,
      };
      final remplacante = await _premiereCompatible(repas, p, {...essayees, ...memeJour}); // 12-13
      if (remplacante == null) {
        throw ErreurPlanning('Aucune recette compatible pour le ${repas.type.libelle.toLowerCase()}. '
            'Assouplissez vos contraintes dans le profil.');
      }
      repas.changerRecette(remplacante);
    }
  }

  /// Demande des recettes à l'agent (1, puis 5, puis 25) et garde la première qui est sûre.
  Future<Recette?> _premiereCompatible(Repas repas, ProfilNutritionnel p, Set<Recette> exclues) async {
    for (final n in [1, 5, 25]) {
      for (final r in await _agent.proposerRecettes(repas, n)) {
        if (exclues.contains(r)) continue;
        if (await _verifierRecette(r, p)) return r;
        exclues.add(r);
      }
    }
    return null;
  }

  /// Opération privée : seul ServicePlanning décide qu'une recette est sûre pour l'utilisateur
  /// (allergènes, aliments exclus, régime, appareils remplaçables).
  Future<bool> _verifierRecette(Recette r, ProfilNutritionnel p) async {
    if (r.contientAllergene(p.allergies) || r.contientIngredient(p.exclus) || !r.convientAuRegime(p.regime)) {
      return false;
    }
    final manquants = r.equipementsManquants(p.equipements);
    if (manquants.isEmpty) return true;
    final adaptations = await _agent.adapterRecette(r, manquants);
    return adaptations.where((a) => a.type == TypeAdaptation.equipement).length >= manquants.length;
  }

  /// Séquence 4, messages 2 à 6 : l'agent propose 5 recettes, le service en garde 3 compatibles
  /// (et différentes des autres repas du même jour).
  Future<List<Recette>> proposerRemplacements(Repas repas) async {
    final p = _auth.utilisateurCourant!.profil!;
    final planning = this.planning!;
    final memeJour = {for (final x in planning.repasDuJour(repas.jour)) x.recette};
    final gardees = <Recette>[];
    final vues = <Recette>{...memeJour};
    for (final n in [5, 25]) {
      for (final r in await _agent.proposerRecettes(repas, n)) { // 3-4
        if (gardees.length == 3) break;
        if (!vues.add(r)) continue;
        if (await _verifierRecette(r, p)) gardees.add(r); // 5 : verifierRecette(recette, profil)
      }
      if (gardees.length == 3) break;
    }
    return gardees; // 6 : 3 recettes compatibles
  }

  /// Écart de prix du panier de la semaine si [recette] remplace le repas.
  double ecartDePrix(Repas repas, Recette recette) {
    final planning = this.planning!;
    final copie = PlanningSemaine.depuisJson(planning.versJson(), _referentiel, catalogue: planning.catalogue);
    copie.remplacerRepas(copie.repasDe(repas.jour, repas.type), recette);
    return ((copie.coutEstime() - planning.coutEstime()) * 1000).round() / 1000;
  }

  /// Séquence 4, messages 9 à 15 : remplace le repas, recalcule le coût et,
  /// si la liste de courses existe déjà, la génère de nouveau.
  Future<void> remplacer(Repas repas, Recette choix) async {
    final u = _auth.utilisateurCourant!;
    final p = u.profil!;
    final planning = this.planning!;
    planning.remplacerRepas(repas, choix); // 10-11 : remplacerRepas → changerRecette
    repas.ajouterAdaptations(await _agent.adapterRecette(choix, choix.equipementsManquants(p.equipements)));
    _calculerDepassement(planning, p); // 12-13 : coutEstime()
    await _auth.enregistrer(u);
    if (_courses.liste != null) await _courses.genererListe(planning); // 14 : generer(planning)
    notifyListeners();
  }

  void _calculerDepassement(PlanningSemaine planning, ProfilNutritionnel p) {
    final cout = planning.coutEstime();
    final budget = p.budgetHebdoDT ?? 0;
    if (cout <= budget) {
      _depassement = null;
      return;
    }
    final catalogue = planning.catalogue;
    final tries = [...planning.repas]
      ..sort((a, b) => coutRepas(b, catalogue).compareTo(coutRepas(a, catalogue)));
    final plusChers = <Repas>[];
    for (final r in tries) {
      if (plusChers.every((x) => x.recette != r.recette)) plusChers.add(r);
      if (plusChers.length == 3) break;
    }
    _depassement = Depassement(ecart: ((cout - budget) * 1000).round() / 1000, plusChers: plusChers);
  }

  /// Recalcule l'écart au budget du planning courant (au démarrage, après un changement de profil).
  void actualiser() {
    final p = _auth.utilisateurCourant?.profil;
    final planning = this.planning;
    if (p != null && planning != null) _calculerDepassement(planning, p);
    notifyListeners();
  }

  /// Coût d'un repas au prorata des produits utilisés (pour classer les repas les plus chers).
  static double coutRepas(Repas repas, Catalogue? catalogue) {
    if (catalogue == null) return 0;
    var total = 0.0;
    final facteur = repas.portions / repas.recette.portions;
    for (final l in repas.recette.lignes) {
      final produit = catalogue.rechercherProduit(l.ingredient);
      if (produit == null) continue;
      total += l.quantite * facteur * produit.prixDT / produit.contenu.quantite;
    }
    return total;
  }
}

bool memeJourQue(Repas a, Repas b) => memeJour(a.jour, b.jour);

/// Le panier dépasse le budget : de combien, et quels repas coûtent le plus.
class Depassement {
  Depassement({required this.ecart, required this.plusChers});
  final double ecart;
  final List<Repas> plusChers;
}

class ErreurPlanning implements Exception {
  ErreurPlanning(this.message);
  final String message;

  @override
  String toString() => message;
}
