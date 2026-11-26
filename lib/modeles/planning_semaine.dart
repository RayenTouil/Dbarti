import '../outils/horloge.dart';
import '../outils/securite.dart';
import 'catalogue.dart';
import 'enumerations.dart';
import 'liste_courses.dart';
import 'recette.dart';
import 'referentiel.dart';
import 'repas.dart';

/// PlanningSemaine — 7 jours × 3 repas.
/// Composition « contient » 1 ◆— 21 Repas : la multiplicité exacte est vérifiée ici.
///
/// Écart documenté : une référence privée vers le catalogue de l'enseigne du profil,
/// pour que coutEstime() puisse chiffrer le panier.
class PlanningSemaine {
  PlanningSemaine({
    required DateTime dateDebut,
    required int cibleKcalJour,
    required List<Repas> repas,
    Catalogue? catalogue,
    String? id,
    DateTime? dateGeneration,
  })  : _id = id ?? nouvelIdentifiant(),
        _dateDebut = jourSeul(dateDebut),
        _cibleKcalJour = cibleKcalJour,
        _dateGeneration = dateGeneration ?? maintenant(),
        _repas = List.of(repas),
        _catalogue = catalogue {
    if (repas.length != nombreDeRepas) {
      throw ArgumentError('Un planning contient exactement $nombreDeRepas repas (reçu : ${repas.length}).');
    }
  }

  static const nombreDeJours = 7;
  static const nombreDeRepas = nombreDeJours * 3; // 21

  final String _id;
  final DateTime _dateDebut;
  final int _cibleKcalJour;
  final DateTime _dateGeneration;
  final List<Repas> _repas;
  Catalogue? _catalogue;

  String get id => _id;
  DateTime get dateDebut => _dateDebut;
  int get cibleKcalJour => _cibleKcalJour;
  DateTime get dateGeneration => _dateGeneration;
  List<Repas> get repas => List.unmodifiable(_repas);
  Catalogue? get catalogue => _catalogue;
  set catalogue(Catalogue? c) => _catalogue = c;

  /// Les 3 repas du jour, du petit-déjeuner au dîner.
  List<Repas> repasDuJour(DateTime jour) =>
      _repas.where((r) => memeJour(r.jour, jour)).toList()..sort((a, b) => a.type.index.compareTo(b.type.index));

  /// Calories du jour (somme des 3 repas, par portion).
  int kcalDuJour(DateTime jour) => repasDuJour(jour).fold(0, (s, r) => s + r.kcal);

  /// Change la recette d'un repas du planning (séquence 4, message 10).
  void remplacerRepas(Repas repas, Recette recette) {
    if (!_repas.contains(repas)) throw ArgumentError('Ce repas n’appartient pas au planning.');
    repas.changerRecette(recette);
  }

  /// Coût du panier de la semaine dans l'enseigne du profil (en dinars).
  double coutEstime() {
    final c = _catalogue;
    if (c == null) return 0;
    return (ListeCourses(catalogue: c)..generer(this)).calculerTotal();
  }

  /// Les 7 jours de la semaine, du lundi au dimanche.
  List<DateTime> get jours => [for (var i = 0; i < nombreDeJours; i++) _dateDebut.add(Duration(days: i))];

  Repas repasDe(DateTime jour, TypeRepas type) =>
      _repas.firstWhere((r) => memeJour(r.jour, jour) && r.type == type);

  factory PlanningSemaine.depuisJson(Map<String, dynamic> j, Referentiel r, {Catalogue? catalogue}) =>
      PlanningSemaine(
        id: j['id'] as String,
        dateDebut: DateTime.parse(j['dateDebut'] as String),
        cibleKcalJour: j['cibleKcalJour'] as int,
        dateGeneration: DateTime.parse(j['dateGeneration'] as String),
        repas: [for (final x in j['repas'] as List) Repas.depuisJson(x as Map<String, dynamic>, r)],
        catalogue: catalogue,
      );

  Map<String, dynamic> versJson() => {
        'id': _id,
        'dateDebut': _dateDebut.toIso8601String(),
        'cibleKcalJour': _cibleKcalJour,
        'dateGeneration': _dateGeneration.toIso8601String(),
        'repas': [for (final r in _repas) r.versJson()],
      };
}
