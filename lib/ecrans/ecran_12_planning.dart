// Écran 12 — Planning de la semaine (écran d'accueil quotidien).
// Sélecteur de jour, bilan du jour par rapport à la cible, trois repas (photo, nom, temps,
// calories, badge si la méthode est adaptée), remplacement en un appui, coût du panier
// comparé au budget toujours visible. Si le panier dépasse le budget : écart et repas les plus chers.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../modeles/planning_semaine.dart';
import '../outils/format.dart';
import '../outils/horloge.dart';
import '../services/service_authentification.dart';
import '../services/service_planning.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'coquille_onglets.dart';
import 'ecran_13_remplacer_repas.dart';
import 'ecran_14_recette.dart';

class EcranPlanning extends StatefulWidget {
  const EcranPlanning({super.key});

  @override
  State<EcranPlanning> createState() => _EcranPlanningState();
}

class _EcranPlanningState extends State<EcranPlanning> {
  DateTime? _jour;
  String? _idPlanning;

  /// Après une génération : le lundi (séquence 3, message 24) ; sinon : aujourd'hui.
  DateTime _jourAffiche(PlanningSemaine p) {
    if (_idPlanning != p.id) {
      final genereAujourdhui = memeJour(p.dateGeneration, maintenant());
      final aujourdhui = jourSeul(maintenant());
      final dansLaSemaine = !aujourdhui.isBefore(p.dateDebut) && aujourdhui.difference(p.dateDebut).inDays < 7;
      _jour = genereAujourdhui || !dansLaSemaine ? p.dateDebut : aujourdhui;
      _idPlanning = p.id;
    }
    return _jour!;
  }

  Future<void> _generer() async {
    final auth = context.read<ServiceAuthentification>();
    try {
      await context.read<ServicePlanning>().genererSemaine(auth.utilisateurCourant!);
    } catch (_) {
      // message et « Réessayer » affichés ci-dessous ; l'ancien planning reste visible
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<ServiceAuthentification>().utilisateurCourant;
    final service = context.watch<ServicePlanning>();
    final planning = service.planning;
    final prenom = (u?.nomComplet ?? '').split(' ').first;
    if (u == null) return const SizedBox();

    if (planning == null) {
      return SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Espaces.marge, 16, Espaces.marge, 16),
                children: [
                  EnteteEcran(titre: 'Bonjour $prenom', sousTitre: 'Votre semaine n’est pas encore préparée.'),
                  if (service.erreur != null) ...[const SizedBox(height: 14), _erreur(service.erreur!)],
                ],
              ),
            ),
            PiedFixe(children: [
              BoutonPrincipal(
                icone: service.erreur != null ? LucideIcons.refreshCw : LucideIcons.sparkles,
                libelle: service.erreur != null ? 'Réessayer' : 'Générer ma semaine',
                chargement: service.enCours,
                onPressed: _generer,
              ),
            ]),
          ],
        ),
      );
    }

    final jour = _jourAffiche(planning);
    final repas = planning.repasDuJour(jour);
    final kcal = planning.kcalDuJour(jour);
    final cible = planning.cibleKcalJour;
    final cout = planning.coutEstime();
    final budget = u.profil?.budgetHebdoDT ?? 0;
    final semaineFinie = jourSeul(maintenant()).difference(planning.dateDebut).inDays >= 7;
    final depassement = service.depassement;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Espaces.marge, 8, Espaces.marge, 20),
        children: [
          Text(formaterSemaine(planning.dateDebut), style: Textes.etiquette),
          Text('Bonjour $prenom', style: Textes.titreEcran),
          const SizedBox(height: 12),
          if (service.erreur != null) ...[_erreur(service.erreur!), const SizedBox(height: 12)],
          if (semaineFinie) ...[
            Encadre(
              ton: TonEncadre.safran,
              icone: LucideIcons.calendarClock,
              child: Row(
                children: [
                  const Expanded(child: Text('Cette semaine est terminée.')),
                  TextButton(onPressed: service.enCours ? null : _generer, child: const Text('Préparer la suivante')),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _SelecteurJours(
            jours: planning.jours,
            selectionne: jour,
            onChanged: (j) => setState(() => _jour = j),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: '$kcal kilocalories sur $cible',
            child: Row(
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: formaterEntier(kcal), style: Textes.inter(12.5, FontWeight.w700)),
                    TextSpan(text: ' / ${formaterEntier(cible)} kcal'),
                  ]),
                  style: Textes.inter(12.5, FontWeight.w400, couleur: Couleurs.doux),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: cible == 0 ? 0 : (kcal / cible).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      color: Couleurs.olive,
                      backgroundColor: Couleurs.trait,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${cible == 0 ? 0 : (kcal * 100 / cible).round()} %',
                    style: Textes.inter(12.5, FontWeight.w400, couleur: Couleurs.doux)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final r in repas) ...[
            CarteRepas(
              key: Key('repas-${r.type.name}'),
              repas: r,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EcranRecette(repas: r))),
              onRemplacer: () => afficherRemplacement(context, r),
            ),
            const SizedBox(height: 12),
          ],
          _CartePanier(
            enseigne: u.profil?.enseigne?.nom ?? '',
            cout: cout,
            budget: budget,
            onTap: () => context.read<NavigationOnglets>().aller(1),
          ),
          if (depassement != null) ...[
            const SizedBox(height: 12),
            Encadre(
              key: const Key('depassement'),
              ton: TonEncadre.safran,
              icone: LucideIcons.triangleAlert,
              child: Text(
                'Le panier dépasse votre budget de ${formaterDT(depassement.ecart)}. '
                'Repas les plus chers : ${depassement.plusChers.map((r) => r.recette.titre).join(', ')}. '
                'Remplacez-en un pour faire baisser le total.',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _erreur(String message) => Encadre(
        key: const Key('erreur-planning'),
        ton: TonEncadre.erreur,
        icone: LucideIcons.wifiOff,
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: _generer, child: const Text('Réessayer')),
          ],
        ),
      );
}

