import 'package:flutter/material.dart';

import 'couleurs.dart';
import 'typographie.dart';

/// Espacements : marges de 20 dp, multiples de 4 dp (semaine 3).
abstract final class Espaces {
  static const marge = 20.0;
  static const ciblePouce = 48.0; // cibles tactiles d'au moins 48 dp
}

ThemeData themeDbarti() {
  final schema = ColorScheme.fromSeed(
    seedColor: Couleurs.primaire,
    primary: Couleurs.primaire,
    onPrimary: Colors.white,
    secondary: Couleurs.olive,
    tertiary: Couleurs.safran,
    error: Couleurs.erreur,
    surface: Couleurs.fond,
    onSurface: Couleurs.encre,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: schema,
    scaffoldBackgroundColor: Couleurs.fond,
    fontFamily: 'Inter',
    textTheme: TextTheme(
      bodyMedium: Textes.corps,
      bodyLarge: Textes.inter(15, FontWeight.w400),
      bodySmall: Textes.aide,
      titleLarge: Textes.barreApp,
      titleMedium: Textes.titreCarte,
      labelLarge: Textes.bouton,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Couleurs.fond,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Couleurs.encre,
      elevation: 0,
      titleTextStyle: Textes.barreApp,
      centerTitle: false,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Couleurs.sombre,
      contentTextStyle: Textes.inter(14, FontWeight.w500, couleur: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Couleurs.fond,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Couleurs.traitFort,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Couleurs.carte,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      titleTextStyle: Textes.poppins(19, FontWeight.w600),
      contentTextStyle: Textes.inter(14, FontWeight.w400, couleur: Couleurs.doux, hauteur: 1.45),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Couleurs.primaire,
        minimumSize: const Size(Espaces.ciblePouce, Espaces.ciblePouce),
        textStyle: Textes.inter(14, FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Couleurs.primaire),
  );
}
