import '../modeles/liste_courses.dart';

/// «système externe» ServiceLivraisonEnseigne — le site de l'enseigne reçoit l'utilisateur
/// redirigé depuis Dbarti. Le panier, le paiement et la livraison se font sur ce site.
abstract class ServiceLivraisonEnseigne {
  /// Renvoie le lien à ouvrir pour remplir le panier (séquence 6, messages 10 et 11).
  Future<String> ouvrirPanier(ListeCourses l);
}

/// Implémentation sans clé ni API : le lien est le site web de l'enseigne du profil.
/// Aucune commande n'est passée par Dbarti ; la liste est copiée pour être collée sur le site.
class ServiceLivraisonEnseigneLocal implements ServiceLivraisonEnseigne {
  ServiceLivraisonEnseigneLocal(this._siteWeb);

  /// Site de l'enseigne choisie par l'utilisateur (ex. https://www.carrefour.tn).
  final String Function() _siteWeb;

  @override
  Future<String> ouvrirPanier(ListeCourses l) async => _siteWeb();
}
