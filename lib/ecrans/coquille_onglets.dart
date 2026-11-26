// Navigation principale : trois onglets fixes en bas — Semaine, Courses, Profil —
// identiques sur tous les écrans (critère « homogénéité »).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../theme/couleurs.dart';
import '../theme/typographie.dart';
import 'ecran_12_planning.dart';
import 'ecran_16_liste_courses.dart';
import 'ecran_18_profil.dart';

/// Onglet affiché ; l'écran 12 s'en sert pour ouvrir les courses depuis la carte « Panier ».
class NavigationOnglets extends ChangeNotifier {
  NavigationOnglets(this._index);
  int _index;
  int get index => _index;

  void aller(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}

/// Remplace toute la pile par les onglets (après connexion ou génération du planning).
void allerAuxOnglets(NavigatorState navigateur, {int onglet = 0}) => navigateur.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => CoquilleOnglets(ongletInitial: onglet)),
      (_) => false,
    );

class CoquilleOnglets extends StatelessWidget {
  const CoquilleOnglets({super.key, this.ongletInitial = 0});
  final int ongletInitial;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => NavigationOnglets(ongletInitial),
        child: Consumer<NavigationOnglets>(
          builder: (context, nav, _) => PopScope(
            canPop: nav.index == 0,
            onPopInvokedWithResult: (aQuitte, _) {
              if (!aQuitte) nav.aller(0); // retour Android : d'abord vers « Semaine »
            },
            child: Scaffold(
              body: switch (nav.index) {
                0 => const EcranPlanning(),
                1 => const EcranListeCourses(),
                _ => const EcranProfil(),
              },
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Couleurs.trait))),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Couleurs.carte,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: Couleurs.primaireClair,
                    height: 72,
                    labelTextStyle: WidgetStateProperty.resolveWith(
                      (s) => Textes.inter(12, FontWeight.w600,
                          couleur: s.contains(WidgetState.selected) ? Couleurs.encre : Couleurs.doux),
                    ),
                    iconTheme: WidgetStateProperty.resolveWith(
                      (s) => IconThemeData(
                        size: 22,
                        color: s.contains(WidgetState.selected) ? Couleurs.primaireFonce : Couleurs.doux,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: nav.index,
                    onDestinationSelected: nav.aller,
                    destinations: const [
                      NavigationDestination(icon: Icon(LucideIcons.calendarDays), label: 'Semaine'),
                      NavigationDestination(icon: Icon(LucideIcons.shoppingBasket), label: 'Courses'),
                      NavigationDestination(icon: Icon(LucideIcons.user), label: 'Profil'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
