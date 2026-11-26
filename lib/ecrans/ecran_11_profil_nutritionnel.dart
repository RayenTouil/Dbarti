// Écran 11 — Profil nutritionnel (résultat du questionnaire, point de départ de la séquence 3).
// Chiffre principal mis en avant ; répartition en grammes et en pourcentage ; méthode de calcul
// indiquée ; résumé modifiable ; le planning n'est généré qu'à la demande (« Générer ma semaine »).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../modeles/enumerations.dart';
import '../modeles/profil_nutritionnel.dart';
import '../outils/format.dart';
import '../services/service_authentification.dart';
import '../services/service_planning.dart';
import '../services/service_profil.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'coquille_onglets.dart';
import 'ecran_questionnaire.dart';

class EcranProfilNutritionnel extends StatelessWidget {
  const EcranProfilNutritionnel({super.key, this.modification = false});

  /// Ouvert depuis le profil (écran 18) : flèche de retour.
  final bool modification;

  Future<void> _generer(BuildContext context) async {
    final auth = context.read<ServiceAuthentification>();
    final planning = context.read<ServicePlanning>();
    final navigateur = Navigator.of(context);
    try {
      await planning.genererSemaine(auth.utilisateurCourant!); // 2 : genererSemaine(utilisateur)
      allerAuxOnglets(navigateur, onglet: 0); // 24 : planning du lundi (écran 12)
    } catch (_) {
      // L'erreur est affichée par l'écran (bouton « Réessayer »).
    }
  }

  Future<void> _modifier(BuildContext context, int etape) async {
    context.read<ServiceProfil>().demarrer();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EcranQuestionnaire(etapeAModifier: etape)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServiceAuthentification>().utilisateurCourant?.profil;
    final planning = context.watch<ServicePlanning>();
    if (p == null) return const Scaffold();
    final exclus = [for (final a in p.allergies) a.libelle, for (final i in p.exclus) i.nom.toLowerCase()];
    final appareils = [for (final e in p.equipements) e.type.nomCourt];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre profil nutritionnel'),
        automaticallyImplyLeading: modification,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Espaces.marge, 4, Espaces.marge, 16),
              children: [
                Carte(padding: const EdgeInsets.all(18), child: _CarteKcal(profil: p)),
                const SizedBox(height: 14),
                Encadre(
                  ton: TonEncadre.info,
                  icone: LucideIcons.calculator,
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Calcul par la formule de '),
                    TextSpan(text: 'Mifflin-St Jeor', style: Textes.inter(13, FontWeight.w700)),
                    const TextSpan(text: ' : âge, taille, poids et activité. Le même profil donne toujours le même résultat.'),
                    if (p.objectif == Objectif.perteDePoids) const TextSpan(text: ' Objectif perte de poids : −400 kcal par jour.'),
                  ])),
                ),
                const SizedBox(height: 14),
                Carte(
                  child: Column(
                    children: [
                      LigneReglage(
                        icone: LucideIcons.ban,
                        titre: 'Exclus',
                        detail: exclus.isEmpty ? 'Aucun' : _majuscule(exclus.join(', ')),
                        fin: const Icon(LucideIcons.pencil, size: 16, color: Couleurs.doux),
                        onTap: () => _modifier(context, 3),
                      ),
                      LigneReglage(
                        icone: LucideIcons.cookingPot,
                        titre: 'Équipement',
                        detail: _majuscule(appareils.join(', ')),
                        fin: const Icon(LucideIcons.pencil, size: 16, color: Couleurs.doux),
                        onTap: () => _modifier(context, 6),
                      ),
                      LigneReglage(
                        icone: LucideIcons.wallet,
                        titre: 'Budget et enseigne',
                        detail: '${formaterEntier((p.budgetHebdoDT ?? 0).round())} DT par semaine · ${p.enseigne?.nom ?? ''}',
                        fin: const Icon(LucideIcons.pencil, size: 16, color: Couleurs.doux),
                        onTap: () => _modifier(context, 5),
                      ),
                      LigneReglage(
                        icone: LucideIcons.clock,
                        titre: 'Temps maximal',
                        detail: '${p.tempsMaxMinutes} minutes par repas',
                        fin: const Icon(LucideIcons.pencil, size: 16, color: Couleurs.doux),
                        onTap: () => _modifier(context, 4),
                        derniere: true,
                      ),
                    ],
                  ),
                ),
                if (planning.erreur != null) ...[
                  const SizedBox(height: 14),
                  Encadre(
                    key: const Key('erreur-generation'),
                    ton: TonEncadre.erreur,
                    icone: LucideIcons.wifiOff,
                    child: Text('${planning.erreur} '
                        '${modification && planning.planning != null ? 'Votre planning actuel reste consultable.' : ''}'),
                  ),
                ],
              ],
            ),
          ),
          PiedFixe(children: [
            BoutonPrincipal(
              key: const Key('bouton-generer'),
              icone: planning.erreur != null ? LucideIcons.refreshCw : LucideIcons.sparkles,
              libelle: planning.erreur != null ? 'Réessayer' : 'Générer ma semaine',
              chargement: planning.enCours,
              onPressed: () => _generer(context),
            ),
            Text('Dbarti ne remplace pas un avis médical.', textAlign: TextAlign.center, style: Textes.aide),
          ]),
        ],
      ),
    );
  }

  static String _majuscule(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _CarteKcal extends StatelessWidget {
  const _CarteKcal({required this.profil});
  final ProfilNutritionnel profil;

  @override
  Widget build(BuildContext context) {
    final (pP, pG, pL) = ProfilNutritionnel.repartitionMacros[profil.objectif]!;
    final macros = [
      ('Protéines', profil.proteinesG, pP, Couleurs.olive),
      ('Glucides', profil.glucidesG, pG, Couleurs.safran),
      ('Lipides', profil.lipidesG, pL, Couleurs.primaire),
    ];
    return Row(
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: CustomPaint(
            painter: _Donut([for (final m in macros) (m.$3 / 100, m.$4)]),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formaterEntier(profil.besoinKcal), style: Textes.poppins(24, FontWeight.w700, hauteur: 1)),
                  Text('kcal / jour', style: Textes.inter(11.5, FontWeight.w400, couleur: Couleurs.doux)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (final (nom, g, pct, couleur) in macros) ...[
                Row(
                  children: [
                    Text(nom, style: Textes.inter(12.5, FontWeight.w600)),
                    const Spacer(),
                    Text('$g g · $pct %', style: Textes.inter(12.5, FontWeight.w400)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: min(1, pct / 60),
                    minHeight: 7,
                    color: couleur,
                    backgroundColor: Couleurs.fond,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Donut extends CustomPainter {
  _Donut(this.parts);
  final List<(double, Color)> parts;

  @override
  void paint(Canvas canvas, Size size) {
    const epaisseur = 13.0;
    final rect = Rect.fromLTWH(epaisseur / 2, epaisseur / 2, size.width - epaisseur, size.height - epaisseur);
    var debut = -pi / 2;
    for (final (part, couleur) in parts) {
      final angle = 2 * pi * part;
      canvas.drawArc(
        rect,
        debut,
        angle,
        false,
        Paint()
          ..color = couleur
          ..style = PaintingStyle.stroke
          ..strokeWidth = epaisseur,
      );
      debut += angle;
    }
  }

  @override
  bool shouldRepaint(_Donut old) => old.parts != parts;
}
