import 'package:dbarti/donnees/depot_donnees.dart';
import 'package:dbarti/externes/agent_ia.dart';
import 'package:dbarti/externes/agent_ia_local.dart';
import 'package:dbarti/modeles/adaptation.dart';
import 'package:dbarti/modeles/enumerations.dart';
import 'package:dbarti/modeles/equipement.dart';
import 'package:dbarti/modeles/planning_semaine.dart';
import 'package:dbarti/modeles/profil_nutritionnel.dart';
import 'package:dbarti/modeles/recette.dart';
import 'package:dbarti/modeles/repas.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aide.dart';

/// Agent qui ne répond pas (connexion perdue) — séquence 3, alt « pas de réponse ».
class AgentEnPanne implements AgentIA {
  AgentEnPanne(this._depot);
  final DepotDonnees _depot;
  bool enPanne = false;

  AgentIALocal get _local => AgentIALocal(_depot);

  @override
  Future<List<Repas>> composerMenus(ProfilNutritionnel p) =>
      enPanne ? Future.error(ErreurAgentIA('Pas de réponse de l’agent IA.')) : _local.composerMenus(p);

  @override
  Future<List<Adaptation>> adapterRecette(Recette r, List<Equipement> manquants) => _local.adapterRecette(r, manquants);

  @override
  Future<List<Recette>> proposerRecettes(Repas repas, int n) => _local.proposerRecettes(repas, n);
}

