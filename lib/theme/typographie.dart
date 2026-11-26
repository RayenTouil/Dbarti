import 'package:flutter/material.dart';

import 'couleurs.dart';

/// Poppins pour les titres et les boutons, Inter pour le texte (14 sp minimum pour le texte courant).
/// Les deux polices sont embarquées dans assets/polices : l'application marche hors ligne.
abstract final class Textes {
  static TextStyle poppins(double taille, FontWeight graisse, {Color couleur = Couleurs.encre, double? hauteur}) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: taille,
        fontWeight: graisse,
        color: couleur,
        height: hauteur,
      );

  /// Inter est une police variable : la graisse passe par l'axe « wght ».
  static TextStyle inter(double taille, FontWeight graisse, {Color couleur = Couleurs.encre, double? hauteur}) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: taille,
        fontWeight: graisse,
        fontVariations: [FontVariation('wght', graisse.value.toDouble())],
        color: couleur,
        height: hauteur,
      );

  static final titreEcran = poppins(24, FontWeight.w700, hauteur: 1.2).copyWith(letterSpacing: -0.3);
  static final sousTitre = inter(14, FontWeight.w400, couleur: Couleurs.doux, hauteur: 1.45);
  static final etiquette = poppins(13, FontWeight.w600, couleur: Couleurs.doux);
  static final barreApp = poppins(18, FontWeight.w600);
  static final corps = inter(14, FontWeight.w400, hauteur: 1.45);
  static final corpsGras = inter(14, FontWeight.w600, hauteur: 1.45);
  static final aide = inter(12.5, FontWeight.w400, couleur: Couleurs.doux, hauteur: 1.4);
  static final libelleChamp = inter(13, FontWeight.w600);
  static final bouton = poppins(16, FontWeight.w600);
  static final titreCarte = poppins(15, FontWeight.w600, hauteur: 1.25);
}
