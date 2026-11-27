// Accès visiteur (séquence 1 mise à jour) : utiliser Dbarti sans compte, puis créer un compte
// plus tard sans perdre ses données.
import 'dart:io';

import 'package:dbarti/app.dart';
import 'package:dbarti/demarrage.dart';
import 'package:dbarti/donnees/base_de_donnees.dart';
import 'package:dbarti/services/service_authentification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'aide.dart';

void main() {
  group('demarrerVisiteur()', () {
    test('crée un utilisateur visiteur, sans e-mail ni mot de passe, enregistré sur le téléphone', () async {
      final d = await preparer();
      final u = await d.auth.demarrerVisiteur(true);
      expect(u.estVisiteur, isTrue);
      expect(u.email, isNull);
      expect(u.nomComplet, isNull);
      expect(u.motDePasseHache, isNull);
      expect(u.dateInscription, isNull);
      expect(d.auth.utilisateurCourant, same(u));
      final enregistre = await d.base.lire(BaseDeDonnees.utilisateurs, u.id);
      expect(enregistre!['estVisiteur'], isTrue);
      expect(enregistre['email'], isNull);
    });

    test('consentement aux données de santé obligatoire', () async {
      final d = await preparer();
      expect(() => d.auth.demarrerVisiteur(false), throwsA(isA<ErreurAuthentification>()));
      expect(d.auth.utilisateurCourant, isNull);
    });

    test('un visiteur ne peut pas « se connecter » : il n’a ni e-mail ni mot de passe', () async {
      final d = await preparer();
      final u = await d.auth.demarrerVisiteur(true);
      expect(u.seConnecter('', ''), isFalse);
    });
  });

  group('Toutes les fonctions sans compte', () {
    test('questionnaire, planning, remplacement, liste et achat, sans inscrire() ni connecter()', () async {
      final d = await preparer();
      final u = await d.auth.demarrerVisiteur(true);
      await remplirQuestionnaire(d, u);
      expect(u.profil!.besoinKcal, 2090);
      final planning = await d.planning.genererSemaine(u);
      expect(planning.repas, hasLength(21));
      final diner = planning.repasDuJour(planning.dateDebut).last;
      final choix = (await d.planning.proposerRemplacements(diner)).first;
      await d.planning.remplacer(diner, choix);
      final liste = await d.courses.genererListe(planning);
      expect(liste.articles, isNotEmpty);
      // Toujours visiteur : aucune authentification n'a eu lieu.
      expect(d.auth.utilisateurCourant!.estVisiteur, isTrue);
      expect((await d.base.lireTout(BaseDeDonnees.utilisateurs)).single['email'], isNull);
    });
  });

  group('Conversion visiteur → compte', () {
    test('même id ; profil, planning et liste de courses conservés', () async {
      final base = BaseDeDonneesMemoire();
      final d = await preparer(base: base);
      final u = await d.auth.demarrerVisiteur(true);
      await remplirQuestionnaire(d, u);
      final planning = await d.planning.genererSemaine(u);
      final liste = await d.courses.genererListe(planning);
      await d.courses.marquerArticle(liste.articles.firstWhere((a) => a.ingredient.id == 'datte'));
      final profil = u.profil;

      final inscrit = await d.auth.inscrire('Yasmine Trabelsi', 'yasmine@exemple.tn', 'soleil2024', true);

      expect(inscrit, same(u)); // le MÊME objet, pas une copie
      expect(inscrit.id, u.id);
      expect(inscrit.estVisiteur, isFalse);
      expect(inscrit.email, 'yasmine@exemple.tn');
      expect(inscrit.profil, same(profil));
      expect(inscrit.planningCourant!.id, planning.id);
      expect(d.courses.liste!.totalDT, closeTo(55.830 - 6.500, 1e-9));
      expect(await base.lireTout(BaseDeDonnees.utilisateurs), hasLength(1));

      // Après un redémarrage, le compte se connecte et retrouve tout.
      final d2 = await preparer(base: base);
      d2.auth.seDeconnecter();
      final reconnecte = await d2.auth.connecter('yasmine@exemple.tn', 'soleil2024');
      expect(reconnecte!.id, u.id);
      expect(reconnecte.planningCourant!.id, planning.id);
      await d2.courses.restaurer(reconnecte.planningCourant!);
      expect(d2.courses.liste!.totalDT, closeTo(55.830 - 6.500, 1e-9));
    });

    test('e-mail déjà utilisé : erreur claire, et le visiteur garde toutes ses données', () async {
      final base = BaseDeDonneesMemoire();
      final d = await preparer(base: base);
      await d.auth.inscrire('Sami Ben Ali', 'sami@exemple.tn', 'motdepasse1', true);
      d.auth.seDeconnecter();

      final visiteur = await d.auth.demarrerVisiteur(true);
      await remplirQuestionnaire(d, visiteur);
      final planning = await d.planning.genererSemaine(visiteur);

      await expectLater(
        d.auth.inscrire('Yasmine Trabelsi', 'sami@exemple.tn', 'soleil2024', true),
        throwsA(isA<ErreurAuthentification>().having((e) => e.message, 'message', contains('existe déjà'))),
      );
      expect(d.auth.utilisateurCourant, same(visiteur));
      expect(visiteur.estVisiteur, isTrue);
      expect(visiteur.email, isNull);
      expect(visiteur.profil!.estComplet(), isTrue);
      expect(visiteur.planningCourant!.id, planning.id);
      final enregistre = await base.lire(BaseDeDonnees.utilisateurs, visiteur.id);
      expect(enregistre!['estVisiteur'], isTrue);
    });
  });

  group('Persistance et migration', () {
    test('les données du visiteur restent après un redémarrage (session, profil, planning, liste)', () async {
      final base = BaseDeDonneesMemoire();
      final d = await preparer(base: base);
      final u = await d.auth.demarrerVisiteur(true);
      await remplirQuestionnaire(d, u);
      final planning = await d.planning.genererSemaine(u);
      await d.courses.genererListe(planning);

      final apres = await preparer(base: base); // l'application est relancée
      final restaure = apres.auth.utilisateurCourant!;
      expect(restaure.id, u.id);
      expect(restaure.estVisiteur, isTrue);
      expect(restaure.profil!.besoinKcal, 2090);
      expect(restaure.planningCourant!.id, planning.id);
      expect(apres.courses.liste!.totalDT, closeTo(55.830, 1e-9));
    });

    test('stockage réel (Hive, fichiers) : le visiteur est retrouvé après fermeture de la base', () async {
      final dossier = await Directory.systemTemp.createTemp('dbarti_hive_');
      addTearDown(() async {
        await Hive.close();
        await dossier.delete(recursive: true);
      });
      final d = await preparer(base: await BaseDeDonneesHive.ouvrir(dossier: dossier.path));
      final u = await d.auth.demarrerVisiteur(true);
      await remplirQuestionnaire(d, u);
      await d.planning.genererSemaine(u);
      await Hive.close(); // fermeture de l'application

      final relance = await preparer(base: await BaseDeDonneesHive.ouvrir(dossier: dossier.path));
      expect(relance.auth.utilisateurCourant!.id, u.id);
      expect(relance.auth.utilisateurCourant!.estVisiteur, isTrue);
      expect(relance.planning.planning!.repas, hasLength(21));
    });

    test('migration : un compte enregistré avant l’accès visiteur reste un compte inscrit', () async {
      final base = BaseDeDonneesMemoire();
      final ancien = await preparer(base: base);
      await inscrireYasmine(ancien);
      // Simule un enregistrement de la version 1.0.0, sans le champ estVisiteur.
      final j = (await base.lireTout(BaseDeDonnees.utilisateurs)).single..remove('estVisiteur');
      await base.enregistrer(BaseDeDonnees.utilisateurs, j['id'] as String, j);
      await base.definirReglage('versionSchema', null);

      final d = await preparer(base: base);
      final migre = (await base.lireTout(BaseDeDonnees.utilisateurs)).single;
      expect(migre['estVisiteur'], isFalse);
      expect(d.auth.utilisateurCourant!.estVisiteur, isFalse);
      expect(d.auth.utilisateurCourant!.profil!.besoinKcal, 2090);
      expect(await base.reglage('versionSchema'), '2');
    });
  });

  group('Écrans (widgets)', () {
    Future<Dependances> lancer(WidgetTester tester, [Future<Dependances> Function()? preparation]) async {
      tester.view
        ..physicalSize = const Size(1080, 2400)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final d = (await tester.runAsync(preparation ?? preparer))!;
      await tester.pumpWidget(AppDbarti(dependances: d));
      await tester.pumpAndSettle();
      return d;
    }

    Future<void> appuyer(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('parcours visiteur : bienvenue → consentement → questionnaire → planning → courses', (tester) async {
      final d = await lancer(tester);

      // Écran 01 : trois choix, « Continuer sans compte » est l'action principale.
      expect(find.text('Continuer sans compte'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      await appuyer(tester, find.byKey(const Key('continuer-sans-compte')));

      // Seul le consentement est demandé, et il est obligatoire.
      expect(find.byType(TextField), findsNothing); // ni e-mail ni mot de passe
      await appuyer(tester, find.byKey(const Key('bouton-commencer-visiteur')));
      expect(find.textContaining('Cochez la case'), findsOneWidget);
      await appuyer(tester, find.byKey(const Key('case-consentement-visiteur')));
      await appuyer(tester, find.byKey(const Key('bouton-commencer-visiteur')));

      // Directement au questionnaire (écran 04).
      expect(find.text('Étape 1 sur 6 · Votre corps'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('champ-age')), '21');
      await appuyer(tester, find.text('Femme'));
      await tester.enterText(find.byKey(const Key('champ-taille')), '165');
      await tester.enterText(find.byKey(const Key('champ-poids')), '58');
      await appuyer(tester, find.byKey(const Key('activite-moderementActif')));
      await appuyer(tester, find.byKey(const Key('bouton-questionnaire')));
      await appuyer(tester, find.byKey(const Key('bouton-questionnaire'))); // objectif
      await appuyer(tester, find.byKey(const Key('allergie-arachides')));
      await appuyer(tester, find.byKey(const Key('bouton-questionnaire'))); // contraintes
      await appuyer(tester, find.byKey(const Key('bouton-questionnaire'))); // préférences
      await tester.enterText(find.byKey(const Key('champ-budget')), '60');
      await appuyer(tester, find.byKey(const Key('enseigne-carrefour')));
      await appuyer(tester, find.byKey(const Key('bouton-questionnaire'))); // foyer et budget
      for (final t in ['plaque', 'casserole', 'poele', 'microOndes']) {
        await appuyer(tester, find.byKey(Key('equipement-$t')));
      }
      await appuyer(tester, find.byKey(const Key('bouton-questionnaire'))); // créer mon profil
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('2 090'), findsOneWidget);

      await appuyer(tester, find.byKey(const Key('bouton-generer')));
      expect(find.text('Bonjour'), findsOneWidget); // pas de prénom : visiteur
      expect(find.text('Porridge aux dattes'), findsOneWidget);

      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(find.text('Liste de courses'), findsOneWidget);
      expect(find.byKey(const Key('total-liste')), findsOneWidget);

      // Aucun écran ne demande de compte : pas de rappel, pas de pop-up.
      expect(find.byType(AlertDialog), findsNothing);
      expect(d.auth.utilisateurCourant!.estVisiteur, isTrue);
    });

    testWidgets('profil visiteur : bandeau, création de compte facultative, données gardées', (tester) async {
      final d = await lancer(tester, () async {
        final d = await preparer();
        final u = await d.auth.demarrerVisiteur(true);
        await remplirQuestionnaire(d, u);
        await d.planning.genererSemaine(u);
        return d;
      });
      final id = d.auth.utilisateurCourant!.id;
      final idPlanning = d.planning.planning!.id;

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Vous utilisez Dbarti sans compte'), findsOneWidget);
      expect(find.text('Effacer mes données'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsNothing);

      await appuyer(tester, find.byKey(const Key('creer-compte-visiteur')));
      expect(find.byKey(const Key('case-consentement')), findsNothing); // consentement déjà donné
      await tester.enterText(find.byKey(const Key('champ-nom')), 'Yasmine Trabelsi');
      await tester.enterText(find.byKey(const Key('champ-email')), 'yasmine@exemple.tn');
      await tester.enterText(find.byKey(const Key('champ-mot-de-passe')), 'soleil2024');
      await appuyer(tester, find.byKey(const Key('bouton-continuer-inscription')));

      expect(find.text('Compte créé, vos données sont gardées.'), findsOneWidget);
      expect(find.text('Vous utilisez Dbarti sans compte'), findsNothing);
      expect(find.text('Supprimer mon compte et mes données'), findsOneWidget);
      expect(d.auth.utilisateurCourant!.id, id);
      expect(d.planning.planning!.id, idPlanning);
    });

    testWidgets('« Effacer mes données » demande une confirmation puis revient à l’accueil', (tester) async {
      final d = await lancer(tester, () async {
        final d = await preparer();
        final u = await d.auth.demarrerVisiteur(true);
        await remplirQuestionnaire(d, u);
        return d;
      });
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      await appuyer(tester, find.byKey(const Key('supprimer-compte')));
      expect(find.text('Effacer vos données ?'), findsOneWidget);
      await appuyer(tester, find.text('Garder mes données'));
      expect(d.auth.utilisateurCourant, isNotNull);

      await appuyer(tester, find.byKey(const Key('supprimer-compte')));
      await appuyer(tester, find.byKey(const Key('confirmer-suppression')));
      expect(find.text('Continuer sans compte'), findsOneWidget);
      expect(d.auth.utilisateurCourant, isNull);
      expect(await tester.runAsync(() => d.base.lireTout(BaseDeDonnees.utilisateurs)), isEmpty);
    });
  });
}
