import 'dart:convert';

import 'package:http/http.dart' as http;

import '../donnees/depot_donnees.dart';
import '../modeles/enumerations.dart';
import '../modeles/profil_nutritionnel.dart';
import '../modeles/recette.dart';
import '../modeles/repas.dart';
import '../outils/horloge.dart';
import 'agent_ia.dart';
import 'agent_ia_local.dart';

/// Agent IA facultatif, branché sur l'API Claude (Anthropic).
///
/// Il n'est utilisé que si une clé est passée à la compilation :
///   flutter run --dart-define=DBARTI_CLE_IA=sk-ant-...
/// Attention : une clé compilée dans un APK peut en être extraite. L'APK publié
/// et la CI sont construits sans clé ; cette option sert aux essais en local.
///
/// Le modèle choisit seulement parmi les recettes de la base locale (par identifiant) :
/// les allergies, les exclusions et l'équipement restent vérifiés par ServicePlanning.
/// Les adaptations à l'équipement viennent de la base de connaissances locale.
class AgentIAClaude extends AgentIALocal {
  AgentIAClaude(this._depotClaude, {required String cle, http.Client? client})
      : _cle = cle,
        _client = client ?? http.Client(),
        super(_depotClaude);

  static const cleCompilee = String.fromEnvironment('DBARTI_CLE_IA');
  static const _modele = 'claude-opus-5-5';
  static const _url = 'https://api.anthropic.com/v1/messages';

  final DepotDonnees _depotClaude;
  final String _cle;
  final http.Client _client;

  /// Résumé des recettes envoyé au modèle (identifiant, titre, repas possibles, kcal…).
  List<Map<String, dynamic>> _catalogueRecettes() => [
        for (final r in _depotClaude.recettes)
          {
            'id': r.id,
            'titre': r.titre,
            'repas': [for (final t in typesDe(r)) t.name],
            'kcal': r.kcalParPortion,
            'minutes': r.tempsPreparationMin,
            'cuisine': r.cuisine,
            'regimes': [for (final x in r.regimesCompatibles) x.name],
          },
      ];

  @override
  Future<List<Repas>> composerMenus(ProfilNutritionnel p) async {
    final ids = _depotClaude.recettes.map((r) => r.id).toList();
    final schema = {
      'type': 'object',
      'properties': {
        'semaine': {
          'type': 'array',
          'description': '7 jours, du lundi au dimanche',
          'items': {
            'type': 'object',
            'properties': {
              'petitDejeuner': {'type': 'string', 'enum': ids},
              'dejeuner': {'type': 'string', 'enum': ids},
              'diner': {'type': 'string', 'enum': ids},
            },
            'required': ['petitDejeuner', 'dejeuner', 'diner'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['semaine'],
      'additionalProperties': false,
    };
    final consigne = '''
Compose les repas d'une semaine (7 jours × petit-déjeuner, déjeuner, dîner) pour ce profil :
- cible : ${p.besoinKcal} kcal par jour, objectif ${p.objectif.libelle}
- régime : ${p.regime.libelle}
- cuisines préférées : ${p.cuisinesPreferees.isEmpty ? 'aucune préférence' : p.cuisinesPreferees.join(', ')}
- temps maximal : ${p.tempsMaxMinutes} minutes par repas
- budget : ${p.budgetHebdoDT} DT par semaine
Choisis uniquement des recettes dont la liste « repas » contient le repas visé, et dont « regimes »
contient le régime (sauf régime Aucun). Varie les plats et reste proche de la cible.
Recettes disponibles (JSON) :
${jsonEncode(_catalogueRecettes())}''';
    final reponse = await _demander(consigne, schema);
    final semaine = reponse['semaine'] as List;
    if (semaine.length != 7) throw ErreurAgentIA('L’agent IA n’a pas renvoyé 7 jours.');
    final lundi = lundiDe(maintenant());
    return [
      for (var j = 0; j < 7; j++)
        for (final type in TypeRepas.values)
          Repas(
            jour: lundi.add(Duration(days: j)),
            type: type,
            portions: p.nbPersonnes,
            recette: _depotClaude.recette((semaine[j] as Map<String, dynamic>)[type.name] as String),
          ),
    ];
  }

  @override
  Future<List<Recette>> proposerRecettes(Repas repas, int n) async {
    final ids = _depotClaude.recettes.map((r) => r.id).toList();
    final schema = {
      'type': 'object',
      'properties': {
        'recettes': {'type': 'array', 'items': {'type': 'string', 'enum': ids}},
      },
      'required': ['recettes'],
      'additionalProperties': false,
    };
    final consigne = '''
Propose $n recettes différentes pour remplacer « ${repas.recette.titre} » (${repas.kcal} kcal)
au ${repas.type.libelle.toLowerCase()}. Choisis des recettes dont la liste « repas » contient
« ${repas.type.name} », proches en calories, sans reprendre « ${repas.recette.id} ».
Recettes disponibles (JSON) :
${jsonEncode(_catalogueRecettes())}''';
    final reponse = await _demander(consigne, schema);
    return [
      for (final id in (reponse['recettes'] as List).cast<String>().toSet())
        if (id != repas.recette.id) _depotClaude.recette(id),
    ].take(n).toList();
  }

  /// Un appel à l'API Messages, avec une sortie JSON imposée par un schéma.
  Future<Map<String, dynamic>> _demander(String consigne, Map<String, dynamic> schema) async {
    final http.Response r;
    try {
      r = await _client
          .post(
            Uri.parse(_url),
            headers: {
              'content-type': 'application/json',
              'x-api-key': _cle,
              'anthropic-version': '2026-10-21',
              'anthropic-beta': 'server-side-fallback-2026-07-01',
            },
            body: jsonEncode({
              'model': _modele,
              'max_tokens': 16000,
              'fallbacks': 'default',
              'output_config': {
                'effort': 'medium',
                'format': {'type': 'json_schema', 'schema': schema},
              },
              'system': 'Tu es l’agent de planification de repas de l’application Dbarti. '
                  'Tu réponds uniquement avec le JSON demandé.',
              'messages': [
                {'role': 'user', 'content': consigne},
              ],
            }),
          )
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      throw ErreurAgentIA('Pas de réponse de l’agent IA. Vérifiez votre connexion.');
    }
    if (r.statusCode != 200) {
      throw ErreurAgentIA('L’agent IA a répondu avec une erreur (${r.statusCode}).');
    }
    final corps = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (corps['stop_reason'] == 'refusal' || corps['stop_reason'] == 'max_tokens') {
      throw ErreurAgentIA('L’agent IA n’a pas pu terminer sa proposition.');
    }
    final texte = (corps['content'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((b) => b['type'] == 'text', orElse: () => const {'text': '{}'})['text'] as String;
    try {
      return jsonDecode(texte) as Map<String, dynamic>;
    } catch (_) {
      throw ErreurAgentIA('Réponse de l’agent IA illisible.');
    }
  }
}
