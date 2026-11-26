import 'package:dbarti/demarrage.dart';
import 'package:dbarti/donnees/base_de_donnees.dart';
import 'package:dbarti/externes/agent_ia.dart';
import 'package:dbarti/modeles/enumerations.dart';
import 'package:dbarti/modeles/utilisateur.dart';
import 'package:dbarti/outils/horloge.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mardi 24 novembre 2026 : la semaine des tests va du lundi 23 au dimanche 29.
final aujourdhuiDesTests = DateTime(2026, 11, 24, 9);

/// Prépare l'application avec une base en mémoire et l'horloge fixée.
Future<Dependances> preparer({AgentIA? agent, bool collecter = false}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  maintenant = () => aujourdhuiDesTests;
  return Dependances.creer(base: BaseDeDonneesMemoire(), agent: agent, collecter: collecter);
}

/// Crée le compte de Yasmine et remplit les 6 étapes du questionnaire (persona de la semaine 2).
Future<Utilisateur> inscrireYasmine(Dependances d) async {
  final u = await d.auth.inscrire('Yasmine Trabelsi', 'yasmine@exemple.tn', 'soleil2024', true);
  final s = d.profil..demarrer();
  final depot = d.depot;
  expect(s.enregistrerEtape(1, {
    'age': 21,
    'sexe': Sexe.femme,
    'tailleCm': 165,
    'poidsKg': 58.0,
    'activite': NiveauActivite.moderementActif,
  }), isTrue);
  expect(s.enregistrerEtape(2, {'objectif': Objectif.equilibre}), isTrue);
  expect(s.enregistrerEtape(3, {
    'regime': Regime.aucun,
    'allergies': [Allergene.arachides],
    'exclus': [depot.ingredient('aubergine')],
  }), isTrue);
  expect(s.enregistrerEtape(4, {
    'cuisinesPreferees': ['Italienne', 'Indienne', 'Mexicaine'],
    'tempsMaxMinutes': 30,
  }), isTrue);
  expect(s.enregistrerEtape(5, {
    'nbPersonnes': 1,
    'budgetHebdoDT': 60.0,
    'enseigne': depot.enseigne('carrefour'),
  }), isTrue);
  expect(s.enregistrerEtape(6, {
    'equipements': [
      for (final t in [TypeEquipement.plaque, TypeEquipement.casserole, TypeEquipement.poele, TypeEquipement.microOndes])
        depot.equipement(t),
    ],
  }), isTrue);
  await s.finaliserProfil(u);
  return u;
}
