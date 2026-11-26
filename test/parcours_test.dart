// Test de widget du parcours principal : inscription (écrans 02 et 02E), questionnaire
// (écrans 04 à 09, avec une erreur de poids), analyse (10), profil (11), planning (12).
import 'package:dbarti/app.dart';
import 'package:dbarti/demarrage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aide.dart';

void main() {
  testWidgets('parcours : inscription → questionnaire → planning de la semaine', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400) // écran de référence 360 × 800 dp
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final Dependances d = (await tester.runAsync(preparer))!;
    await tester.pumpWidget(AppDbarti(dependances: d));
    await tester.pumpAndSettle();

    Future<void> appuyer(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    // Écran 01 — Bienvenue
    expect(find.text('Continuer sans compte'), findsOneWidget); // action principale
    await appuyer(find.text('Créer un compte'));

    // Écran 02 → 02E : adresse incomplète, consentement non coché
    await tester.enterText(find.byKey(const Key('champ-nom')), 'Yasmine Trabelsi');
    await tester.enterText(find.byKey(const Key('champ-email')), 'yasmine@exemple');
    await tester.enterText(find.byKey(const Key('champ-mot-de-passe')), 'soleil2024');
    await appuyer(find.byKey(const Key('bouton-continuer-inscription')));
    expect(find.textContaining('Adresse incomplète'), findsOneWidget);
    expect(find.textContaining('Cochez la case'), findsOneWidget);

    // Correction, puis consentement explicite
    await tester.enterText(find.byKey(const Key('champ-email')), 'yasmine@exemple.tn');
    await appuyer(find.byKey(const Key('case-consentement')));
    await appuyer(find.byKey(const Key('bouton-continuer-inscription')));

    // Écran 04 — Étape 1 sur 6 : poids hors limites refusé
    expect(find.text('Étape 1 sur 6 · Votre corps'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('champ-age')), '21');
    await appuyer(find.text('Femme'));
    await tester.enterText(find.byKey(const Key('champ-taille')), '165');
    await tester.enterText(find.byKey(const Key('champ-poids')), '251');
    await appuyer(find.byKey(const Key('activite-moderementActif')));
    await appuyer(find.byKey(const Key('bouton-questionnaire')));
    expect(find.textContaining('entre 30 et 250 kg'), findsOneWidget);
    expect(find.text('Étape 1 sur 6 · Votre corps'), findsOneWidget); // étape non validée
    await tester.enterText(find.byKey(const Key('champ-poids')), '58');
    await appuyer(find.byKey(const Key('bouton-questionnaire')));

    // Écran 05 — Objectif : avertissement si GLYCEMIE, puis retour à « Manger équilibré »
    expect(find.text('Étape 2 sur 6 · Objectif'), findsOneWidget);
    await appuyer(find.byKey(const Key('objectif-glycemie')));
    expect(find.byKey(const Key('avertissement-medecin')), findsOneWidget);
    await appuyer(find.byKey(const Key('objectif-equilibre')));
    expect(find.byKey(const Key('avertissement-medecin')), findsNothing);
    await appuyer(find.byKey(const Key('bouton-questionnaire')));

    // Écran 06 — Contraintes : arachides, et l'aubergine exclue
    expect(find.text('Étape 3 sur 6 · Contraintes'), findsOneWidget);
    await appuyer(find.byKey(const Key('allergie-arachides')));
    await appuyer(find.byKey(const Key('ajouter-aliment')));
    await appuyer(find.byKey(const Key('aliment-aubergine')));
    expect(find.text('Aubergine'), findsOneWidget);
    await appuyer(find.byKey(const Key('bouton-questionnaire')));

    // Écran 07 — Préférences (facultative)
    expect(find.text('Étape 4 sur 6 · Préférences'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    await appuyer(find.byKey(const Key('cuisine-Italienne')));
    await appuyer(find.byKey(const Key('bouton-questionnaire')));

    // Écran 08 — Foyer et budget
    expect(find.text('Étape 5 sur 6 · Foyer et budget'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('champ-budget')), '60');
    await tester.pump();
    expect(find.textContaining('8,571'), findsOneWidget); // « Soit environ 8,571 DT par jour. »
    await appuyer(find.byKey(const Key('enseigne-carrefour')));
    await appuyer(find.byKey(const Key('bouton-questionnaire')));

    // Écran 09 — Équipement : plaque, casserole, poêle, micro-ondes (ni four ni mixeur)
    expect(find.text('Étape 6 sur 6 · Équipement'), findsOneWidget);
    for (final t in ['plaque', 'casserole', 'poele', 'microOndes']) {
      await appuyer(find.byKey(Key('equipement-$t')));
    }
    expect(find.text('Créer mon profil'), findsOneWidget);
    await appuyer(find.byKey(const Key('bouton-questionnaire')));

    // Écrans 10 puis 11 — Analyse IA, puis profil nutritionnel
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Votre profil nutritionnel'), findsOneWidget);
    expect(find.text('2 090'), findsOneWidget);
    expect(find.text('94 g · 18 %'), findsOneWidget);

    // Écran 12 — « Générer ma semaine » → planning du lundi
    await appuyer(find.byKey(const Key('bouton-generer')));
    expect(find.text('Bonjour Yasmine'), findsOneWidget);
    expect(find.text('Porridge aux dattes'), findsOneWidget);
    expect(find.text('Curry de pois chiches et riz'), findsOneWidget);
    expect(find.text('Penne au thon et tomates'), findsOneWidget);
    expect(find.text('Sans mixeur'), findsOneWidget);
    expect(find.text('Ingrédient local'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('carte-panier')), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('55,830 DT sur 60 DT', findRichText: true), findsOneWidget);
    expect(find.text('Semaine'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(d.planning.planning!.repas, hasLength(21));
  });

  testWidgets('liste de courses : total, reste du budget et « déjà à la maison »', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final Dependances d = (await tester.runAsync(() async {
      final d = await preparer();
      await d.planning.genererSemaine(await inscrireYasmine(d));
      return d;
    }))!;
    await tester.pumpWidget(AppDbarti(dependances: d));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    expect(find.text('Liste de courses'), findsOneWidget);
    expect(find.byKey(const Key('total-liste')), findsOneWidget);
    expect(find.text('55,830 DT'), findsOneWidget);
    expect(find.text('Dans votre budget : il reste 4,170 DT.'), findsOneWidget);

    final dattes = find.byKey(const Key('article-datte'));
    await tester.ensureVisible(dattes);
    await tester.tap(dattes);
    await tester.pumpAndSettle();
    expect(find.text('Déjà à la maison · non compté'), findsOneWidget);
    expect(d.courses.liste!.totalDT, closeTo(49.330, 1e-9));
    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.text('49,330 DT'), findsOneWidget);
    expect(find.text('Dans votre budget : il reste 10,670 DT.'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('article-huile-olive')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('À acheter ailleurs'), findsOneWidget);
  });

  testWidgets('connexion : identifiants incorrects, puis corrects → planning', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final Dependances d = (await tester.runAsync(() async {
      final d = await preparer();
      await d.planning.genererSemaine(await inscrireYasmine(d));
      d.auth.seDeconnecter();
      return d;
    }))!;
    await tester.pumpWidget(AppDbarti(dependances: d));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Bon retour !'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('connexion-email')), 'yasmine@exemple.tn');
    await tester.enterText(find.byKey(const Key('connexion-mot-de-passe')), 'mauvais123');
    await tester.tap(find.byKey(const Key('bouton-se-connecter')));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou mot de passe incorrect'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('connexion-mot-de-passe')), 'soleil2024');
    await tester.tap(find.byKey(const Key('bouton-se-connecter')));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour Yasmine'), findsOneWidget);
  });

  testWidgets('profil : modifier le budget recalcule et signale le dépassement', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final Dependances d = (await tester.runAsync(() async {
      final d = await preparer();
      await d.planning.genererSemaine(await inscrireYasmine(d));
      return d;
    }))!;
    await tester.pumpWidget(AppDbarti(dependances: d));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foyer et budget'));
    await tester.pumpAndSettle();
    expect(find.text('Étape 5 sur 6 · Foyer et budget'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('champ-budget')), '50');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Votre profil nutritionnel'), findsOneWidget); // écran 11 recalculé
    expect(d.auth.utilisateurCourant!.profil!.budgetHebdoDT, 50);
    expect(d.planning.depassement!.ecart, closeTo(5.830, 1e-9));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semaine'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('depassement')), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('dépasse votre budget de 5,830', findRichText: true), findsOneWidget);
  });
}
