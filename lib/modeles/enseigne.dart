import 'catalogue.dart';

/// Enseigne — une chaîne de magasins (Carrefour, Monoprix…).
/// Composition « publie » 1 ◆— 1 Catalogue.
class Enseigne {
  Enseigne({
    required String id,
    required String nom,
    required String siteWeb,
    required bool livraisonDisponible,
    required Catalogue catalogue,
    String description = '',
  })  : _id = id,
        _nom = nom,
        _siteWeb = siteWeb,
        _livraisonDisponible = livraisonDisponible,
        _catalogue = catalogue,
        _description = description;

  final String _id;
  final String _nom;
  final String _siteWeb;
  final bool _livraisonDisponible;
  final Catalogue _catalogue;
  final String _description; // texte de l'écran 08 (« Magasins et livraison carrefour.tn »)

  String get id => _id;
  String get nom => _nom;
  String get siteWeb => _siteWeb;
  bool get livraisonDisponible => _livraisonDisponible;
  Catalogue get catalogue => _catalogue;
  String get description => _description;

  /// « https://www.carrefour.tn » → « carrefour.tn »
  String get domaine => Uri.parse(_siteWeb).host.replaceFirst('www.', '');

  @override
  bool operator ==(Object other) => other is Enseigne && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}
