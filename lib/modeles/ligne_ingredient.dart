import 'ingredient.dart';
import 'referentiel.dart';

/// LigneIngredient — quantité d'un ingrédient dans une recette.
/// L'unité est celle du produit vendu (g, ml, pièce, pot) pour pouvoir chiffrer la liste.
class LigneIngredient {
  LigneIngredient({required double quantite, required String unite, required Ingredient ingredient})
      : _quantite = quantite,
        _unite = unite,
        _ingredient = ingredient;

  double _quantite;
  final String _unite;
  final Ingredient _ingredient; // association « LigneIngredient → Ingredient » [1]

  double get quantite => _quantite;
  String get unite => _unite;
  Ingredient get ingredient => _ingredient;

  /// Utilisé par Recette.ajusterPortions().
  set quantite(double valeur) => _quantite = valeur;

  factory LigneIngredient.depuisJson(Map<String, dynamic> j, Referentiel r) => LigneIngredient(
        quantite: (j['quantite'] as num).toDouble(),
        unite: j['unite'] as String,
        ingredient: r.ingredient(j['ingredient'] as String),
      );

  Map<String, dynamic> versJson() =>
      {'quantite': _quantite, 'unite': _unite, 'ingredient': _ingredient.id};
}
