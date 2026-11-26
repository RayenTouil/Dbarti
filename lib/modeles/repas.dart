import 'adaptation.dart';
import 'enumerations.dart';
import 'recette.dart';
import 'referentiel.dart';

/// Repas — un des 21 repas du planning.
/// Association « utilise » → Recette [1] ; composition « porte » 1 ◆— 0..* Adaptation.
class Repas {
  Repas({
    required DateTime jour,
    required TypeRepas type,
    required int portions,
    required Recette recette,
    List<Adaptation> adaptations = const [],
  })  : _jour = jour,
        _type = type,
        _portions = portions,
        _recette = recette,
        _kcal = recette.kcalParPortion,
        _adaptations = List.of(adaptations);

  final DateTime _jour;
  final TypeRepas _type;
  final int _portions;
  int _kcal;
  Recette _recette;
  final List<Adaptation> _adaptations;

  DateTime get jour => _jour;
  TypeRepas get type => _type;
  int get portions => _portions;
  int get kcal => _kcal;
  Recette get recette => _recette;
  List<Adaptation> get adaptations => List.unmodifiable(_adaptations);

  /// Change la recette du repas. Les adaptations de l'ancienne recette disparaissent.
  void changerRecette(Recette recette) {
    _recette = recette;
    _kcal = recette.kcalParPortion;
    _adaptations.clear();
  }

  /// Ajoute les adaptations proposées par l'agent IA (composition : le repas les possède).
  void ajouterAdaptations(List<Adaptation> adaptations) => _adaptations.addAll(adaptations);

  bool get estAdapte => _adaptations.isNotEmpty;

  factory Repas.depuisJson(Map<String, dynamic> j, Referentiel r) => Repas(
        jour: DateTime.parse(j['jour'] as String),
        type: enumDepuisNom(TypeRepas.values, j['type'] as String),
        portions: j['portions'] as int,
        recette: r.recette(j['recette'] as String),
        adaptations: [
          for (final a in (j['adaptations'] as List? ?? const []))
            Adaptation.depuisJson(a as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> versJson() => {
        'jour': _jour.toIso8601String(),
        'type': _type.name,
        'portions': _portions,
        'kcal': _kcal,
        'recette': _recette.id,
        'adaptations': [for (final a in _adaptations) a.versJson()],
      };
}
