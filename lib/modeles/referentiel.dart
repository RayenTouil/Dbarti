import 'enseigne.dart';
import 'enumerations.dart';
import 'equipement.dart';
import 'ingredient.dart';
import 'recette.dart';

/// Données de référence (recettes, ingrédients, enseignes, appareils), chargées depuis
/// `assets/donnees`. Sert à retrouver un objet à partir de son identifiant quand un
/// objet enregistré (planning, liste…) est relu depuis la base.
abstract class Referentiel {
  Ingredient ingredient(String id);
  Recette recette(String id);
  Enseigne enseigne(String id);
  Equipement equipement(TypeEquipement type);
  List<Recette> get recettes;
  List<Enseigne> get enseignes;
  List<Ingredient> get ingredients;
}
