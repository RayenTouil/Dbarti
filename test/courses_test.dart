import 'package:dbarti/donnees/base_de_donnees.dart';
import 'package:dbarti/externes/outil_collecte.dart';
import 'package:dbarti/modeles/enumerations.dart';
import 'package:dbarti/outils/format.dart';
import 'package:dbarti/outils/horloge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aide.dart';

void main() {
  group('Liste de courses chiffrée (séquence 5)', () {
    test('agrégation des quantités sur les 21 repas', () async {
      final d = await preparer();
      final liste = await d.courses.genererListe(await d.planning.genererSemaine(await inscrireYasmine(d)));
      final parIngredient = {for (final a in liste.articles) a.ingredient.id: a};
      // Tomates : 2 curry (120 g) + 2 penne au thon (120 g) + 2 penne à la tomate (100 g)
      //           + ojja (150 g) + salade (80 g) + wrap (50 g) = 960 g → 1 sachet de 1 kg
      expect(parIngredient['tomate']!.quantite, 960);
      expect(parIngredient['tomate']!.nbRecettes, 9);
      expect(parIngredient['tomate']!.nbConditionnements, 1);
      // Pois chiches : 2 × 200 + 200 + 150 = 750 g → 2 boîtes de 400 g
      expect(parIngredient['pois-chiche']!.quantite, 750);
      expect(parIngredient['pois-chiche']!.nbConditionnements, 2);
      expect(parIngredient['pois-chiche']!.prixDT, closeTo(4.900, 1e-9));
      // Thon : 2 × 160 g → 2 boîtes
      expect(parIngredient['thon']!.nbConditionnements, 2);
      // 16 produits de l'enseigne + 1 article « à acheter ailleurs »
      expect(liste.articles, hasLength(17));
    });

    test('ingrédient absent du catalogue : « à acheter ailleurs », sans prix', () async {
      final d = await preparer();
      final liste = await d.courses.genererListe(await d.planning.genererSemaine(await inscrireYasmine(d)));
      final ailleurs = liste.articles.where((a) => a.aAcheterAilleurs()).toList();
      expect(ailleurs.map((a) => a.ingredient.id), ['huile-olive']);
      expect(ailleurs.single.produit, isNull);
      expect(ailleurs.single.prixDT, 0);
      expect(ailleurs.single.prixCompte, 0);
    });

    test('total 55,830 DT et reste du budget 4,170 DT avec les données de démonstration', () async {
      final d = await preparer();
      final liste = await d.courses.genererListe(await d.planning.genererSemaine(await inscrireYasmine(d)));
      expect(liste.calculerTotal(), closeTo(55.830, 1e-9));
      expect(liste.resteBudget(60), closeTo(4.170, 1e-9));
      expect(formaterDT(liste.totalDT), '55,830 DT');
      expect(formaterDT(liste.resteBudget(60)), '4,170 DT');
      expect(liste.nbArticlesComptes, 16);
    });

    test('articles par rayon, dans l’ordre du parcours en magasin', () async {
      final d = await preparer();
      final liste = await d.courses.genererListe(await d.planning.genererSemaine(await inscrireYasmine(d)));
      expect(liste.articlesParRayon().keys, ['Fruits et légumes', 'Épicerie', 'Crèmerie, viande']);
      expect(liste.articlesParRayon()['Fruits et légumes'], hasLength(5));
    });

    test('« déjà à la maison » : article barré et retiré du total, réversible', () async {
      final d = await preparer();
      final liste = await d.courses.genererListe(await d.planning.genererSemaine(await inscrireYasmine(d)));
      final dattes = liste.articles.firstWhere((a) => a.ingredient.id == 'datte');
      await d.courses.marquerArticle(dattes);
      expect(dattes.dejaALaMaison, isTrue);
      expect(liste.totalDT, closeTo(55.830 - 6.500, 1e-9));
      expect(liste.resteBudget(60), closeTo(10.670, 1e-9));
      await d.courses.marquerArticle(dattes);
      expect(dattes.dejaALaMaison, isFalse);
      expect(liste.totalDT, closeTo(55.830, 1e-9));
    });

    test('« déjà à la maison » reste coché quand la liste est régénérée', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      final liste = await d.courses.genererListe(planning);
      await d.courses.marquerArticle(liste.articles.firstWhere((a) => a.ingredient.id == 'lait'));
      final nouvelle = await d.courses.genererListe(planning);
      expect(nouvelle.articles.firstWhere((a) => a.ingredient.id == 'lait').dejaALaMaison, isTrue);
      expect(nouvelle.totalDT, closeTo(55.830 - 1.450, 1e-9));
    });

    test('catalogue de plus de 7 jours : prix « indicatifs »', () async {
      final d = await preparer();
      final carrefour = d.depot.enseigne('carrefour').catalogue; // mis à jour le 20 novembre
      final monoprix = d.depot.enseigne('monoprix').catalogue; // mis à jour le 1er novembre
      expect(carrefour.estAJour(), isTrue);
      expect(monoprix.estAJour(), isFalse);
      final u = await inscrireYasmine(d);
      final planning = await d.planning.genererSemaine(u);
      await d.courses.genererListe(planning);
      expect(d.courses.prixIndicatifs, isFalse);
      d.profil
        ..demarrer()
        ..enregistrerEtape(5, {'enseigne': d.depot.enseigne('monoprix')});
      await d.profil.finaliserProfil(u);
      await d.courses.genererListe(planning);
      expect(d.courses.prixIndicatifs, isTrue);
    });
  });

  group('Mettre à jour le catalogue (séquence 7)', () {
    test('Carrefour collecté (nouvelle date et nouveaux prix), Monoprix inaccessible (ancien gardé)', () async {
      final d = await preparer();
      final carrefour = d.depot.enseigne('carrefour');
      final monoprix = d.depot.enseigne('monoprix');
      final feta = d.depot.ingredient('feta');
      expect(carrefour.catalogue.rechercherProduit(feta)!.prixDT, 2.300);
      final dateMonoprix = monoprix.catalogue.dateMiseAJour;
      final resultats = await mettreAJourLesCatalogues(
        outil: OutilCollecteLocal(d.depot),
        enseignes: d.depot.enseignes,
        base: d.base,
        forcer: true,
      );
      expect(resultats, {'carrefour': true, 'monoprix': false});
      expect(carrefour.catalogue.dateMiseAJour, maintenant());
      expect(carrefour.catalogue.rechercherProduit(feta)!.prixDT, 2.400);
      expect(monoprix.catalogue.dateMiseAJour, dateMonoprix);
      expect(await d.base.lire(BaseDeDonnees.catalogues, 'carrefour'), isNotNull);
    });
  });

  group('Faire ses courses (séquence 6)', () {
    test('LIVRAISON : achat créé, liste copiée, lien vers le site de l’enseigne', () async {
      final d = await preparer();
      String? pressePapiers;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
          (appel) async {
        if (appel.method == 'Clipboard.setData') pressePapiers = (appel.arguments as Map)['text'] as String;
        return null;
      });
      final liste = await d.courses.genererListe(await d.planning.genererSemaine(await inscrireYasmine(d)));
      final achat = await d.courses.acheter(liste, ModeAchat.livraison);
      expect(achat.mode, ModeAchat.livraison);
      expect(achat.montantDT, closeTo(55.830, 1e-9));
      expect(d.courses.lien, 'https://www.carrefour.tn');
      expect(pressePapiers, contains('Tomates fraîches'));
      expect(pressePapiers, contains('À acheter ailleurs'));
    });

    test('MAGASIN : lien d’itinéraire vers l’enseigne', () async {
      final d = await preparer();
      final liste = await d.courses.genererListe(await d.planning.genererSemaine(await inscrireYasmine(d)));
      final achat = await d.courses.acheter(liste, ModeAchat.magasin);
      expect(achat.ouvrirEnseigne(), contains('google.com/maps'));
      expect(d.courses.lien, contains('Carrefour'));
    });
  });
}
