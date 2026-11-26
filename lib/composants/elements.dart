import 'dart:ui' show PointMode;

import 'package:flutter/material.dart' hide Adaptation;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../modeles/adaptation.dart';
import '../modeles/enumerations.dart';
import '../modeles/recette.dart';
import '../modeles/repas.dart';
import '../theme/couleurs.dart';
import '../theme/typographie.dart';

/// Carte blanche de la charte (bordure fine, coins de 16 dp, ombre légère).
class Carte extends StatelessWidget {
  const Carte({super.key, required this.child, this.padding = EdgeInsets.zero, this.onTap, this.bordure});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? bordure;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x142A201C), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: Material(
          color: Couleurs.carte,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: bordure ?? Couleurs.trait, width: bordure == null ? 1 : 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: onTap == null ? Padding(padding: padding, child: child) : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

enum TonEncadre { olive, safran, info, erreur }

/// Encadré d'information : olive = validé ou adapté, safran = attention, info = neutre.
class Encadre extends StatelessWidget {
  const Encadre({super.key, required this.ton, required this.icone, required this.child, this.surSombre = false});

  final TonEncadre ton;
  final IconData icone;
  final Widget child;
  final bool surSombre;

  @override
  Widget build(BuildContext context) {
    final (fond, texte, bord) = switch (ton) {
      TonEncadre.olive when surSombre => (Couleurs.olive.withValues(alpha: 0.22), const Color(0xFFD4ECC0), null),
      TonEncadre.olive => (Couleurs.oliveClair, Couleurs.oliveTexte, null),
      TonEncadre.safran => (Couleurs.safranClair, Couleurs.safranTexte, null),
      TonEncadre.erreur => (Couleurs.erreurClair, Couleurs.erreur, null),
      TonEncadre.info => (Couleurs.carte, Couleurs.doux, Couleurs.trait),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(14),
        border: bord == null ? null : Border.all(color: bord),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: texte),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle(
              style: Textes.inter(13, FontWeight.w400, couleur: texte, hauteur: 1.45),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Texte avec une partie en gras : « **Sans mixeur** : les tomates… ».
Text texteAvecGras(String gras, String reste, {TextStyle? style}) => Text.rich(
      TextSpan(children: [
        TextSpan(text: gras, style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: reste),
      ]),
      style: style,
    );

enum TonBadge { olive, safran, primaire, neutre }

class Badge2 extends StatelessWidget {
  const Badge2({super.key, required this.libelle, required this.ton, this.icone});
  final String libelle;
  final TonBadge ton;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final (fond, texte) = switch (ton) {
      TonBadge.olive => (Couleurs.oliveClair, Couleurs.oliveTexte),
      TonBadge.safran => (Couleurs.safranClair, Couleurs.safranTexte),
      TonBadge.primaire => (Couleurs.primaireClair, Couleurs.primaireFonce),
      TonBadge.neutre => (Couleurs.fond, Couleurs.doux),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(11)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[Icon(icone, size: 12, color: texte), const SizedBox(width: 4)],
          Text(libelle, style: Textes.inter(11.5, FontWeight.w600, couleur: texte)),
        ],
      ),
    );
  }
}

/// Badges d'un repas adapté : « ✓ Sans mixeur » (olive) et « Ingrédient local » (safran).
List<Widget> badgesAdaptations(List<Adaptation> adaptations) => [
      for (final a in adaptations)
        a.type == TypeAdaptation.ingredientLocal
            ? const Badge2(libelle: 'Ingrédient local', ton: TonBadge.safran)
            : Badge2(libelle: titreAdaptation(a), ton: TonBadge.olive, icone: LucideIcons.check),
    ];

/// « Sans mixeur : les tomates… » → « Sans mixeur ».
String titreAdaptation(Adaptation a) {
  if (a.type == TypeAdaptation.ingredientLocal) return 'Ingrédient local';
  final i = a.description.indexOf(' :');
  return i < 0 ? a.description : a.description.substring(0, i);
}

/// Barre d'avancement du questionnaire : « Étape i sur 6 · thème » (critère « guidage »).
class BarreEtapes extends StatelessWidget {
  const BarreEtapes({super.key, required this.etape, required this.total, required this.theme, this.surSombre = false});
  final int etape;
  final int total;
  final String theme;
  final bool surSombre;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Étape $etape sur $total, $theme',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 1; i <= total; i++) ...[
                  if (i > 1) const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i <= etape
                            ? (surSombre ? Couleurs.safran : Couleurs.primaire)
                            : (surSombre ? Colors.white.withValues(alpha: 0.18) : Couleurs.trait),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              theme.isEmpty ? 'Étape $etape sur $total' : 'Étape $etape sur $total · $theme',
              style: Textes.inter(surSombre ? 14 : 12.5, FontWeight.w600, couleur: surSombre ? Couleurs.safran : Couleurs.doux),
            ),
          ],
        ),
      );
}

