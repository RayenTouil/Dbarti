import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../donnees/base_de_donnees.dart';
import '../modeles/enseigne.dart';
import '../modeles/produit.dart';
import '../modeles/referentiel.dart';
import '../outils/horloge.dart';

/// «système externe» OutilCollecte — lit le catalogue en ligne de chaque enseigne.
abstract class OutilCollecte {
  /// Produits et prix publiés par l'enseigne. Lève une erreur si le site est inaccessible.
  Future<List<Produit>> collecterCatalogue(Enseigne e);
}

/// Simulation sans scraping : les « pages produits » d'une enseigne sont un fichier JSON
/// local, `assets/donnees/collecte/<domaine>.json`. S'il n'existe pas, le site est
/// considéré comme inaccessible (cas de Monoprix dans les données de démonstration).
class OutilCollecteLocal implements OutilCollecte {
  OutilCollecteLocal(this._referentiel, {AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final Referentiel _referentiel;
  final AssetBundle _bundle;

  @override
  Future<List<Produit>> collecterCatalogue(Enseigne e) async {
    final adresse = 'assets/donnees/collecte/${e.domaine}.json'; // 1-2 : lire siteWeb → adresse
    final String texte;
    try {
      texte = await _bundle.loadString(adresse); // 4 : lire les pages produits
    } catch (_) {
      throw StateError('Site de ${e.nom} inaccessible'); // 9 : erreur
    }
    final json = jsonDecode(texte) as Map<String, dynamic>;
    return [
      for (final p in json['produits'] as List) Produit.depuisJson(p as Map<String, dynamic>, _referentiel),
    ];
  }
}

/// Séquence 7 — mise à jour des catalogues, sans écran. Dans l'application, elle est lancée
/// au démarrage, au plus une fois par jour (simule le passage « chaque nuit »).
/// Les catalogues mis à jour sont enregistrés ; un catalogue non mis à jour est gardé tel quel.
Future<Map<String, bool>> mettreAJourLesCatalogues({
  required OutilCollecte outil,
  required List<Enseigne> enseignes,
  required BaseDeDonnees base,
  bool forcer = false,
}) async {
  const cle = 'derniereCollecte';
  final aujourdhui = jourSeul(maintenant()).toIso8601String();
  if (!forcer && await base.reglage(cle) == aujourdhui) return const {};
  final resultats = <String, bool>{};
  for (final e in enseignes) {
    try {
      final produits = await outil.collecterCatalogue(e); // 3 : collecterCatalogue(enseigne)
      e.catalogue.mettreAJour(produits); // 6-7 : mettreAJour, produits associés aux ingrédients
      await base.enregistrer(BaseDeDonnees.catalogues, e.id, e.catalogue.versJson()); // 8 : enregistrer
      resultats[e.id] = true;
    } catch (_) {
      resultats[e.id] = false; // l'ancien catalogue est conservé ; après 7 jours : prix indicatifs
    }
  }
  await base.definirReglage(cle, aujourdhui);
  return resultats;
}
