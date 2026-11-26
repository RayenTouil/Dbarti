import '../outils/horloge.dart';
import 'ingredient.dart';
import 'produit.dart';
import 'referentiel.dart';

/// Catalogue — produits et prix d'une enseigne, mis à jour par l'outil de collecte.
/// Composition « contient » 1 ◆— 0..* Produit.
class Catalogue {
  Catalogue({required DateTime dateMiseAJour, List<Produit> produits = const []})
      : _dateMiseAJour = dateMiseAJour,
        _produits = List.of(produits);

  /// Au-delà de cette durée, les prix sont « indicatifs » (séquences 5 et 7).
  static const dureeValidite = Duration(days: 7);

  DateTime _dateMiseAJour;
  final List<Produit> _produits;

  DateTime get dateMiseAJour => _dateMiseAJour;
  List<Produit> get produits => List.unmodifiable(_produits);

  /// Le produit du catalogue qui correspond à l'ingrédient (le moins cher à l'unité),
  /// ou null : l'ingrédient est alors « à acheter ailleurs ».
  Produit? rechercherProduit(Ingredient ingredient) {
    final candidats = _produits.where((p) => p.ingredient == ingredient).toList();
    if (candidats.isEmpty) return null;
    candidats.sort((a, b) => (a.prixDT / a.contenu.quantite).compareTo(b.prixDT / b.contenu.quantite));
    return candidats.first;
  }

  /// Vrai si la dernière mise à jour date de 7 jours ou moins.
  bool estAJour() => maintenant().difference(_dateMiseAJour) <= dureeValidite;

  /// Remplace les produits et les prix par ceux de la collecte (séquence 7, message 6).
  void mettreAJour(List<Produit> produits) {
    _produits
      ..clear()
      ..addAll(produits);
    _dateMiseAJour = maintenant();
  }

  /// Remet le contenu d'un catalogue enregistré lors d'une collecte précédente.
  void restaurer(Catalogue enregistre) {
    _produits
      ..clear()
      ..addAll(enregistre._produits);
    _dateMiseAJour = enregistre._dateMiseAJour;
  }

  factory Catalogue.depuisJson(Map<String, dynamic> j, Referentiel r) => Catalogue(
        dateMiseAJour: DateTime.parse(j['dateMiseAJour'] as String),
        produits: [
          for (final p in j['produits'] as List) Produit.depuisJson(p as Map<String, dynamic>, r),
        ],
      );

  Map<String, dynamic> versJson() => {
        'dateMiseAJour': _dateMiseAJour.toIso8601String(),
        'produits': [for (final p in _produits) p.versJson()],
      };
}
