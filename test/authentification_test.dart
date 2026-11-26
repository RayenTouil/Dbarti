import 'package:dbarti/donnees/base_de_donnees.dart';
import 'package:dbarti/outils/securite.dart';
import 'package:dbarti/outils/validation.dart';
import 'package:dbarti/services/service_authentification.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aide.dart';

void main() {
  group('Mot de passe haché avec un sel', () {
    test('jamais stocké en clair', () async {
      final d = await preparer();
      final u = await d.auth.inscrire('Yasmine Trabelsi', 'yasmine@exemple.tn', 'soleil2024', true);
      expect(u.motDePasseHache, isNot(contains('soleil2024')));
      expect(u.motDePasseHache, startsWith('pbkdf2-sha256\$'));
      final brut = (d.base as BaseDeDonneesMemoire).brut(BaseDeDonnees.utilisateurs).values.join();
      expect(brut, isNot(contains('soleil2024')));
    });

    test('deux sels différents donnent deux empreintes différentes', () {
      final a = hacherMotDePasse('soleil2024');
      final b = hacherMotDePasse('soleil2024');
      expect(a, isNot(b));
      expect(verifierMotDePasse('soleil2024', a), isTrue);
      expect(verifierMotDePasse('soleil2024', b), isTrue);
      expect(verifierMotDePasse('soleil2025', a), isFalse);
    });
  });

  group('S’authentifier (séquence 1)', () {
    test('identifiants corrects : utilisateur et profil complet', () async {
      final d = await preparer();
      await inscrireYasmine(d);
      d.auth.seDeconnecter();
      final u = await d.auth.connecter('Yasmine@Exemple.tn ', 'soleil2024');
      expect(u, isNotNull);
      expect(u!.profil!.estComplet(), isTrue);
    });

    test('identifiants incorrects : null (« E-mail ou mot de passe incorrect »)', () async {
      final d = await preparer();
      await inscrireYasmine(d);
      expect(await d.auth.connecter('yasmine@exemple.tn', 'mauvais123'), isNull);
      expect(await d.auth.connecter('inconnu@gmail.com', 'soleil2024'), isNull);
    });

    test('verifierFormat : messages qui disent comment corriger (écran 02E)', () {
      expect(erreurEmail('yasmine@exemple'), contains('@gmail.com'));
      expect(erreurEmail('yasmine'), isNotNull);
      expect(erreurEmail('yasmine@gmail.com'), isNull);
      expect(erreurMotDePasse('court1'), contains('8 caractères'));
      expect(erreurMotDePasse('sanschiffre'), contains('chiffre'));
      expect(erreurMotDePasse('soleil2024'), isNull);
    });

    test('inscription : consentement obligatoire et adresse unique', () async {
      final d = await preparer();
      expect(() => d.auth.inscrire('Sami Ben Ali', 'sami@exemple.tn', 'motdepasse1', false),
          throwsA(isA<ErreurAuthentification>()));
      await d.auth.inscrire('Sami Ben Ali', 'sami@exemple.tn', 'motdepasse1', true);
      expect(() => d.auth.inscrire('Sami Ben Ali', 'SAMI@exemple.tn', 'motdepasse2', true),
          throwsA(isA<ErreurAuthentification>()));
    });

    test('supprimer le compte efface ses données', () async {
      final d = await preparer();
      final u = await inscrireYasmine(d);
      await d.planning.genererSemaine(u);
      await d.auth.supprimerCompte();
      expect(d.auth.utilisateurCourant, isNull);
      expect(await d.base.lireTout(BaseDeDonnees.utilisateurs), isEmpty);
      expect(await d.base.lire(BaseDeDonnees.plannings, u.id), isNull);
    });
  });
}
