import 'enumerations.dart';
import 'equipement.dart';
import 'etape_recette.dart';
import 'ingredient.dart';
import 'ligne_ingredient.dart';
import 'referentiel.dart';

/// Recette (diagramme : recettes et planning).
/// Composition : 1 ◆— 1..* LigneIngredient (« liste ») et 1 ◆— 1..* EtapeRecette {ordonnées}.
/// Association : « nécessite » → Equipement [0..*].
class Recette {
  Recette({
    required String id,
    required String titre,
    required String photoUrl,
    required int tempsPreparationMin,
    required int portions,
    required int kcalParPortion,
    required List<Regime> regimesCompatibles,
    required String cuisine,
    required List<LigneIngredient> lignes,
    required List<EtapeRecette> etapes,
    List<Equipement> equipements = const [],
  })  : assert(lignes.isNotEmpty && etapes.isNotEmpty),
        _id = id,
        _titre = titre,
        _photoUrl = photoUrl,
        _tempsPreparationMin = tempsPreparationMin,
        _portions = portions,
        _kcalParPortion = kcalParPortion,
        _regimesCompatibles = List.unmodifiable(regimesCompatibles),
        _cuisine = cuisine,
        _lignes = List.of(lignes),
        _etapes = List.of(etapes)..sort((a, b) => a.ordre.compareTo(b.ordre)),
        _equipements = List.unmodifiable(equipements);

  final String _id;
  final String _titre;
  final String _photoUrl;
  final int _tempsPreparationMin;
  int _portions;
  final int _kcalParPortion;
  final List<Regime> _regimesCompatibles;
  final String _cuisine;
  final List<LigneIngredient> _lignes;
  final List<EtapeRecette> _etapes;
  final List<Equipement> _equipements;

  String get id => _id;
  String get titre => _titre;
  String get photoUrl => _photoUrl;
  int get tempsPreparationMin => _tempsPreparationMin;
  int get portions => _portions;
  int get kcalParPortion => _kcalParPortion;
  List<Regime> get regimesCompatibles => _regimesCompatibles;
  String get cuisine => _cuisine;
  List<LigneIngredient> get lignes => List.unmodifiable(_lignes);
  List<EtapeRecette> get etapes => List.unmodifiable(_etapes);
  List<Equipement> get equipements => _equipements;

  /// Vrai si au moins un ingrédient porte un des allergènes donnés.
  bool contientAllergene(List<Allergene> allergies) => _lignes.any(
      (l) => l.ingredient.allergenes.any(allergies.contains));

  /// Vrai si la recette utilise un des ingrédients exclus.
  bool contientIngredient(List<Ingredient> exclus) =>
      _lignes.any((l) => exclus.contains(l.ingredient));

  /// Appareils nécessaires que l'utilisateur n'a pas.
  List<Equipement> equipementsManquants(List<Equipement> dispo) =>
      _equipements.where((e) => !dispo.contains(e)).toList();

  /// Recalcule les quantités pour [n] portions (écran 14).
  void ajusterPortions(int n) {
    if (n < 1 || n == _portions) return;
    final facteur = n / _portions;
    for (final l in _lignes) {
      l.quantite = l.quantite * facteur;
    }
    _portions = n;
  }

  /// Vrai si la recette convient au régime (AUCUN : toutes les recettes conviennent).
  bool convientAuRegime(Regime regime) =>
      regime == Regime.aucun || _regimesCompatibles.contains(regime);

  /// Copie indépendante, pour ajuster les portions à l'écran sans toucher la base.
  Recette copie(Referentiel r) => Recette.depuisJson(versJson(), r);

  factory Recette.depuisJson(Map<String, dynamic> j, Referentiel r) => Recette(
        id: j['id'] as String,
        titre: j['titre'] as String,
        photoUrl: j['photoUrl'] as String? ?? '',
        tempsPreparationMin: j['tempsPreparationMin'] as int,
        portions: j['portions'] as int,
        kcalParPortion: j['kcalParPortion'] as int,
        regimesCompatibles: [
          for (final x in j['regimesCompatibles'] as List) enumDepuisNom(Regime.values, x as String),
        ],
        cuisine: j['cuisine'] as String,
        lignes: [
          for (final l in j['lignes'] as List) LigneIngredient.depuisJson(l as Map<String, dynamic>, r),
        ],
        etapes: [
          for (final e in j['etapes'] as List) EtapeRecette.depuisJson(e as Map<String, dynamic>),
        ],
        equipements: [
          for (final t in (j['equipements'] as List? ?? const []))
            r.equipement(enumDepuisNom(TypeEquipement.values, t as String)),
        ],
      );

  Map<String, dynamic> versJson() => {
        'id': _id,
        'titre': _titre,
        'photoUrl': _photoUrl,
        'tempsPreparationMin': _tempsPreparationMin,
        'portions': _portions,
        'kcalParPortion': _kcalParPortion,
        'regimesCompatibles': [for (final x in _regimesCompatibles) x.name],
        'cuisine': _cuisine,
        'lignes': [for (final l in _lignes) l.versJson()],
        'etapes': [for (final e in _etapes) e.versJson()],
        'equipements': [for (final e in _equipements) e.type.name],
      };

  @override
  bool operator ==(Object other) => other is Recette && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}
