// Écran 01 — Bienvenue (premier lancement).
// Une promesse en une phrase, une seule action principale, en bas.
import 'package:flutter/material.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_02_inscription.dart';
import 'ecran_03_connexion.dart';

class EcranBienvenue extends StatelessWidget {
  const EcranBienvenue({super.key});

  @override
  Widget build(BuildContext context) {
    Widget rond(String image, double taille) => Container(
          width: taille,
          height: taille,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Couleurs.sombre, width: 5),
            image: DecorationImage(image: AssetImage('assets/images/$image.jpg'), fit: BoxFit.cover),
          ),
        );

    return Scaffold(
      backgroundColor: Couleurs.sombre,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collage de trois plats (photos Wikimedia Commons, voir « À propos »).
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          Positioned(left: 18, top: 40, child: rond('curry', 190)),
                          Positioned(right: 18, top: 22, child: rond('grecque', 140)),
                          Positioned(right: 52, top: 160, child: rond('porridge', 128)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Espaces.marge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LogoDbarti(),
                          const SizedBox(height: 16),
                          Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'Chnowa dbartek lyoum ?\n'),
                              TextSpan(text: 'Votre semaine est prête.', style: TextStyle(color: Couleurs.safran.withValues(alpha: 1))),
                            ]),
                            style: Textes.poppins(26, FontWeight.w700, couleur: Colors.white, hauteur: 1.18)
                                .copyWith(letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Des repas adaptés à votre profil, vos recettes et une liste de courses chiffrée dans votre enseigne.',
                            style: Textes.inter(15, FontWeight.w400, couleur: Couleurs.douxSurSombre, hauteur: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PiedFixe(
              fond: Colors.transparent,
              children: [
                BoutonPrincipal(
                  libelle: 'Créer mon compte',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcranInscription())),
                ),
                BoutonTexte(
                  libelle: 'J’ai déjà un compte',
                  couleur: Colors.white,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcranConnexion())),
                ),
                Text('Gratuit · en français · Android',
                    style: Textes.inter(12.5, FontWeight.w400, couleur: const Color(0xFFA99B91))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
