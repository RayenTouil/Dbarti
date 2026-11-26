// Captures d'écran du README, dessinées par Flutter avec les vraies polices (360 × 800 dp).
// Ignoré par défaut. Pour régénérer les images de docs/captures :
//   flutter test --dart-define=CAPTURES=true --update-goldens test/captures_test.dart
import 'package:dbarti/demarrage.dart';
import 'package:dbarti/ecrans/coquille_onglets.dart';
import 'package:dbarti/ecrans/ecran_01_bienvenue.dart';
import 'package:dbarti/ecrans/ecran_02_inscription.dart';
import 'package:dbarti/ecrans/ecran_11_profil_nutritionnel.dart';
import 'package:dbarti/ecrans/ecran_14_recette.dart';
import 'package:dbarti/ecrans/ecran_15_mode_cuisine.dart';
import 'package:dbarti/ecrans/ecran_17_achat.dart';
import 'package:dbarti/ecrans/ecran_questionnaire.dart';
import 'package:dbarti/modeles/enumerations.dart';
import 'package:dbarti/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'aide.dart';

const _actif = bool.fromEnvironment('CAPTURES');

Widget _enveloppe(Dependances d, Widget ecran) => MultiProvider(
      providers: [
        Provider.value(value: d.depot),
        ChangeNotifierProvider.value(value: d.auth),
        ChangeNotifierProvider.value(value: d.profil),
        ChangeNotifierProvider.value(value: d.planning),
        ChangeNotifierProvider.value(value: d.courses),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeDbarti(),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ecran,
      ),
    );

Future<Dependances> _yasmineAvecPlanning(WidgetTester t) async => (await t.runAsync(() async {
      final d = await preparer();
      final u = await inscrireYasmine(d);
      final p = await d.planning.genererSemaine(u);
      await d.courses.genererListe(p);
      return d;
    }))!;

Future<void> _photos(WidgetTester t) async {
  await t.runAsync(() async {
    final contexte = t.element(find.byType(MaterialApp));
    for (final nom in ['curry', 'grecque', 'porridge', 'penne', 'wrap', 'yaourt', 'sautee', 'lentilles', 'chili', 'poisson']) {
      await precacheImage(AssetImage('assets/images/$nom.jpg'), contexte);
    }
  });
  await t.pumpAndSettle();
}

Future<void> _capturer(WidgetTester t, String nom) async {
  await _photos(t);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('../docs/captures/$nom.png'));
}

void main() {
  void capture(String nom, Future<void> Function(WidgetTester t) corps) => testWidgets(nom, (t) async {
        t.view
          ..physicalSize = const Size(720, 1600)
          ..devicePixelRatio = 2;
        addTearDown(t.view.reset);
        await corps(t);
        await _capturer(t, nom);
      }, skip: !_actif);

  capture('01_bienvenue', (t) async {
    final d = (await t.runAsync(preparer))!;
    await t.pumpWidget(_enveloppe(d, const EcranBienvenue()));
  });

  capture('02E_inscription_erreur', (t) async {
    final d = (await t.runAsync(preparer))!;
    await t.pumpWidget(_enveloppe(d, const EcranInscription()));
    await t.enterText(find.byKey(const Key('champ-nom')), 'Yasmine Trabelsi');
    await t.enterText(find.byKey(const Key('champ-email')), 'yasmine@exemple');
    await t.enterText(find.byKey(const Key('champ-mot-de-passe')), 'soleil2024');
    await t.tap(find.byKey(const Key('case-consentement')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('bouton-continuer-inscription')));
    await t.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
  });

  capture('04_questionnaire_corps', (t) async {
    final d = await _yasmineAvecPlanning(t);
    d.profil.demarrer();
    await t.pumpWidget(_enveloppe(d, const EcranQuestionnaire()));
  });

  capture('09_questionnaire_equipement', (t) async {
    final d = await _yasmineAvecPlanning(t);
    d.profil.demarrer();
    await t.pumpWidget(_enveloppe(d, const EcranQuestionnaire(etapeAModifier: 6)));
  });

  capture('11_profil_nutritionnel', (t) async {
    final d = await _yasmineAvecPlanning(t);
    await t.pumpWidget(_enveloppe(d, const EcranProfilNutritionnel()));
  });

  capture('12_planning', (t) async {
    final d = await _yasmineAvecPlanning(t);
    await t.pumpWidget(_enveloppe(d, const CoquilleOnglets()));
  });

  capture('13_remplacer_repas', (t) async {
    final d = await _yasmineAvecPlanning(t);
    await t.pumpWidget(_enveloppe(d, const CoquilleOnglets()));
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: find.byKey(const Key('repas-diner')), matching: find.byType(IconButton)));
    await t.pumpAndSettle();
  });

  capture('14_recette', (t) async {
    final d = await _yasmineAvecPlanning(t);
    final curry = d.planning.planning!.repasDe(d.planning.planning!.dateDebut, TypeRepas.dejeuner);
    await t.pumpWidget(_enveloppe(d, EcranRecette(repas: curry)));
  });

  capture('15_mode_cuisine', (t) async {
    final d = await _yasmineAvecPlanning(t);
    final curry = d.planning.planning!.repasDe(d.planning.planning!.dateDebut, TypeRepas.dejeuner);
    await t.pumpWidget(_enveloppe(d, EcranModeCuisine(repas: curry)));
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const Key('etape-suivante')));
      await t.pumpAndSettle();
    }
  });

  capture('16_liste_courses', (t) async {
    final d = await _yasmineAvecPlanning(t);
    final liste = d.courses.liste!;
    await t.runAsync(() => d.courses.marquerArticle(liste.articles.firstWhere((a) => a.ingredient.id == 'oignon')));
    await t.pumpWidget(_enveloppe(d, const CoquilleOnglets(ongletInitial: 1)));
  });

  capture('17_faire_ses_courses', (t) async {
    final d = await _yasmineAvecPlanning(t);
    await t.pumpWidget(_enveloppe(d, const EcranAchat()));
  });

  capture('18_profil', (t) async {
    final d = await _yasmineAvecPlanning(t);
    await t.pumpWidget(_enveloppe(d, const CoquilleOnglets(ongletInitial: 2)));
  });
}
