import 'ingredient.dart';
import 'produit.dart';
import 'referentiel.dart';

/// ArticleCourse — une ligne de la liste de courses.
/// Associations : « pour » → Ingredient [1] ; « associé à » → Produit [0..1]
/// (0 : l'ingrédient n'est pas au catalogue, il est « à acheter ailleurs »).
///
/// Écart documenté : [nbRecettes] (privé) garde le nombre de repas qui utilisent
/// l'ingrédient, affiché à l'écran 16 (« 1 kg · 4 recettes »).
class ArticleCourse {
  ArticleCourse({
    required double quantite,
    required String unite,
    required double prixDT,
    required Ingredient ingredient,
    Produit? produit,
    bool dejaALaMaison = false,
    int nbRecettes = 1,
  })  : _quantite = quantite,
        _unite = unite,
        _prixDT = prixDT,
        _ingredient = ingredient,
        _produit = produit,
        _dejaALaMaison = dejaALaMaison,
        _nbRecettes = nbRecettes;

  final double _quantite;
  final String _unite;
  final double _prixDT;
  bool _dejaALaMaison;
  final Ingredient _ingredient;
  final Produit? _produit;
  final int _nbRecettes;

  double get quantite => _quantite;
  String get unite => _unite;
  double get prixDT => _prixDT;
  bool get dejaALaMaison => _dejaALaMaison;
  Ingredient get ingredient => _ingredient;
  Produit? get produit => _produit;
  int get nbRecettes => _nbRecettes;

  /// Nombre de conditionnements à acheter (2 pour « 2 × 400 g »).
  int get nbConditionnements =>
      _produit == null ? 0 : (_prixDT / _produit.prixDT).round();

  /// Coche ou décoche « déjà à la maison » : l'article est barré et retiré du total.
  /// Un nouvel appui annule le choix (écran 16 : « réversible en un appui »).
  void marquerDejaALaMaison() => _dejaALaMaison = !_dejaALaMaison;

  /// Vrai si aucun produit de l'enseigne ne correspond à l'ingrédient.
  bool aAcheterAilleurs() => _produit == null;

  /// Prix compté dans le total : 0 si l'article est déjà à la maison ou à acheter ailleurs.
  double get prixCompte => _dejaALaMaison || _produit == null ? 0 : _prixDT;

  factory ArticleCourse.depuisJson(Map<String, dynamic> j, Referentiel r, Produit? Function(String) produit) =>
      ArticleCourse(
        quantite: (j['quantite'] as num).toDouble(),
        unite: j['unite'] as String,
        prixDT: (j['prixDT'] as num).toDouble(),
        ingredient: r.ingredient(j['ingredient'] as String),
        produit: j['produit'] == null ? null : produit(j['produit'] as String),
        dejaALaMaison: j['dejaALaMaison'] as bool? ?? false,
        nbRecettes: j['nbRecettes'] as int? ?? 1,
      );

  Map<String, dynamic> versJson() => {
        'quantite': _quantite,
        'unite': _unite,
        'prixDT': _prixDT,
        'ingredient': _ingredient.id,
        'produit': _produit?.reference,
        'dejaALaMaison': _dejaALaMaison,
        'nbRecettes': _nbRecettes,
      };
}
