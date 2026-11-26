import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

/// :BaseDeDonnees des diagrammes de séquence — tout est stocké sur le téléphone.
/// Chaque objet est enregistré en JSON sous une clé, dans une « boîte » par type.
abstract class BaseDeDonnees {
  Future<Map<String, dynamic>?> lire(String boite, String cle);
  Future<List<Map<String, dynamic>>> lireTout(String boite);
  Future<void> enregistrer(String boite, String cle, Map<String, dynamic> valeur);
  Future<void> supprimer(String boite, String cle);

  /// Réglages simples (session, date de la dernière collecte).
  Future<String?> reglage(String cle);
  Future<void> definirReglage(String cle, String? valeur);

  static const utilisateurs = 'utilisateurs';
  static const plannings = 'plannings';
  static const listes = 'listes';
  static const achats = 'achats';
  static const catalogues = 'catalogues';
}

/// Implémentation de l'application : Hive (fichiers locaux, sans serveur).
class BaseDeDonneesHive implements BaseDeDonnees {
  BaseDeDonneesHive._(this._boites, this._reglages);

  final Map<String, Box<String>> _boites;
  final Box<String> _reglages;

  static Future<BaseDeDonneesHive> ouvrir() async {
    final dossier = await getApplicationSupportDirectory();
    Hive.init('${dossier.path}/dbarti');
    final boites = <String, Box<String>>{};
    for (final nom in [
      BaseDeDonnees.utilisateurs,
      BaseDeDonnees.plannings,
      BaseDeDonnees.listes,
      BaseDeDonnees.achats,
      BaseDeDonnees.catalogues,
    ]) {
      boites[nom] = await Hive.openBox<String>(nom);
    }
    return BaseDeDonneesHive._(boites, await Hive.openBox<String>('reglages'));
  }

  @override
  Future<Map<String, dynamic>?> lire(String boite, String cle) async {
    final v = _boites[boite]!.get(cle);
    return v == null ? null : jsonDecode(v) as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> lireTout(String boite) async =>
      [for (final v in _boites[boite]!.values) jsonDecode(v) as Map<String, dynamic>];

  @override
  Future<void> enregistrer(String boite, String cle, Map<String, dynamic> valeur) =>
      _boites[boite]!.put(cle, jsonEncode(valeur));

  @override
  Future<void> supprimer(String boite, String cle) => _boites[boite]!.delete(cle);

  @override
  Future<String?> reglage(String cle) async => _reglages.get(cle);

  @override
  Future<void> definirReglage(String cle, String? valeur) =>
      valeur == null ? _reglages.delete(cle) : _reglages.put(cle, valeur);
}

/// Implémentation en mémoire, pour les tests.
class BaseDeDonneesMemoire implements BaseDeDonnees {
  final Map<String, Map<String, String>> _donnees = {};
  final Map<String, String> _reglages = {};

  Map<String, String> _boite(String nom) => _donnees.putIfAbsent(nom, () => {});

  /// Contenu brut d'une boîte (pour vérifier dans les tests qu'aucun mot de passe n'est en clair).
  Map<String, String> brut(String boite) => Map.unmodifiable(_boite(boite));

  @override
  Future<Map<String, dynamic>?> lire(String boite, String cle) async {
    final v = _boite(boite)[cle];
    return v == null ? null : jsonDecode(v) as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> lireTout(String boite) async =>
      [for (final v in _boite(boite).values) jsonDecode(v) as Map<String, dynamic>];

  @override
  Future<void> enregistrer(String boite, String cle, Map<String, dynamic> valeur) async =>
      _boite(boite)[cle] = jsonEncode(valeur);

  @override
  Future<void> supprimer(String boite, String cle) async => _boite(boite).remove(cle);

  @override
  Future<String?> reglage(String cle) async => _reglages[cle];

  @override
  Future<void> definirReglage(String cle, String? valeur) async =>
      valeur == null ? _reglages.remove(cle) : _reglages[cle] = valeur;
}
