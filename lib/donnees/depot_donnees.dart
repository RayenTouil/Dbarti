import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../modeles/catalogue.dart';
import '../modeles/enseigne.dart';
import '../modeles/enumerations.dart';
import '../modeles/equipement.dart';
import '../modeles/ingredient.dart';
import '../modeles/recette.dart';
import '../modeles/referentiel.dart';

/// Charge les données de démonstration de `assets/donnees/*.json`
/// (recettes, ingrédients, enseignes, catalogues) et les met à disposition par identifiant.
class DepotDonnees implements Referentiel {
  DepotDonnees._();

  final Map<String, Ingredient> _ingredients = {};
  final Map<String, Recette> _recettes = {};
  final Map<String, Enseigne> _enseignes = {};
  final Map<TypeEquipement, Equipement> _equipements = {
    for (final t in TypeEquipement.values) t: Equipement(type: t),
  };
  Map<String, dynamic> _connaissancesAgent = {};

  /// Base de connaissances de l'agent IA local (agent_ia.json).
  Map<String, dynamic> get connaissancesAgent => _connaissancesAgent;

  static Future<DepotDonnees> charger({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    Future<dynamic> lire(String nom) async => jsonDecode(await b.loadString('assets/donnees/$nom'));

    final d = DepotDonnees._();
    for (final j in await lire('ingredients.json') as List) {
      final i = Ingredient.depuisJson(j as Map<String, dynamic>);
      d._ingredients[i.id] = i;
    }
    for (final j in await lire('recettes.json') as List) {
      final r = Recette.depuisJson(j as Map<String, dynamic>, d);
      d._recettes[r.id] = r;
    }
    final catalogues = await lire('catalogues.json') as Map<String, dynamic>;
    for (final j in await lire('enseignes.json') as List) {
      final e = j as Map<String, dynamic>;
      final id = e['id'] as String;
      d._enseignes[id] = Enseigne(
        id: id,
        nom: e['nom'] as String,
        siteWeb: e['siteWeb'] as String,
        livraisonDisponible: e['livraisonDisponible'] as bool,
        description: e['description'] as String? ?? '',
        catalogue: Catalogue.depuisJson(catalogues[id] as Map<String, dynamic>, d),
      );
    }
    d._connaissancesAgent = await lire('agent_ia.json') as Map<String, dynamic>;
    return d;
  }

  @override
  Ingredient ingredient(String id) =>
      _ingredients[id] ?? (throw ArgumentError('Ingrédient inconnu : $id'));

  @override
  Recette recette(String id) => _recettes[id] ?? (throw ArgumentError('Recette inconnue : $id'));

  @override
  Enseigne enseigne(String id) => _enseignes[id] ?? (throw ArgumentError('Enseigne inconnue : $id'));

  @override
  Equipement equipement(TypeEquipement type) => _equipements[type]!;

  @override
  List<Recette> get recettes => List.unmodifiable(_recettes.values);

  @override
  List<Enseigne> get enseignes => List.unmodifiable(_enseignes.values);

  @override
  List<Ingredient> get ingredients => List.unmodifiable(_ingredients.values);

  /// Ingrédients proposés dans « Aliments que je ne mange pas » (écran 06), par ordre alphabétique.
  List<Ingredient> get ingredientsTries =>
      [..._ingredients.values]..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

  /// Cuisines présentes dans les recettes, dans l'ordre de l'écran 07.
  static const cuisines = [
    'Italienne', 'Indienne', 'Mexicaine', 'Méditerranéenne', 'Asiatique', 'Orientale', 'Américaine', 'Française',
  ];
}
