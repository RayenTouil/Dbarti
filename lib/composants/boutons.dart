import 'package:flutter/material.dart';

import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';

/// Bouton principal : rouge harissa, une seule fois par écran, en bas (zone du pouce).
class BoutonPrincipal extends StatelessWidget {
  const BoutonPrincipal({super.key, required this.libelle, this.onPressed, this.icone, this.iconeFin, this.chargement = false});

  final String libelle;
  final VoidCallback? onPressed;
  final IconData? icone;
  final IconData? iconeFin;
  final bool chargement;

  @override
  Widget build(BuildContext context) => _BoutonBase(
        libelle: libelle,
        onPressed: chargement ? null : onPressed,
        icone: icone,
        iconeFin: iconeFin,
        chargement: chargement,
        fond: Couleurs.primaire,
        texte: Colors.white,
      );
}

/// Bouton secondaire : contour, fond blanc.
class BoutonSecondaire extends StatelessWidget {
  const BoutonSecondaire({super.key, required this.libelle, this.onPressed, this.icone, this.surSombre = false});

  final String libelle;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool surSombre;

  @override
  Widget build(BuildContext context) => _BoutonBase(
        libelle: libelle,
        onPressed: onPressed,
        icone: icone,
        fond: surSombre ? Colors.transparent : Couleurs.carte,
        texte: surSombre ? Colors.white : Couleurs.encre,
        bordure: surSombre ? Colors.white.withValues(alpha: 0.35) : Couleurs.traitFort,
      );
}

class _BoutonBase extends StatelessWidget {
  const _BoutonBase({
    required this.libelle,
    required this.onPressed,
    required this.fond,
    required this.texte,
    this.icone,
    this.iconeFin,
    this.bordure,
    this.chargement = false,
  });

  final String libelle;
  final VoidCallback? onPressed;
  final IconData? icone;
  final IconData? iconeFin;
  final Color fond;
  final Color texte;
  final Color? bordure;
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    final actif = onPressed != null || chargement;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: actif ? fond : fond.withValues(alpha: 0.45),
          foregroundColor: texte,
          disabledForegroundColor: texte.withValues(alpha: chargement ? 1 : 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: bordure == null ? BorderSide.none : BorderSide(color: bordure!, width: 1.5),
          ),
          textStyle: Textes.bouton,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (chargement)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: texte)),
              )
            else if (icone != null)
              Padding(padding: const EdgeInsets.only(right: 8), child: Icon(icone, size: 19)),
            Flexible(child: Text(libelle, overflow: TextOverflow.ellipsis, style: Textes.bouton.copyWith(color: texte))),
            if (iconeFin != null) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(iconeFin, size: 18)),
          ],
        ),
      ),
    );
  }
}

/// Bouton texte (action secondaire, ex. « J'ai déjà un compte »).
class BoutonTexte extends StatelessWidget {
  const BoutonTexte({super.key, required this.libelle, this.onPressed, this.couleur = Couleurs.primaire});

  final String libelle;
  final VoidCallback? onPressed;
  final Color couleur;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: Espaces.ciblePouce,
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          child: Text(libelle, style: Textes.poppins(16, FontWeight.w600, couleur: couleur)),
        ),
      );
}

/// Pied d'écran fixe : contient l'action principale, toujours au même endroit.
class PiedFixe extends StatelessWidget {
  const PiedFixe({super.key, required this.children, this.fond = Couleurs.fond, this.ligne = false});

  final List<Widget> children;
  final Color fond;
  final bool ligne;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: fond,
          border: ligne ? const Border(top: BorderSide(color: Couleurs.trait)) : null,
        ),
        padding: const EdgeInsets.fromLTRB(Espaces.marge, 12, Espaces.marge, 14),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                children[i],
              ],
            ],
          ),
        ),
      );
}
