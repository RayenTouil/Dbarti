import 'enseigne.dart';
import 'enumerations.dart';
import 'equipement.dart';
import 'ingredient.dart';
import 'referentiel.dart';

/// ProfilNutritionnel — les réponses du questionnaire (écrans 04 à 09) et les besoins calculés.
/// Associations : « dispose de » → Equipement [0..*] ; « exclut » → Ingredient [0..*] ;
/// « achète chez » → Enseigne [1].
class ProfilNutritionnel {
  ProfilNutritionnel();

  // Étape 1 — corps
  int? _age;
  Sexe? _sexe;
  int? _tailleCm;
  double? _poidsKg;
  NiveauActivite? _activite;
  // Étape 2 — objectif
  Objectif _objectif = Objectif.equilibre;
  // Étape 3 — contraintes
  Regime _regime = Regime.aucun;
  List<Allergene> _allergies = [];
  List<Ingredient> _exclus = [];
  // Étape 4 — préférences (facultative : valeurs par défaut)
  List<String> _cuisinesPreferees = [];
  int _tempsMaxMinutes = tempsMaxParDefaut;
  // Étape 5 — foyer et budget
  int _nbPersonnes = 1;
  double? _budgetHebdoDT;
  Enseigne? _enseigne;
  // Étape 6 — équipement
  List<Equipement> _equipements = [];
  // Résultats
  int _besoinKcal = 0;
  int _proteinesG = 0;
  int _glucidesG = 0;
  int _lipidesG = 0;

  Map<String, String> _erreurs = {};

  static const tempsMaxParDefaut = 30;
  static const etapes = ['Votre corps', 'Objectif', 'Contraintes', 'Préférences', 'Foyer et budget', 'Équipement'];

  /// Répartition protéines / glucides / lipides (en % des kcal) selon l'objectif.
  /// EQUILIBRE vient de l'écran 11 ; les trois autres sont des valeurs de démonstration.
  static const repartitionMacros = {
    Objectif.equilibre: (18, 52, 30),
    Objectif.perteDePoids: (25, 45, 30),
    Objectif.priseDeMuscle: (25, 50, 25),
    Objectif.glycemie: (20, 45, 35),
  };

  int? get age => _age;
  Sexe? get sexe => _sexe;
  int? get tailleCm => _tailleCm;
  double? get poidsKg => _poidsKg;
  NiveauActivite? get activite => _activite;
  Objectif get objectif => _objectif;
  Regime get regime => _regime;
  List<Allergene> get allergies => List.unmodifiable(_allergies);
  List<Ingredient> get exclus => List.unmodifiable(_exclus);
  List<String> get cuisinesPreferees => List.unmodifiable(_cuisinesPreferees);
  int get tempsMaxMinutes => _tempsMaxMinutes;
  int get nbPersonnes => _nbPersonnes;
  double? get budgetHebdoDT => _budgetHebdoDT;
  Enseigne? get enseigne => _enseigne;
  List<Equipement> get equipements => List.unmodifiable(_equipements);
  int get besoinKcal => _besoinKcal;
  int get proteinesG => _proteinesG;
  int get glucidesG => _glucidesG;
  int get lipidesG => _lipidesG;

  /// Messages d'erreur de la dernière validation, par champ (affichés sous le champ).
  Map<String, String> get erreurs => Map.unmodifiable(_erreurs);

  set age(int? v) => _age = v;
  set sexe(Sexe? v) => _sexe = v;
  set tailleCm(int? v) => _tailleCm = v;
  set poidsKg(double? v) => _poidsKg = v;
  set activite(NiveauActivite? v) => _activite = v;
  set objectif(Objectif v) => _objectif = v;
  set regime(Regime v) => _regime = v;
  set allergies(List<Allergene> v) => _allergies = List.of(v);
  set exclus(List<Ingredient> v) => _exclus = List.of(v);
  set cuisinesPreferees(List<String> v) => _cuisinesPreferees = List.of(v);
  set tempsMaxMinutes(int v) => _tempsMaxMinutes = v;
  set nbPersonnes(int v) => _nbPersonnes = v;
  set budgetHebdoDT(double? v) => _budgetHebdoDT = v;
  set enseigne(Enseigne? v) => _enseigne = v;
  set equipements(List<Equipement> v) => _equipements = List.of(v);

  /// Valide une étape du questionnaire (1 à 6). Faux si une valeur est hors limites :
  /// le message est alors disponible dans [erreurs] (séquence 2, messages 4 à 8).
  bool valider(int etape) {
    _erreurs = _erreursEtape(etape);
    return _erreurs.isEmpty;
  }

