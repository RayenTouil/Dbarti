import 'package:flutter/material.dart';

/// Charte graphique de la semaine 3 : chaque couleur a un rôle fixe
/// (critère « signifiance des codes »).
abstract final class Couleurs {
  /// Rouge harissa — action principale, onglet actif.
  static const primaire = Color(0xFFE0482B);
  static const primaireFonce = Color(0xFFC23A20);
  static const primaireClair = Color(0xFFFBE5DF);

  /// Brun foncé — texte, sélection, panier.
  static const encre = Color(0xFF2A201C);
  static const sombre = Color(0xFF2A201C);
  static const doux = Color(0xFF75675E);
  static const douxSurSombre = Color(0xFFD8CCC3);

  /// Olive — validé, adapté, dans le budget.
  static const olive = Color(0xFF5B8A3A);
  static const oliveClair = Color(0xFFEAF2E1);
  static const oliveTexte = Color(0xFF3F6A22);

  /// Safran — attention, ingrédient local.
  static const safran = Color(0xFFF2A32A);
  static const safranClair = Color(0xFFFDF0D5);
  static const safranTexte = Color(0xFF8F5A04);

  /// Crème — fond des écrans.
  static const fond = Color(0xFFFFFAF2);
  static const carte = Color(0xFFFFFFFF);
  static const trait = Color(0xFFEADFCF);
  static const traitFort = Color(0xFFD9CBB7);

  static const erreur = Color(0xFFB3261E);
  static const erreurClair = Color(0xFFFBE3E1);
}
