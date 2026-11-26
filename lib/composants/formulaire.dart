import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/couleurs.dart';
import '../theme/typographie.dart';

/// Champ de saisie de la charte : unité dans le champ, aide dessous, et en cas d'erreur
/// trois indices (bordure, icône, texte) — jamais la couleur seule (écran 02E).
class ChampSaisie extends StatelessWidget {
  const ChampSaisie({
    super.key,
    required this.libelle,
    required this.controleur,
    this.unite,
    this.aide,
    this.erreur,
    this.icone,
    this.indice,
    this.numerique = false,
    this.decimal = false,
    this.motDePasse = false,
    this.clavier,
    this.cleChamp,
    this.onChanged,
    this.fin,
  });

  final String libelle;
  final TextEditingController controleur;
  final String? unite;
  final String? aide;
  final String? erreur;
  final IconData? icone;
  final String? indice;
  final bool numerique;
  final bool decimal;
  final bool motDePasse;
  final TextInputType? clavier;
  final Key? cleChamp;
  final ValueChanged<String>? onChanged;
  final Widget? fin;

  @override
  Widget build(BuildContext context) {
    final enErreur = erreur != null;
    OutlineInputBorder bord(Color c, double l) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: l));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(libelle, style: Textes.libelleChamp),
        const SizedBox(height: 6),
        TextField(
          key: cleChamp,
          controller: controleur,
          obscureText: motDePasse,
          onChanged: onChanged,
          keyboardType: clavier ??
              (numerique ? TextInputType.numberWithOptions(decimal: decimal) : TextInputType.text),
          inputFormatters: numerique
              ? [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))]
              : null,
          style: Textes.inter(15, FontWeight.w400),
          decoration: InputDecoration(
            isDense: false,
            filled: true,
            fillColor: enErreur ? Couleurs.erreurClair : Couleurs.carte,
            hintText: indice,
            hintStyle: Textes.inter(15, FontWeight.w400, couleur: Couleurs.doux.withValues(alpha: 0.7)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: icone == null ? null : Icon(icone, size: 18, color: enErreur ? Couleurs.erreur : Couleurs.doux),
            suffixIcon: fin ??
                (enErreur
                    ? const Icon(LucideIcons.circleAlert, size: 18, color: Couleurs.erreur)
                    : null),
            suffixText: unite,
            suffixStyle: Textes.inter(15, FontWeight.w500, couleur: Couleurs.doux),
            enabledBorder: bord(enErreur ? Couleurs.erreur : Couleurs.traitFort, enErreur ? 2 : 1.5),
            focusedBorder: bord(enErreur ? Couleurs.erreur : Couleurs.encre, 2),
          ),
        ),
        if (enErreur) ...[
          const SizedBox(height: 6),
          MessageErreur(erreur!),
        ],
        if (aide != null) ...[
          const SizedBox(height: 6),
          Text(aide!, style: Textes.aide),
        ],
      ],
    );
  }
}

/// Message sous un champ : icône + texte qui dit comment corriger.
class MessageErreur extends StatelessWidget {
  const MessageErreur(this.texte, {super.key});
  final String texte;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.circleAlert, size: 15, color: Couleurs.erreur),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(texte, style: Textes.inter(12.5, FontWeight.w500, couleur: Couleurs.erreur))),
        ],
      );
}

/// Sélecteur segmenté (Femme / Homme, 15 / 30 / 45 min / 1 h).
class Segment<T> extends StatelessWidget {
  const Segment({super.key, required this.options, required this.valeur, required this.onChanged, required this.libelle});