  Map<String, String> _erreursEtape(int etape) {
    final e = <String, String>{};
    switch (etape) {
      case 1:
        if (_age == null || _age! < 16 || _age! > 100) e['age'] = 'Entrez un âge entre 16 et 100 ans.';
        if (_sexe == null) e['sexe'] = 'Choisissez Femme ou Homme.';
        if (_tailleCm == null || _tailleCm! < 100 || _tailleCm! > 250) {
          e['taille'] = 'Entrez une taille entre 100 et 250 cm, par exemple 165.';
        }
        if (_poidsKg == null || _poidsKg! < 30 || _poidsKg! > 250) {
          e['poids'] = 'Entrez un poids entre 30 et 250 kg, par exemple 58.';
        }
        if (_activite == null) e['activite'] = 'Choisissez votre niveau d’activité.';
      case 2 || 3 || 4:
        break; // choix toujours valides (valeurs par défaut)
      case 5:
        if (_nbPersonnes < 1 || _nbPersonnes > 10) e['personnes'] = 'Entre 1 et 10 personnes.';
        if (_budgetHebdoDT == null || _budgetHebdoDT! < 10 || _budgetHebdoDT! > 1000) {
          e['budget'] = 'Entrez un budget entre 10 et 1 000 DT, par exemple 60.';
        }
        if (_enseigne == null) e['enseigne'] = 'Choisissez votre enseigne.';
      case 6:
        if (_equipements.isEmpty) e['equipement'] = 'Cochez au moins un appareil de cuisine.';
      default:
        throw RangeError.range(etape, 1, 6, 'etape');
    }
    return e;
  }

  /// Formule de Mifflin-St Jeor × facteur d'activité, arrondie à 10 kcal.
  /// Objectif « perte de poids » : −400 kcal par jour (écran 05).
  /// Yasmine (F, 21 ans, 165 cm, 58 kg, modérément active) → 2 090 kcal.
  int calculerBesoin() {
    final base = 10 * _poidsKg! + 6.25 * _tailleCm! - 5 * _age! + (_sexe == Sexe.homme ? 5 : -161);
    var besoin = base * _activite!.facteur;
    if (_objectif == Objectif.perteDePoids) besoin -= 400;
    _besoinKcal = (besoin / 10).round() * 10;
    return _besoinKcal;
  }

  /// Protéines et glucides : 4 kcal par gramme ; lipides : 9 kcal par gramme.
  void calculerMacros() {
    final (p, g, l) = repartitionMacros[_objectif]!;
    _proteinesG = (_besoinKcal * p / 100 / 4).round();
    _glucidesG = (_besoinKcal * g / 100 / 4).round();
    _lipidesG = (_besoinKcal * l / 100 / 9).round();
  }

  /// Vrai si les 6 étapes sont valides et le besoin calculé.
  bool estComplet() =>
      [1, 2, 3, 4, 5, 6].every((i) => _erreursEtape(i).isEmpty) && _besoinKcal > 0;

  /// Copie indépendante (pour modifier le profil sans toucher l'original avant validation).
  ProfilNutritionnel copie(Referentiel r) => ProfilNutritionnel.depuisJson(versJson(), r);

  factory ProfilNutritionnel.depuisJson(Map<String, dynamic> j, Referentiel r) {
    final p = ProfilNutritionnel()
      .._age = j['age'] as int?
      .._sexe = j['sexe'] == null ? null : enumDepuisNom(Sexe.values, j['sexe'] as String)
      .._tailleCm = j['tailleCm'] as int?
      .._poidsKg = (j['poidsKg'] as num?)?.toDouble()
      .._activite = j['activite'] == null ? null : enumDepuisNom(NiveauActivite.values, j['activite'] as String)
      .._objectif = enumDepuisNom(Objectif.values, j['objectif'] as String)
      .._regime = enumDepuisNom(Regime.values, j['regime'] as String)
      .._allergies = [for (final a in j['allergies'] as List) enumDepuisNom(Allergene.values, a as String)]
      .._exclus = [for (final i in j['exclus'] as List) r.ingredient(i as String)]
      .._cuisinesPreferees = List<String>.from(j['cuisinesPreferees'] as List)
      .._tempsMaxMinutes = j['tempsMaxMinutes'] as int
      .._nbPersonnes = j['nbPersonnes'] as int
      .._budgetHebdoDT = (j['budgetHebdoDT'] as num?)?.toDouble()
      .._enseigne = j['enseigne'] == null ? null : r.enseigne(j['enseigne'] as String)
      .._equipements = [
        for (final t in j['equipements'] as List) r.equipement(enumDepuisNom(TypeEquipement.values, t as String)),
      ]
      .._besoinKcal = j['besoinKcal'] as int? ?? 0
      .._proteinesG = j['proteinesG'] as int? ?? 0
      .._glucidesG = j['glucidesG'] as int? ?? 0
      .._lipidesG = j['lipidesG'] as int? ?? 0;
    return p;
  }

  Map<String, dynamic> versJson() => {
        'age': _age,
        'sexe': _sexe?.name,
        'tailleCm': _tailleCm,
        'poidsKg': _poidsKg,
        'activite': _activite?.name,
        'objectif': _objectif.name,
        'regime': _regime.name,
        'allergies': [for (final a in _allergies) a.name],
        'exclus': [for (final i in _exclus) i.id],
        'cuisinesPreferees': _cuisinesPreferees,
        'tempsMaxMinutes': _tempsMaxMinutes,
        'nbPersonnes': _nbPersonnes,
        'budgetHebdoDT': _budgetHebdoDT,
        'enseigne': _enseigne?.id,
        'equipements': [for (final e in _equipements) e.type.name],
        'besoinKcal': _besoinKcal,
        'proteinesG': _proteinesG,
        'glucidesG': _glucidesG,
        'lipidesG': _lipidesG,
      };
}
