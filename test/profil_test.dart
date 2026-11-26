import 'package:dbarti/modeles/enumerations.dart';
import 'package:dbarti/modeles/profil_nutritionnel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aide.dart';

ProfilNutritionnel yasmine() => ProfilNutritionnel()
  ..age = 21
  ..sexe = Sexe.femme
  ..tailleCm = 165
  ..poidsKg = 58
  ..activite = NiveauActivite.moderementActif;

void main() {
  group('ProfilNutritionnel.calculerBesoin() — Mifflin-St Jeor', () {
    test('Yasmine (F, 21 ans, 165 cm, 58 kg, modérément active) : 2 090 kcal', () {
      expect(yasmine().calculerBesoin(), 2090);
    });

    test('homme : +5 au lieu de −161, arrondi à 10 kcal', () {
      final p = yasmine()..sexe = Sexe.homme;
      // (580 + 1031,25 − 105 + 5) × 1,55 = 2 342,4 → 2 340
      expect(p.calculerBesoin(), 2340);
    });

    test('facteurs d’activité 1,2 / 1,55 / 1,725', () {
      // base : 580 + 1 031,25 − 105 − 161 = 1 345,25
      expect((yasmine()..activite = NiveauActivite.peuActif).calculerBesoin(), 1610); // × 1,2 = 1 614,3
      expect((yasmine()..activite = NiveauActivite.tresActif).calculerBesoin(), 2320); // × 1,725
    });

    test('objectif perte de poids : −400 kcal par jour', () {
      expect((yasmine()..objectif = Objectif.perteDePoids).calculerBesoin(), 1690);
    });

    test('calculerMacros() : 94 g de protéines, 272 g de glucides, 70 g de lipides (écran 11)', () {
      final p = yasmine()..calculerBesoin();
      p.calculerMacros();
      expect([p.proteinesG, p.glucidesG, p.lipidesG], [94, 272, 70]);
    });
  });

  group('ProfilNutritionnel.valider()', () {
    test('poids hors de 30 à 250 kg : message sous le champ, étape non validée', () {
      for (final poids in [29.0, 251.0]) {
        final p = yasmine()..poidsKg = poids;
        expect(p.valider(1), isFalse, reason: '$poids kg');
        expect(p.erreurs['poids'], contains('entre 30 et 250 kg'));
      }
      for (final poids in [30.0, 250.0]) {
        expect((yasmine()..poidsKg = poids).valider(1), isTrue, reason: '$poids kg');
      }
    });

    test('étape 6 : au moins un appareil', () {
      final p = ProfilNutritionnel();
      expect(p.valider(6), isFalse);
      expect(p.erreurs, contains('equipement'));
    });

    test('étape Préférences passée : valeurs par défaut', () async {
      final d = await preparer();
      await d.auth.inscrire('Test Défaut', 'defaut@exemple.tn', 'motdepasse1', true);
      d.profil.demarrer();
      expect(d.profil.enregistrerEtape(4, {'passer': true}), isTrue);
      expect(d.profil.brouillon.cuisinesPreferees, isEmpty);
      expect(d.profil.brouillon.tempsMaxMinutes, ProfilNutritionnel.tempsMaxParDefaut);
    });

    test('le profil de Yasmine est complet après le questionnaire', () async {
      final d = await preparer();
      final u = await inscrireYasmine(d);
      expect(u.profil!.estComplet(), isTrue);
      expect(u.profil!.besoinKcal, 2090);
    });
  });
}
