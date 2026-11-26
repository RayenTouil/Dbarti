import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../donnees/base_de_donnees.dart';
import '../externes/service_livraison_enseigne.dart';
import '../modeles/achat.dart';
import '../modeles/article_course.dart';
import '../modeles/catalogue.dart';
import '../modeles/enumerations.dart';
import '../modeles/liste_courses.dart';
import '../modeles/planning_semaine.dart';
import '../modeles/referentiel.dart';
import 'service_authentification.dart';

/// «contrôleur» ServiceCourses — cas « Générer la liste de courses chiffrée » (séquence 5)
/// et « Faire ses courses » (séquence 6).
class ServiceCourses extends ChangeNotifier {
  ServiceCourses(this._base, this._auth, this._livraison, this._referentiel);

  final BaseDeDonnees _base;
  final ServiceAuthentification _auth;
  final ServiceLivraisonEnseigne _livraison;
  final Referentiel _referentiel;

  ListeCourses? _liste;
  String? _planningDeLaListe;
  bool _prixIndicatifs = false;
  String? _lien;

  ListeCourses? get liste => _liste;

  /// Catalogue de plus de 7 jours : les prix sont « indicatifs ».
  bool get prixIndicatifs => _prixIndicatifs;

  /// Lien à ouvrir après l'achat : site de l'enseigne (livraison) ou itinéraire (magasin).
  String? get lien => _lien;

  double get budget => _auth.utilisateurCourant?.profil?.budgetHebdoDT ?? 0;

  /// Séquence 5 : additionne les quantités des 21 repas, associe les produits du catalogue
  /// de l'enseigne, calcule le total et le reste du budget.
  Future<ListeCourses> genererListe(PlanningSemaine p) async {
    final enseigne = _auth.utilisateurCourant?.profil?.enseigne;
    final Catalogue catalogue = enseigne?.catalogue ?? p.catalogue!;
    p.catalogue ??= catalogue;
    final ancienne = _planningDeLaListe == p.id ? _liste : null;
    final liste = ListeCourses(catalogue: catalogue); // 6 : créer()
    _prixIndicatifs = !catalogue.estAJour(); // 7-8 : estAJour()
    if (ancienne != null) {
      // Les articles « déjà à la maison » restent cochés quand la liste est recalculée.
      liste.generer(p);
      final aLaMaison = {for (final a in ancienne.articles) if (a.dejaALaMaison) a.ingredient};
      for (final a in liste.articles) {
        if (aLaMaison.contains(a.ingredient)) a.marquerDejaALaMaison();
      }
    } else {
      liste.generer(p); // 3 à 13 : ingrédients, additionner, rechercherProduit()
    }
    liste.calculerTotal(); // 14
    _liste = liste;
    _planningDeLaListe = p.id;
    await _enregistrer();
    notifyListeners();
    return liste; // 17 : articlesParRayon(), total, reste
  }

  /// Reprend la liste enregistrée si elle correspond au planning courant.
  Future<void> restaurer(PlanningSemaine p) async {
    final u = _auth.utilisateurCourant;
    if (u == null) return;
    final j = await _base.lire(BaseDeDonnees.listes, u.id);
    final catalogue = u.profil?.enseigne?.catalogue;
    if (j == null || j['planning'] != p.id || catalogue == null) return;
    _liste = ListeCourses.depuisJson(j['liste'] as Map<String, dynamic>, _referentiel, catalogue);
    _planningDeLaListe = p.id;
    _prixIndicatifs = !catalogue.estAJour();
    notifyListeners();
  }

  /// Un nouveau planning remplace l'ancien : la liste sera recalculée à l'ouverture de l'onglet.
  Future<void> oublierListe() async {
    _liste = null;
    _planningDeLaListe = null;
    final u = _auth.utilisateurCourant;
    if (u != null) await _base.supprimer(BaseDeDonnees.listes, u.id);
    notifyListeners();
  }

  /// Déconnexion : la liste reste enregistrée, mais n'est plus affichée.
  Future<void> oublierListeEnMemoire() async {
    _liste = null;
    _planningDeLaListe = null;
    _lien = null;
    notifyListeners();
  }

  /// « Déjà à la maison » (séquence 5, messages 19 à 22) : l'article est barré et retiré du total.
  Future<void> marquerArticle(ArticleCourse a) async {
    a.marquerDejaALaMaison();
    _liste?.calculerTotal(); // 21 : calculerTotal()
    await _enregistrer();
    notifyListeners();
  }

  /// Séquence 6 : crée l'achat ; en LIVRAISON, copie la liste et prépare le lien vers le site
  /// de l'enseigne ; en MAGASIN, prépare le lien d'itinéraire.
  Future<Achat> acheter(ListeCourses l, ModeAchat mode) async {
    final u = _auth.utilisateurCourant!;
    final montant = l.calculerTotal(); // 5-6 : calculerTotal()
    final achat = Achat(mode: mode, montantDT: montant, enseigne: u.profil!.enseigne!, liste: l); // 7 : créer
    final achats = await _base.lire(BaseDeDonnees.achats, u.id);
    await _base.enregistrer(BaseDeDonnees.achats, u.id, {
      'achats': [...?achats?['achats'] as List?, achat.versJson()],
    });
    if (mode == ModeAchat.livraison) {
      await Clipboard.setData(ClipboardData(text: achat.copierListe())); // 8-9 : copierListe()
      _lien = await _livraison.ouvrirPanier(l); // 10-11 : ouvrirPanier(liste)
    } else {
      _lien = achat.ouvrirEnseigne(); // 16-17 : ouvrirEnseigne()
    }
    notifyListeners();
    return achat;
  }

  Future<void> _enregistrer() async {
    final u = _auth.utilisateurCourant;
    final l = _liste;
    if (u == null || l == null) return;
    await _base.enregistrer(BaseDeDonnees.listes, u.id, {'planning': _planningDeLaListe, 'liste': l.versJson()});
  }
}
