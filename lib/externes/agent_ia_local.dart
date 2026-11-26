import '../donnees/depot_donnees.dart';
import '../modeles/adaptation.dart';
import '../modeles/enumerations.dart';
import '../modeles/equipement.dart';
import '../modeles/profil_nutritionnel.dart';
import '../modeles/recette.dart';
import '../modeles/repas.dart';
import '../outils/horloge.dart';
import 'agent_ia.dart';

/// Agent IA par défaut : à base de règles, hors ligne, sans clé.
/// Sa « connaissance » est dans assets/donnees/agent_ia.json :
/// - les semaines types par régime (quels plats à quel repas),
/// - les méthodes de remplacement quand un appareil manque,
/// - les ingrédients remplacés par un produit local.
class AgentIALocal implements AgentIA {
  AgentIALocal(this._depot);

  final DepotDonnees _depot;

  Map<String, dynamic> get _savoir => _depot.connaissancesAgent;

  /// Types de repas où une recette peut être servie.
  List<TypeRepas> typesDe(Recette r) => [
        for (final t in (_savoir['typesDeRepas'] as Map<String, dynamic>)[r.id] as List? ?? const [])
          enumDepuisNom(TypeRepas.values, t as String),
      ];

  @override
  Future<List<Repas>> composerMenus(ProfilNutritionnel p) async {
    final lundi = lundiDe(maintenant());
    final semaines = _savoir['semainesTypes'] as Map<String, dynamic>;
    final semaine = (semaines[p.regime.name] ?? semaines['aucun']) as Map<String, dynamic>;
    final repas = <Repas>[];
    for (var jour = 0; jour < 7; jour++) {
      for (final type in TypeRepas.values) {
        final rotation = [for (final id in semaine[type.name] as List) _depot.recette(id as String)];
        final recette = _choisir(rotation, jour, p);
        repas.add(Repas(
          jour: lundi.add(Duration(days: jour)),
          type: type,
          portions: p.nbPersonnes,
          recette: recette,
        ));
      }
    }
    return repas;
  }

  /// Le plat prévu ce jour-là s'il respecte le régime et le temps maximal ;
  /// sinon le suivant de la semaine type qui les respecte.
  Recette _choisir(List<Recette> rotation, int jour, ProfilNutritionnel p) {
    bool convient(Recette r, {required bool avecTemps}) =>
        r.convientAuRegime(p.regime) && (!avecTemps || r.tempsPreparationMin <= p.tempsMaxMinutes);
    for (final avecTemps in [true, false]) {
      for (var k = 0; k < rotation.length; k++) {
        final r = rotation[(jour + k) % rotation.length];
        if (convient(r, avecTemps: avecTemps)) return r;
      }
    }
    return rotation[jour % rotation.length];
  }

  @override
  Future<List<Adaptation>> adapterRecette(Recette r, List<Equipement> manquants) async {
    final methodes = (_savoir['methodes'] as Map<String, dynamic>)[r.id] as Map<String, dynamic>? ?? const {};
    final adaptations = <Adaptation>[];
    for (final e in manquants) {
      final m = methodes[e.type.name] as Map<String, dynamic>?;
      if (m == null) continue; // pas de méthode : la recette ne sera pas proposée
      adaptations.add(Adaptation(
        type: TypeAdaptation.equipement,
        description: m['description'] as String,
        ordreEtape: m['ordreEtape'] as int?,
        instruction: m['instruction'] as String?,
        conseil: m['conseil'] as String?,
      ));
    }
    final local = (_savoir['ingredientsLocaux'] as Map<String, dynamic>)[r.id] as String?;
    if (local != null) {
      adaptations.add(Adaptation(type: TypeAdaptation.ingredientLocal, description: local));
    }
    return adaptations;
  }

  /// Recettes du même type de repas, les plus proches en calories d'abord.
  @override
  Future<List<Recette>> proposerRecettes(Repas repas, int n) async {
    final candidats = [
      for (final r in _depot.recettes)
        if (r != repas.recette && typesDe(r).contains(repas.type)) r,
    ];
    final ordre = {for (var i = 0; i < candidats.length; i++) candidats[i]: i};
    candidats.sort((a, b) {
      final ecart = (a.kcalParPortion - repas.kcal).abs().compareTo((b.kcalParPortion - repas.kcal).abs());
      return ecart != 0 ? ecart : ordre[a]!.compareTo(ordre[b]!);
    });
    return candidats.take(n).toList();
  }
}