/// Photo d'une recette, ou une vignette avec une icône si la recette n'a pas de photo.
class PhotoRecette extends StatelessWidget {
  const PhotoRecette({super.key, required this.recette, this.taille, this.rayon = 12});
  final Recette recette;
  final double? taille;
  final double rayon;

  @override
  Widget build(BuildContext context) {
    final contenu = recette.photoUrl.isEmpty
        ? Container(
            color: Couleurs.safranClair,
            alignment: Alignment.center,
            child: Icon(iconeRecette(recette), color: Couleurs.safranTexte, size: (taille ?? 120) * 0.38),
          )
        : Image.asset(recette.photoUrl, fit: BoxFit.cover, semanticLabel: recette.titre);
    return ClipRRect(
      borderRadius: BorderRadius.circular(rayon),
      child: SizedBox(width: taille, height: taille, child: contenu),
    );
  }
}

IconData iconeRecette(Recette r) {
  final t = r.titre.toLowerCase();
  if (t.contains('omelette') || t.contains('ojja')) return LucideIcons.eggFried;
  if (t.contains('salade')) return LucideIcons.salad;
  if (t.contains('soupe')) return LucideIcons.soup;
  if (t.contains('riz') || t.contains('flocons')) return LucideIcons.wheat;
  if (t.contains('pizza')) return LucideIcons.pizza;
  if (t.contains('tartine')) return LucideIcons.sandwich;
  if (t.contains('penne') || t.contains('nouilles')) return LucideIcons.cookingPot;
  return LucideIcons.utensils;
}

/// Carte d'un repas (écran 12) : photo, type, nom, temps, calories, badges, bouton « Remplacer ».
class CarteRepas extends StatelessWidget {
  const CarteRepas({super.key, required this.repas, required this.onTap, required this.onRemplacer});
  final Repas repas;
  final VoidCallback onTap;
  final VoidCallback onRemplacer;

  @override
  Widget build(BuildContext context) => Carte(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            PhotoRecette(recette: repas.recette, taille: 78),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repas.type.libelle, style: Textes.inter(11.5, FontWeight.w600, couleur: Couleurs.doux)),
                  const SizedBox(height: 1),
                  Text(repas.recette.titre, style: Textes.titreCarte),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 13, color: Couleurs.doux),
                      const SizedBox(width: 3),
                      Text('${repas.recette.tempsPreparationMin} min', style: Textes.inter(12, FontWeight.w400, couleur: Couleurs.doux)),
                      const SizedBox(width: 10),
                      const Icon(LucideIcons.flame, size: 13, color: Couleurs.doux),
                      const SizedBox(width: 3),
                      Text('${repas.kcal} kcal', style: Textes.inter(12, FontWeight.w400, couleur: Couleurs.doux)),
                    ],
                  ),
                  if (repas.estAdapte) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 5, runSpacing: 5, children: badgesAdaptations(repas.adaptations)),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                onPressed: onRemplacer,
                tooltip: 'Remplacer ce repas',
                style: IconButton.styleFrom(
                  shape: const CircleBorder(side: BorderSide(color: Couleurs.trait)),
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(LucideIcons.refreshCw, size: 16, color: Couleurs.doux),
              ),
            ),
          ],
        ),
      );
}

