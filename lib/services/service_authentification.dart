import 'package:flutter/foundation.dart';

import '../donnees/base_de_donnees.dart';
import '../modeles/catalogue.dart';
import '../modeles/planning_semaine.dart';
import '../modeles/referentiel.dart';
import '../modeles/utilisateur.dart';

/// «contrôleur» ServiceAuthentification — cas « Créer un compte » et « S'authentifier » (séquence 1).
class ServiceAuthentification extends ChangeNotifier {
  ServiceAuthentification(this._base, this._referentiel);

  final BaseDeDonnees _base;
  final Referentiel _referentiel;
  Utilisateur? _courant;

  static const _cleSession = 'session';

  Utilisateur? get utilisateurCourant => _courant;

  /// « Continuer sans compte » (séquence 1, messages 3 à 6) : crée un visiteur, sans e-mail
  /// ni mot de passe, enregistré seulement sur le téléphone.
  Future<Utilisateur> demarrerVisiteur(bool consentement) async {
    if (!consentement) {
      throw ErreurAuthentification('Cochez la case pour accepter l’utilisation de vos données de santé.');
    }
    final u = Utilisateur(consentementSante: true, estVisiteur: true); // 4 : créer(estVisiteur = vrai)
    await enregistrer(u); // 5 : enregistrer sur le téléphone
    await _base.definirReglage(_cleSession, u.id);
    _courant = u;
    notifyListeners();
    return u; // 6 : utilisateur visiteur
  }

  /// Crée le compte (écran 02). Si l'utilisateur courant est un visiteur, c'est LUI qui devient
  /// inscrit (séquence 1, opt, messages 20 à 22) : même id, profil, planning et liste conservés.
  /// Lève [ErreurAuthentification] si l'adresse est déjà utilisée ou si les règles ne sont pas
  /// respectées ; dans ce cas le visiteur garde ses données, inchangées.
  Future<Utilisateur> inscrire(String nom, String email, String motDePasse, bool consentement) async {
    if (!consentement) {
      throw ErreurAuthentification('Cochez la case pour accepter l’utilisation de vos données de santé.');
    }
    if (await _chercher(email) != null) {
      throw ErreurAuthentification('Un compte existe déjà avec cette adresse. Choisissez-en une autre ou connectez-vous.');
    }
    final visiteur = _courant;
    if (visiteur != null && visiteur.estVisiteur) {
      if (!visiteur.creerCompte(nom, email, motDePasse)) { // 21 : creerCompte(nom, email, motDePasse)
        throw ErreurAuthentification('Vérifiez votre nom, votre adresse e-mail et votre mot de passe.');
      }
      visiteur.seConnecter(email, motDePasse);
      await enregistrer(visiteur); // 22 : enregistrer(compte)
      return visiteur; // 23 : compte créé
    }
    final u = Utilisateur(consentementSante: consentement);
    if (!u.creerCompte(nom, email, motDePasse)) {
      throw ErreurAuthentification('Vérifiez votre nom, votre adresse e-mail et votre mot de passe.');
    }
    u.seConnecter(email, motDePasse);
    await enregistrer(u);
    await _base.definirReglage(_cleSession, u.id);
    _courant = u;
    notifyListeners();
    return u;
  }

  /// Séquence 1, messages 5 à 13 : cherche le compte, puis l'utilisateur vérifie le mot de passe.
  /// Renvoie null si les identifiants sont incorrects.
  Future<Utilisateur?> connecter(String email, String motDePasse) async {
    final u = await _chercher(email); // 6-7 : chercher(email)
    if (u == null || !u.seConnecter(email, motDePasse)) return null; // 8-9 : seConnecter, résultat
    await _base.definirReglage(_cleSession, u.id);
    _courant = u;
    notifyListeners();
    return u; // 10 : utilisateur (et profilComplet via u.profil?.estComplet())
  }

  /// Au démarrage : reprend la session enregistrée, s'il y en a une.
  Future<Utilisateur?> restaurerSession() async {
    final id = await _base.reglage(_cleSession);
    if (id == null) return null;
    final j = await _base.lire(BaseDeDonnees.utilisateurs, id);
    if (j == null) return null;
    final u = Utilisateur.depuisJson(j, _referentiel);
    await _chargerPlannings(u);
    _courant = u;
    notifyListeners();
    return u;
  }

  void seDeconnecter() {
    _courant?.seDeconnecter();
    _courant = null;
    _base.definirReglage(_cleSession, null);
    notifyListeners();
  }

  /// Supprime le compte et toutes ses données : profil, plannings, liste et achats.
  /// Pour un visiteur, c'est « Effacer mes données ».
  Future<void> supprimerCompte() async {
    final u = _courant;
    if (u == null) return;
    u.supprimerCompte();
    await _base.supprimer(BaseDeDonnees.utilisateurs, u.id);
    await _base.supprimer(BaseDeDonnees.plannings, u.id);
    await _base.supprimer(BaseDeDonnees.listes, u.id);
    await _base.supprimer(BaseDeDonnees.achats, u.id);
    await _base.definirReglage(_cleSession, null);
    _courant = null;
    notifyListeners();
  }

  /// Enregistre le compte, son profil et ses plannings.
  Future<void> enregistrer(Utilisateur u) async {
    await _base.enregistrer(BaseDeDonnees.utilisateurs, u.id, u.versJson());
    await _base.enregistrer(BaseDeDonnees.plannings, u.id, {
      'plannings': [for (final p in u.plannings) p.versJson()],
    });
    notifyListeners();
  }

  /// Migration de la base : les comptes enregistrés avant l'accès visiteur reçoivent
  /// estVisiteur = faux. Aucune donnée n'est supprimée. À appeler au démarrage.
  static Future<void> migrer(BaseDeDonnees base) async {
    const cle = 'versionSchema';
    final version = int.tryParse(await base.reglage(cle) ?? '') ?? 1;
    if (version < 2) {
      for (final j in await base.lireTout(BaseDeDonnees.utilisateurs)) {
        if (!j.containsKey('estVisiteur')) {
          await base.enregistrer(BaseDeDonnees.utilisateurs, j['id'] as String, {...j, 'estVisiteur': false});
        }
      }
    }
    await base.definirReglage(cle, '2');
  }

  Future<Utilisateur?> _chercher(String email) async {
    final cherche = email.trim().toLowerCase();
    for (final j in await _base.lireTout(BaseDeDonnees.utilisateurs)) {
      if (j['email'] == cherche) {
        final u = Utilisateur.depuisJson(j, _referentiel);
        await _chargerPlannings(u);
        return u;
      }
    }
    return null;
  }

  Future<void> _chargerPlannings(Utilisateur u) async {
    final j = await _base.lire(BaseDeDonnees.plannings, u.id);
    if (j == null) return;
    final Catalogue? catalogue = u.profil?.enseigne?.catalogue;
    u.restaurerPlannings([
      for (final p in j['plannings'] as List)
        PlanningSemaine.depuisJson(p as Map<String, dynamic>, _referentiel, catalogue: catalogue),
    ]);
  }
}

class ErreurAuthentification implements Exception {
  ErreurAuthentification(this.message);
  final String message;

  @override
  String toString() => message;
}
