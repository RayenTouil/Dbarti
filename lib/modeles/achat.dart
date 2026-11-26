import '../outils/format.dart';
import '../outils/horloge.dart';
import '../outils/securite.dart';
import 'enseigne.dart';
import 'enumerations.dart';
import 'liste_courses.dart';

/// Achat — garde le mode choisi (MAGASIN ou LIVRAISON) et le montant du panier.
/// Associations : ListeCourses 1 « donne lieu à » 0..* Achat ; Achat « chez » → Enseigne [1].
class Achat {
  Achat({
    required ModeAchat mode,
    required double montantDT,
    required Enseigne enseigne,
    required ListeCourses liste,
    String? id,
    DateTime? date,
  })  : _id = id ?? nouvelIdentifiant(),
        _mode = mode,
        _date = date ?? maintenant(),
        _montantDT = montantDT,
        _enseigne = enseigne,
        _liste = liste;

  final String _id;
  final ModeAchat _mode;
  final DateTime _date;
  final double _montantDT;
  final Enseigne _enseigne;
  final ListeCourses _liste;

  String get id => _id;
  ModeAchat get mode => _mode;
  DateTime get date => _date;
  double get montantDT => _montantDT;
  Enseigne get enseigne => _enseigne;
  ListeCourses get liste => _liste;

  /// MAGASIN : lien d'itinéraire vers le magasin de l'enseigne le plus proche
  /// (recherche dans l'application de cartes, sans clé).
  String ouvrirEnseigne() =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_enseigne.nom)}';

  /// LIVRAISON : la liste en texte, à coller sur le site de l'enseigne.
  /// Les articles « déjà à la maison » n'y figurent pas.
  String copierListe() {
    final b = StringBuffer()
      ..writeln('Liste de courses Dbarti · ${_enseigne.nom}')
      ..writeln('Total : ${formaterDT(_montantDT)}');
    final ailleurs = <String>[];
    _liste.articlesParRayon().forEach((rayon, articles) {
      final aAcheter = articles.where((a) => !a.dejaALaMaison).toList();
      final chez = aAcheter.where((a) => !a.aAcheterAilleurs()).toList();
      if (chez.isNotEmpty) {
        b
          ..writeln()
          ..writeln(rayon);
        for (final a in chez) {
          final p = a.produit!;
          final n = a.nbConditionnements;
          b.writeln('- ${p.libelle} · ${n > 1 ? '$n × ' : ''}${p.conditionnement}');
        }
      }
      for (final a in aAcheter.where((a) => a.aAcheterAilleurs())) {
        ailleurs.add('- ${a.ingredient.nom} · ${formaterQuantite(a.quantite, a.unite)}');
      }
    });
    if (ailleurs.isNotEmpty) {
      b
        ..writeln()
        ..writeln('À acheter ailleurs')
        ..writeAll(ailleurs, '\n');
    }
    return b.toString().trim();
  }

  Map<String, dynamic> versJson() => {
        'id': _id,
        'mode': _mode.name,
        'date': _date.toIso8601String(),
        'montantDT': _montantDT,
        'enseigne': _enseigne.id,
        'liste': _liste.id,
      };
}