void main() {
  group('Générer le planning (séquence 3)', () {
    test('le planning contient exactement 21 repas : 7 jours × 3 repas', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      expect(planning.repas, hasLength(21));
      expect(planning.jours, hasLength(7));
      for (final jour in planning.jours) {
        expect(planning.repasDuJour(jour).map((r) => r.type), TypeRepas.values);
      }
      expect(planning.dateDebut.weekday, DateTime.monday);
      expect(planning.cibleKcalJour, 2090);
    });

    test('la multiplicité 21 est vérifiée par le constructeur', () async {
      final d = await preparer();
      final repas = (await d.planning.genererSemaine(await inscrireYasmine(d))).repas;
      expect(() => PlanningSemaine(dateDebut: DateTime(2026, 11, 23), cibleKcalJour: 2090, repas: repas.take(20).toList()),
          throwsArgumentError);
      expect(
          () => PlanningSemaine(
              dateDebut: DateTime(2026, 11, 23), cibleKcalJour: 2090, repas: [...repas, repas.first]),
          throwsArgumentError);
    });

    test('filtre strict des allergènes : aucune recette avec des arachides', () async {
      final d = await preparer();
      final u = await inscrireYasmine(d);
      // L'agent propose bien des plats aux arachides (il ne gère pas les allergies)…
      final propose = await d.agent.composerMenus(u.profil!);
      expect(propose.any((r) => r.recette.contientAllergene([Allergene.arachides])), isTrue);
      // … mais le code les retire tous.
      final planning = await d.planning.genererSemaine(u);
      expect(planning.repas.where((r) => r.recette.contientAllergene([Allergene.arachides])), isEmpty);
      expect(planning.repas.map((r) => r.recette.id), isNot(contains('r-tartine-cacahuete')));
      expect(planning.repas.map((r) => r.recette.id), isNot(contains('r-nouilles-cacahuete')));
    });

    test('filtre des exclusions : aucune recette avec de l’aubergine', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      final aubergine = d.depot.ingredient('aubergine');
      expect(planning.repas.where((r) => r.recette.contientIngredient([aubergine])), isEmpty);
    });

    test('adaptation « Sans mixeur » sur le curry, recette inchangée', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      final curry = planning.repas.firstWhere((r) => r.recette.id == 'r-curry');
      final mixeur = d.depot.equipement(TypeEquipement.mixeur);
      expect(curry.recette.equipements, contains(mixeur)); // la recette demande toujours un mixeur
      final sansMixeur = curry.adaptations.where((a) => a.type == TypeAdaptation.equipement).single;
      expect(sansMixeur.description, startsWith('Sans mixeur'));
      expect(sansMixeur.ordreEtape, 4);
      expect(sansMixeur.instruction, contains('fourchette'));
      expect(curry.adaptations.where((a) => a.type == TypeAdaptation.ingredientLocal), hasLength(1));
    });

    test('appareil manquant sans méthode de remplacement : la recette est retirée (pizza au four)', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      expect(planning.repas.map((r) => r.recette.id), isNot(contains('r-pizza-thon')));
      final four = d.depot.equipement(TypeEquipement.four);
      expect(planning.repas.where((r) => r.recette.equipements.contains(four)), isEmpty);
    });

    test('lundi : porridge, curry, penne au thon — 1 960 sur 2 090 kcal (écran 12)', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      final lundi = planning.repasDuJour(planning.dateDebut);
      expect(lundi.map((r) => r.recette.titre),
          ['Porridge aux dattes', 'Curry de pois chiches et riz', 'Penne au thon et tomates']);
      expect(planning.kcalDuJour(planning.dateDebut), 1960);
    });

    test('coutEstime() = 55,830 DT, dans le budget de 60 DT', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      expect(planning.coutEstime(), closeTo(55.830, 1e-9));
      expect(d.planning.depassement, isNull);
    });

    test('panier au-dessus du budget : écart et repas les plus chers signalés', () async {
      final d = await preparer();
      final u = await inscrireYasmine(d);
      d.profil
        ..demarrer()
        ..enregistrerEtape(5, {'budgetHebdoDT': 50.0});
      await d.profil.finaliserProfil(u);
      await d.planning.genererSemaine(u);
      final depassement = d.planning.depassement!;
      expect(depassement.ecart, closeTo(5.830, 1e-9));
      expect(depassement.plusChers, hasLength(3));
    });

    test('l’agent ne répond pas : erreur « Réessayer », l’ancien planning reste', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final depot = await DepotDonnees.charger();
      final agent = AgentEnPanne(depot);
      final d = await preparer(agent: agent);
      final u = await inscrireYasmine(d);
      final ancien = await d.planning.genererSemaine(u);
      agent.enPanne = true;
      await expectLater(d.planning.genererSemaine(u), throwsA(isA<ErreurAgentIA>()));
      expect(d.planning.erreur, isNotNull);
      expect(d.planning.planning, same(ancien));
    });
  });

  group('Remplacer un repas (séquence 4)', () {
    test('3 recettes compatibles, différentes des autres repas du jour, avec l’écart de prix', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      final diner = planning.repasDuJour(planning.dateDebut).last;
      final propositions = await d.planning.proposerRemplacements(diner);
      expect(propositions, hasLength(3));
      final memeJour = planning.repasDuJour(diner.jour).map((r) => r.recette);
      for (final r in propositions) {
        expect(r.contientAllergene([Allergene.arachides]), isFalse);
        expect(memeJour, isNot(contains(r)));
      }
      expect(d.planning.ecartDePrix(diner, propositions.first), isNot(0));
    });

    test('Remplacer : le repas change, le coût est recalculé et la liste existante est régénérée', () async {
      final d = await preparer();
      final planning = await d.planning.genererSemaine(await inscrireYasmine(d));
      await d.courses.genererListe(planning);
      final diner = planning.repasDuJour(planning.dateDebut).last;
      final choix = (await d.planning.proposerRemplacements(diner)).first;
      final ecart = d.planning.ecartDePrix(diner, choix);
      await d.planning.remplacer(diner, choix);
      expect(diner.recette, choix);
      expect(planning.coutEstime(), closeTo(55.830 + ecart, 1e-9));
      expect(d.courses.liste!.totalDT, closeTo(55.830 + ecart, 1e-9));
    });
  });
}
