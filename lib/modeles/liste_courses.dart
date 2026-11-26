import 'dart:collection';

import '../outils/horloge.dart';
import '../outils/securite.dart';
import 'article_course.dart';
import 'catalogue.dart';
import 'ingredient.dart';
import 'planning_semaine.dart';
import 'referentiel.dart';

/// ListeCourses — la liste chiffrée créée depuis le planning.
/// Composition « regroupe » 1 ◆— 1..* ArticleCourse.
///
/// Écart documenté : la liste garde une référence privée vers le catalogue de
/// l'enseigne du profil, pour pouvoir chiffrer les articles dans generer().
class ListeCourses {
  ListeCourses({required Catalogue catalogue, String? id, DateTime? dateCreation})
      : _catalogue = catalogue,
        _id = id ?? nouvelIdentifiant(),
        _dateCreation = dateCreation ?? maintenant();

  /// Ordre des rayons, celui d'un parcours en magasin (écran 16).
  static const ordreRayons = ['Fruits et légumes', 'Épicerie', 'Crèmerie, viande', 'Boulangerie', 'Surgelés'];

  final String _id;
  DateTime _dateCreation;
  double _totalDT = 0;
  final List<ArticleCourse> _articles = [];
  final Catalogue _catalogue;

  String get id => _id;
  DateTime get dateCreation => _dateCreation;
  double get totalDT => _totalDT;
  List<ArticleCourse> get articles => List.unmodifiable(_articles);
  Catalogue get catalogue => _catalogue;

  /// Construit les articles à partir des 21 repas (séquence 5, messages 3 à 13) :
  /// les quantités d'un même ingrédient sont additionnées, puis chaque ingrédient est
  /// associé au produit du catalogue (ou marqué « à acheter ailleurs »).
  /// Les articles déjà cochés « déjà à la maison » le restent.
  void generer(PlanningSemaine planning) {
    final dejaALaMaison = {for (final a in _articles) if (a.dejaALaMaison) a.ingredient.id};

    // Additionner les quantités par ingrédient (message 5).
    final quantites = <Ingredient, double>{};
    final unites = <Ingredient, String>{};
    final recettes = <Ingredient, int>{};
    for (final repas in planning.repas) {
      final facteur = repas.portions / repas.recette.portions;
      for (final ligne in repas.recette.lignes) {
        final ing = ligne.ingredient;
        quantites[ing] = (quantites[ing] ?? 0) + ligne.quantite * facteur;
        unites[ing] = ligne.unite;
        recettes[ing] = (recettes[ing] ?? 0) + 1;
      }
    }

    // Un produit par ingrédient, sinon « à acheter ailleurs » (messages 9 à 13).
    _articles.clear();
    for (final entree in quantites.entries) {
      final ingredient = entree.key;
      final besoin = entree.value;
      final produit = _catalogue.rechercherProduit(ingredient);
      var prix = 0.0;
      if (produit != null) {
        final contenu = produit.contenu;
        assert(contenu.unite == unites[ingredient],
            'Unité incohérente pour ${ingredient.nom} : ${contenu.unite} / ${unites[ingredient]}');
        final nb = (besoin / contenu.quantite - 1e-9).ceil().clamp(1, 1000);
        prix = _arrondi(nb * produit.prixDT);
      }
      _articles.add(ArticleCourse(
        quantite: besoin,
        unite: unites[ingredient]!,
        prixDT: prix,
        ingredient: ingredient,
        produit: produit,
        dejaALaMaison: dejaALaMaison.contains(ingredient.id),
        nbRecettes: recettes[ingredient]!,
      ));
    }
    _dateCreation = maintenant();
    calculerTotal();
  }

  /// Somme des articles à acheter, sans ceux « déjà à la maison » ni ceux « à acheter ailleurs ».
  double calculerTotal() {
    _totalDT = _arrondi(_articles.fold(0.0, (s, a) => s + a.prixCompte));
    return _totalDT;
  }

  /// Ce qu'il reste du budget (négatif si la liste le dépasse).
  double resteBudget(double budgetDT) => _arrondi(budgetDT - _totalDT);

  /// Articles groupés par rayon, dans l'ordre du parcours en magasin.
  Map<String, List<ArticleCourse>> articlesParRayon() {
    final groupes = <String, List<ArticleCourse>>{};
    for (final a in _articles) {
      groupes.putIfAbsent(a.produit?.rayon ?? a.ingredient.rayon, () => []).add(a);
    }
    int rang(String rayon) {
      final i = ordreRayons.indexOf(rayon);
      return i < 0 ? ordreRayons.length : i;
    }

    final cles = groupes.keys.toList()..sort((a, b) => rang(a).compareTo(rang(b)));
    return LinkedHashMap.fromEntries([for (final c in cles) MapEntry(c, groupes[c]!)]);
  }

  /// Nombre d'articles comptés dans le total.
  int get nbArticlesComptes => _articles.where((a) => a.prixCompte > 0).length;

  static double _arrondi(double x) => (x * 1000).round() / 1000;

  factory ListeCourses.depuisJson(Map<String, dynamic> j, Referentiel r, Catalogue catalogue) {
    final liste = ListeCourses(
      catalogue: catalogue,
      id: j['id'] as String,
      dateCreation: DateTime.parse(j['dateCreation'] as String),
    );
    for (final a in j['articles'] as List) {
      liste._articles.add(ArticleCourse.depuisJson(a as Map<String, dynamic>, r, (ref) {
        for (final p in catalogue.produits) {
          if (p.reference == ref) return p;
        }
        return null;
      }));
    }
    liste.calculerTotal();
    return liste;
  }

  Map<String, dynamic> versJson() => {
        'id': _id,
        'dateCreation': _dateCreation.toIso8601String(),
        'totalDT': _totalDT,
        'articles': [for (final a in _articles) a.versJson()],
      };
}