  final List<T> options;
  final T? valeur;
  final ValueChanged<T> onChanged;
  final String Function(T) libelle;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Couleurs.traitFort, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++)
              Expanded(
                child: Semantics(
                  selected: options[i] == valeur,
                  button: true,
                  child: InkWell(
                    onTap: () => onChanged(options[i]),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: options[i] == valeur ? Couleurs.encre : Colors.transparent,
                        border: i == 0 ? null : const Border(left: BorderSide(color: Couleurs.traitFort, width: 1.5)),
                      ),
                      child: Text(
                        libelle(options[i]),
                        style: Textes.inter(14, FontWeight.w600,
                            couleur: options[i] == valeur ? Colors.white : Couleurs.encre),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Puce sélectionnable : un appui suffit, aucune saisie au clavier.
class Puce extends StatelessWidget {
  const Puce({super.key, required this.libelle, required this.selectionnee, this.onTap, this.onSupprimer});

  final String libelle;
  final bool selectionnee;
  final VoidCallback? onTap;
  final VoidCallback? onSupprimer;

  @override
  Widget build(BuildContext context) {
    final retirable = onSupprimer != null;
    final fond = retirable ? Couleurs.primaireClair : (selectionnee ? Couleurs.encre : Couleurs.carte);
    final bord = retirable ? Couleurs.primaire : (selectionnee ? Couleurs.encre : Couleurs.traitFort);
    final texte = retirable ? Couleurs.primaireFonce : (selectionnee ? Colors.white : Couleurs.encre);
    return Semantics(
      selected: selectionnee,
      button: true,
      child: Material(
        color: fond,
        shape: StadiumBorder(side: BorderSide(color: bord, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap ?? onSupprimer,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectionnee && !retirable) ...[
                    Icon(LucideIcons.check, size: 15, color: texte),
                    const SizedBox(width: 6),
                  ],
                  Text(libelle, style: Textes.inter(13.5, FontWeight.w500, couleur: texte)),
                  if (retirable) ...[
                    const SizedBox(width: 6),
                    Icon(LucideIcons.x, size: 14, color: texte, semanticLabel: 'Retirer $libelle'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte de choix unique (objectif, activité, enseigne) : icône, titre, conséquence, bouton radio.
class CarteChoix extends StatelessWidget {
  const CarteChoix({
    super.key,
    required this.icone,
    required this.titre,
    required this.description,
    required this.selectionnee,
    required this.onTap,
    this.compacte = false,
  });

  final IconData icone;
  final String titre;
  final String description;
  final bool selectionnee;
  final VoidCallback onTap;
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final taille = compacte ? 38.0 : 42.0;
    return Semantics(
      selected: selectionnee,
      button: true,
      child: Material(
        color: selectionnee ? Couleurs.primaireClair : Couleurs.carte,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selectionnee ? Couleurs.primaire : Couleurs.trait, width: selectionnee ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compacte ? 12 : 14, vertical: compacte ? 10 : 12),
            child: Row(
              children: [
                Container(
                  width: taille,
                  height: taille,
                  decoration: BoxDecoration(
                    color: selectionnee ? Couleurs.carte : Couleurs.fond,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, size: compacte ? 19 : 21, color: selectionnee ? Couleurs.primaire : Couleurs.encre),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titre, style: Textes.poppins(compacte ? 14 : 15, FontWeight.w600)),
                      Text(description, style: Textes.aide),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                BoutonRadio(selectionne: selectionnee),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BoutonRadio extends StatelessWidget {
  const BoutonRadio({super.key, required this.selectionne});
  final bool selectionne;

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selectionne ? Couleurs.primaire : Couleurs.traitFort, width: 2),
        ),
        alignment: Alignment.center,
        child: selectionne
            ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Couleurs.primaire, shape: BoxShape.circle))
            : null,
      );
}

/// Case à cocher de la charte (olive quand cochée).
class CaseACocher extends StatelessWidget {
  const CaseACocher({super.key, required this.cochee, this.taille = 22});
  final bool cochee;
  final double taille;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          color: cochee ? Couleurs.olive : Colors.transparent,
          borderRadius: BorderRadius.circular(taille * 0.27),
          border: Border.all(color: cochee ? Couleurs.olive : Couleurs.traitFort, width: 2),
        ),
        child: cochee ? Icon(LucideIcons.check, size: taille * 0.64, color: Colors.white) : null,
      );
}