class _SelecteurJours extends StatelessWidget {
  const _SelecteurJours({required this.jours, required this.selectionne, required this.onChanged});
  final List<DateTime> jours;
  final DateTime selectionne;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final j in jours)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Semantics(
                  selected: memeJour(j, selectionne),
                  button: true,
                  label: formaterJour(j),
                  child: Material(
                    color: memeJour(j, selectionne) ? Couleurs.encre : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: Key('jour-${j.weekday}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onChanged(j),
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Text(joursCourts[j.weekday - 1],
                                  style: Textes.inter(11.5, FontWeight.w500,
                                      couleur: memeJour(j, selectionne) ? Couleurs.douxSurSombre : Couleurs.doux)),
                              Text('${j.day}',
                                  style: Textes.poppins(16, FontWeight.w600,
                                      couleur: memeJour(j, selectionne) ? Colors.white : Couleurs.encre)),
                              const SizedBox(height: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: memeJour(j, selectionne) ? Couleurs.safran : Couleurs.olive,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}

class _CartePanier extends StatelessWidget {
  const _CartePanier({required this.enseigne, required this.cout, required this.budget, required this.onTap});
  final String enseigne;
  final double cout;
  final double budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        key: const Key('carte-panier'),
        color: Couleurs.sombre,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Couleurs.primaire, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.shoppingBasket, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panier de la semaine · $enseigne',
                          style: Textes.inter(12, FontWeight.w400, couleur: Couleurs.douxSurSombre)),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: formaterDT(cout)),
                          TextSpan(
                            text: ' sur ${formaterEntier(budget.round())} DT',
                            style: Textes.inter(12, FontWeight.w500, couleur: Couleurs.douxSurSombre),
                          ),
                        ]),
                        style: Textes.poppins(17, FontWeight.w700, couleur: cout > budget ? Couleurs.safran : Colors.white),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      );
}
