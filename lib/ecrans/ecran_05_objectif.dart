// Écran 05 — Questionnaire 2/6 : Objectif.
// Un seul objectif, parmi quatre cartes. Objectif GLYCEMIE : avertissement
// « parlez-en à votre médecin » (séquence 2, opt, message 10).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../modeles/enumerations.dart';
import '../modeles/profil_nutritionnel.dart';
import 'ecran_questionnaire.dart';

class EtapeObjectif extends StatefulWidget {
  const EtapeObjectif({super.key, required this.profil});
  final ProfilNutritionnel profil;

  @override
  State<EtapeObjectif> createState() => _EtapeObjectifState();
}

class _EtapeObjectifState extends EtatEtape<EtapeObjectif> {
  late Objectif _objectif = widget.profil.objectif;

  @override
  Map<String, dynamic> reponses() => {'objectif': _objectif};

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EnteteEcran(titre: 'Quel est votre objectif ?', sousTitre: 'Vous pourrez le changer à tout moment.'),
          const SizedBox(height: 16),
          for (final (objectif, icone) in [
            (Objectif.equilibre, LucideIcons.scale),
            (Objectif.perteDePoids, LucideIcons.trendingDown),
            (Objectif.priseDeMuscle, LucideIcons.dumbbell),
            (Objectif.glycemie, LucideIcons.droplet),
          ]) ...[
            CarteChoix(
              key: Key('objectif-${objectif.name}'),
              icone: icone,
              titre: objectif.libelle,
              description: objectif.description,
              selectionnee: _objectif == objectif,
              onTap: () => setState(() => _objectif = objectif),
            ),
            const SizedBox(height: 10),
          ],
          if (_objectif == Objectif.glycemie)
            const Encadre(
              key: Key('avertissement-medecin'),
              ton: TonEncadre.safran,
              icone: LucideIcons.stethoscope,
              child: Text('Si vous suivez un traitement, parlez-en à votre médecin. '
                  'Dbarti ne remplace pas un avis médical.'),
            ),
        ],
      );
}
