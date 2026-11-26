import 'package:flutter/services.dart' show AssetBundle;

import 'donnees/base_de_donnees.dart';
import 'donnees/depot_donnees.dart';
import 'externes/agent_ia.dart';
import 'externes/agent_ia_claude.dart';
import 'externes/agent_ia_local.dart';
import 'externes/outil_collecte.dart';
import 'externes/service_livraison_enseigne.dart';
import 'modeles/catalogue.dart';
import 'services/service_authentification.dart';
import 'services/service_courses.dart';
import 'services/service_planning.dart';
import 'services/service_profil.dart';

/// Assemble l'application : données de démonstration, base locale, systèmes externes
/// et les 4 contrôleurs. Utilisé par main.dart et par les tests (base en mémoire).
class Dependances {
  Dependances._({
    required this.depot,
    required this.base,
    required this.agent,
    required this.auth,
    required this.profil,
    required this.planning,
    required this.courses,
  });

  final DepotDonnees depot;
  final BaseDeDonnees base;
  final AgentIA agent;
  final ServiceAuthentification auth;
  final ServiceProfil profil;
  final ServicePlanning planning;
  final ServiceCourses courses;

  static Future<Dependances> creer({
    required BaseDeDonnees base,
    AgentIA? agent,
    AssetBundle? bundle,
    bool collecter = true,
  }) async {
    final depot = await DepotDonnees.charger(bundle: bundle);

    // Catalogues mis à jour lors d'une collecte précédente.
    for (final e in depot.enseignes) {
      final j = await base.lire(BaseDeDonnees.catalogues, e.id);
      if (j != null) e.catalogue.restaurer(Catalogue.depuisJson(j, depot));
    }
    // Séquence 7 : mise à jour des catalogues, au plus une fois par jour.
    if (collecter) {
      await mettreAJourLesCatalogues(
        outil: OutilCollecteLocal(depot, bundle: bundle),
        enseignes: depot.enseignes,
        base: base,
      );
    }

    final auth = ServiceAuthentification(base, depot);
    final livraison = ServiceLivraisonEnseigneLocal(
      () => auth.utilisateurCourant?.profil?.enseigne?.siteWeb ?? depot.enseignes.first.siteWeb,
    );
    final courses = ServiceCourses(base, auth, livraison, depot);
    // Agent IA : local par défaut ; Claude seulement si une clé est passée avec --dart-define.
    final agentIA = agent ??
        (AgentIAClaude.cleCompilee.isNotEmpty
            ? AgentIAClaude(depot, cle: AgentIAClaude.cleCompilee)
            : AgentIALocal(depot));
    final planning = ServicePlanning(agentIA, auth, courses, depot);
    final profil = ServiceProfil(auth, depot);

    final u = await auth.restaurerSession();
    final courant = u?.planningCourant;
    if (courant != null) {
      await courses.restaurer(courant);
      planning.actualiser();
    }

    return Dependances._(
      depot: depot,
      base: base,
      agent: agentIA,
      auth: auth,
      profil: profil,
      planning: planning,
      courses: courses,
    );
  }
}
