import 'ingredient.dart';
import 'referentiel.dart';

/// Produit — un article réel du catalogue d'une enseigne.
/// Association « correspond à » → Ingredient [1].
class Produit {
  Produit({
    required String reference,
    required String libelle,
    required String conditionnement,
    required double prixDT,
    required String rayon,
    required Ingredient ingredient,
  })  : _reference = reference,
        _libelle = libelle,
        _conditionnement = conditionnement,
        _prixDT = prixDT,
        _rayon = rayon,
        _ingredient = ingredient;

  final String _reference;
  final String _libelle;
  final String _conditionnement;
  final double _prixDT;
  final String _rayon;
  final Ingredient _ingredient;

  String get reference => _reference;
  String get libelle => _libelle;
  String get conditionnement => _conditionnement;
  double get prixDT => _prixDT;
  String get rayon => _rayon;
  Ingredient get ingredient => _ingredient;

  /// Contenu d'un conditionnement, dans l'unité des recettes : « 1 kg » → 1000 g.
  ({double quantite, String unite}) get contenu => contenuDuConditionnement(_conditionnement);

  factory Produit.depuisJson(Map<String, dynamic> j, Referentiel r) => Produit(
        reference: j['reference'] as String,
        libelle: j['libelle'] as String,
        conditionnement: j['conditionnement'] as String,
        prixDT: (j['prixDT'] as num).toDouble(),
        rayon: j['rayon'] as String,
        ingredient: r.ingredient(j['ingredient'] as String),
      );

  Map<String, dynamic> versJson() => {
        'reference': _reference,
        'libelle': _libelle,
        'conditionnement': _conditionnement,
        'prixDT': _prixDT,
        'rayon': _rayon,
        'ingredient': _ingredient.id,
      };
}

final _motif = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(kg|g|L|l|ml|cl|pièces?|pots?)$');

/// Lit un conditionnement (« 400 g », « 1 kg », « 1 L », « 6 pièces », « 4 pots »).
({double quantite, String unite}) contenuDuConditionnement(String texte) {
  final m = _motif.firstMatch(texte.trim());
  if (m == null) throw FormatException('Conditionnement illisible : $texte');
  final n = double.parse(m.group(1)!.replaceAll(',', '.'));
  return switch (m.group(2)!) {
    'kg' => (quantite: n * 1000, unite: 'g'),
    'g' => (quantite: n, unite: 'g'),
    'L' || 'l' => (quantite: n * 1000, unite: 'ml'),
    'cl' => (quantite: n * 10, unite: 'ml'),
    'ml' => (quantite: n, unite: 'ml'),
    'pièce' || 'pièces' => (quantite: n, unite: 'pièce'),
    _ => (quantite: n, unite: 'pot'),
  };
}
