import 'enumerations.dart';

/// Ingredient (diagramme : recettes et planning).
class Ingredient {
  Ingredient({
    required String id,
    required String nom,
    required String rayon,
    required double kcalPour100g,
    List<Allergene> allergenes = const [],
    bool estLocal = true,
  })  : _id = id,
        _nom = nom,
        _rayon = rayon,
        _kcalPour100g = kcalPour100g,
        _allergenes = List.unmodifiable(allergenes),
        _estLocal = estLocal;

  final String _id;
  final String _nom;
  final String _rayon;
  final double _kcalPour100g;
  final List<Allergene> _allergenes;
  final bool _estLocal;

  String get id => _id;
  String get nom => _nom;
  String get rayon => _rayon;
  double get kcalPour100g => _kcalPour100g;
  List<Allergene> get allergenes => _allergenes;
  bool get estLocal => _estLocal;

  factory Ingredient.depuisJson(Map<String, dynamic> j) => Ingredient(
        id: j['id'] as String,
        nom: j['nom'] as String,
        rayon: j['rayon'] as String,
        kcalPour100g: (j['kcalPour100g'] as num).toDouble(),
        allergenes: [
          for (final a in (j['allergenes'] as List? ?? const []))
            enumDepuisNom(Allergene.values, a as String),
        ],
        estLocal: j['estLocal'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) => other is Ingredient && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}