/// Icônes des appareils de l'écran 09 (le four est dessiné, comme dans le prototype).
Widget iconeEquipement(TypeEquipement t, {double taille = 22, Color couleur = Couleurs.encre}) => switch (t) {
      TypeEquipement.plaque => Icon(LucideIcons.flame, size: taille, color: couleur),
      TypeEquipement.casserole => Icon(LucideIcons.cookingPot, size: taille, color: couleur),
      TypeEquipement.poele => Icon(LucideIcons.eggFried, size: taille, color: couleur),
      TypeEquipement.four => SizedBox(width: taille, height: taille, child: CustomPaint(painter: _Four(couleur))),
      TypeEquipement.microOndes => Icon(LucideIcons.microwave, size: taille, color: couleur),
      TypeEquipement.mixeur => Icon(LucideIcons.blender, size: taille, color: couleur),
      TypeEquipement.robotCuiseur => Icon(LucideIcons.chefHat, size: taille, color: couleur),
      TypeEquipement.friteuseAAir => Icon(LucideIcons.wind, size: taille, color: couleur),
      TypeEquipement.cocotteMinute => Icon(LucideIcons.soup, size: taille, color: couleur),
    };

class _Four extends CustomPainter {
  _Four(this.couleur);
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(RRect.fromLTRBR(3 * s, 3 * s, 21 * s, 21 * s, Radius.circular(2 * s)), p);
    canvas.drawLine(Offset(3 * s, 8 * s), Offset(21 * s, 8 * s), p);
    canvas.drawRRect(RRect.fromLTRBR(7 * s, 11 * s, 17 * s, 18 * s, Radius.circular(1 * s)), p);
    canvas.drawPoints(PointMode.points, [Offset(7 * s, 5.5 * s), Offset(10 * s, 5.5 * s)], p);
  }

  @override
  bool shouldRepaint(_Four old) => old.couleur != couleur;
}

/// Logo Dbarti : carré rouge harissa avec la marmite, et le nom « Dbar·ti ».
class LogoDbarti extends StatelessWidget {
  const LogoDbarti({super.key, this.couleurNom = Colors.white});
  final Color couleurNom;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Dbarti',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Couleurs.primaire, borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.cookingPot, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 10),
            ExcludeSemantics(
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Dbar'),
                  TextSpan(text: 'ti', style: TextStyle(color: Couleurs.primaire.withValues(alpha: 1))),
                ]),
                style: Textes.poppins(30, FontWeight.w800, couleur: couleurNom).copyWith(letterSpacing: -1),
              ),
            ),
          ],
        ),
      );
}

/// Titre et sous-titre d'écran.
class EnteteEcran extends StatelessWidget {
  const EnteteEcran({super.key, required this.titre, this.sousTitre});
  final String titre;
  final String? sousTitre;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: Textes.titreEcran),
          if (sousTitre != null) ...[const SizedBox(height: 4), Text(sousTitre!, style: Textes.sousTitre)],
        ],
      );
}

/// Ligne de réglage / de résumé : icône, clé, valeur, chevron ou crayon.
class LigneReglage extends StatelessWidget {
  const LigneReglage({
    super.key,
    required this.icone,
    required this.titre,
    this.detail,
    this.onTap,
    this.danger = false,
    this.fin,
    this.derniere = false,
  });

  final IconData icone;
  final String titre;
  final String? detail;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? fin;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final couleur = danger ? Couleurs.erreur : Couleurs.encre;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: derniere ? null : const Border(bottom: BorderSide(color: Couleurs.trait)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: Couleurs.fond, borderRadius: BorderRadius.circular(10)),
              child: Icon(icone, size: 17, color: couleur),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: Textes.inter(14, FontWeight.w500, couleur: couleur)),
                  if (detail != null) Text(detail!, style: Textes.inter(12, FontWeight.w400, couleur: Couleurs.doux)),
                ],
              ),
            ),
            fin ?? (onTap != null && !danger ? const Icon(LucideIcons.chevronRight, size: 18, color: Couleurs.doux) : const SizedBox()),
          ],
        ),
      ),
    );
  }
}
