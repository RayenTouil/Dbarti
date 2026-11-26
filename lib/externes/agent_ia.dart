import '../modeles/adaptation.dart';
import '../modeles/equipement.dart';
import '../modeles/profil_nutritionnel.dart';
import '../modeles/recette.dart';
import '../modeles/repas.dart';

/// «système externe» AgentIA — compose les menus, adapte les recettes, propose des remplaçants.
///
/// Principe de Dbarti : « l'IA propose, le code vérifie ». L'agent ne filtre jamais les
/// allergies ni les exclusions : ServicePlanning le fait après lui, dans le code.
abstract class AgentIA {
  /// 21 repas (7 jours × 3) à partir du profil (séquence 3, message 5).
  Future<List<Repas>> composerMenus(ProfilNutritionnel p);

  /// Méthodes de remplacement pour les appareils manquants, et ingrédients locaux.
  /// Un appareil manquant sans méthode n'a pas d'adaptation : la recette sera retirée.
  Future<List<Adaptation>> adapterRecette(Recette r, List<Equipement> manquants);

  /// [n] recettes pour remplacer le repas (même type de repas, autre recette).
  Future<List<Recette>> proposerRecettes(Repas repas, int n);
}

/// Erreur de l'agent (pas de réponse, connexion perdue…) : l'écran propose « Réessayer ».
class ErreurAgentIA implements Exception {
  ErreurAgentIA(this.message);
  final String message;

  @override
  String toString() => message;
}
