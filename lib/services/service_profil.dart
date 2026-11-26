import 'package:flutter/foundation.dart';

import '../modeles/enseigne.dart';
import '../modeles/enumerations.dart';
import '../modeles/equipement.dart';
import '../modeles/ingredient.dart';
import '../modeles/profil_nutritionnel.dart';
import '../modeles/referentiel.dart';
import '../modeles/utilisateur.dart';
import 'service_authentification.dart';

/// «contrôleur» ServiceProfil — cas « Remplir le questionnaire de profil » (séquence 2)
/// et « Gérer son profil » (écran 18).
class ServiceProfil extends ChangeNotifier {
  ServiceProfil(this._auth, this._referentiel);

  final ServiceAuthentification _auth;
  final Referentiel _referentiel;
  ProfilNutritionnel _brouillon = ProfilNutritionnel();

  /// Réponses en cours de saisie. Le profil n'est rattaché à l'utilisateur qu'à la fin.
  ProfilNutritionnel get brouillon => _brouillon;

  /// Messages d'erreur de la dernière étape, par champ.
  Map<String, String> get erreurs => _brouillon.erreurs;

  /// Commence le questionnaire : vide pour un nouveau compte, ou copie du profil à modifier.
  void demarrer() {
    final existant = _auth.utilisateurCourant?.profil;
    _brouillon = existant == null ? ProfilNutritionnel() : existant.copie(_referentiel);
    notifyListeners();
  }

  /// Enregistre les réponses d'une étape puis la valide (séquence 2, messages 3 à 9).
  /// Faux si une valeur est hors limites : le message est dans [erreurs].
  /// Étape 4 passée (`{'passer': true}`) : valeurs par défaut.
  bool enregistrerEtape(int etape, Map<String, dynamic> reponses) {
    final p = _brouillon;
    if (reponses['passer'] == true && etape == 4) {
      p
        ..cuisinesPreferees = const []
        ..tempsMaxMinutes = ProfilNutritionnel.tempsMaxParDefaut;
    }
    for (final MapEntry(:key, :value) in reponses.entries) {
      switch (key) {
        case 'age':
          p.age = value as int?;
        case 'sexe':
          p.sexe = value as Sexe?;
        case 'tailleCm':
          p.tailleCm = value as int?;
        case 'poidsKg':
          p.poidsKg = value as double?;
        case 'activite':
          p.activite = value as NiveauActivite?;
        case 'objectif':
          p.objectif = value as Objectif;
        case 'regime':
          p.regime = value as Regime;
        case 'allergies':
          p.allergies = value as List<Allergene>;
        case 'exclus':
          p.exclus = value as List<Ingredient>;
        case 'cuisinesPreferees':
          p.cuisinesPreferees = value as List<String>;
        case 'tempsMaxMinutes':
          p.tempsMaxMinutes = value as int;
        case 'nbPersonnes':
          p.nbPersonnes = value as int;
        case 'budgetHebdoDT':
          p.budgetHebdoDT = value as double?;
        case 'enseigne':
          p.enseigne = value as Enseigne?;
        case 'equipements':
          p.equipements = value as List<Equipement>;
      }
    }
    final valide = p.valider(etape); // 4 : valider(i)
    notifyListeners();
    return valide;
  }

  /// « Créer mon profil » (séquence 2, messages 12 à 17) : calcule le besoin et les macros,
  /// rattache le profil à l'utilisateur et l'enregistre.
  Future<ProfilNutritionnel> finaliserProfil(Utilisateur u) async {
    final p = _brouillon;
    for (var i = 1; i <= 6; i++) {
      if (!p.valider(i)) throw StateError('Étape $i non valide');
    }
    p.calculerBesoin(); // 13-14
    p.calculerMacros(); // 15
    final ancienneEnseigne = u.profil?.enseigne;
    u.profil = p;
    // Changer d'enseigne : le planning est chiffré avec le nouveau catalogue.
    if (ancienneEnseigne != p.enseigne) {
      for (final planning in u.plannings) {
        planning.catalogue = p.enseigne?.catalogue;
      }
    }
    await _auth.enregistrer(u); // 16 : enregistrer(profil)
    _brouillon = p.copie(_referentiel);
    notifyListeners();
    return p; // 17 : profil
  }
}
