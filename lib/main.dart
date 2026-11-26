import 'package:flutter/material.dart';

import 'app.dart';
import 'demarrage.dart';
import 'donnees/base_de_donnees.dart';

/// Dbarti — recettes, planning des repas sur 7 jours et liste de courses chiffrée en dinars.
/// Tout est local : aucune clé, aucun serveur. Données de démonstration dans assets/donnees.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final base = await BaseDeDonneesHive.ouvrir();
  final dependances = await Dependances.creer(base: base);
  runApp(AppDbarti(dependances: dependances));
}
