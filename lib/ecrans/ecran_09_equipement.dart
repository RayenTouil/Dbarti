// Écran 09 — Questionnaire 6/6 : Équipement (cas inclus « Déclarer son équipement de cuisine »).
// Appareils représentés par des icônes et des noms courants ; état sélectionné marqué par
// une coche et une couleur ; règle d'adaptation expliquée ; le bouton annonce la création du profil.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../donnees/depot_donnees.dart';
import '../modeles/enumerations.dart';
import '../modeles/profil_nutritionnel.dart';
import '../theme/couleurs.dart';
import '../theme/typographie.dart';
import 'ecran_questionnaire.dart';

class EtapeEquipement extends StatefulWidget {
  const EtapeEquipement({super.key, required this.profil, required this.erreurs});
  final ProfilNutritionnel profil;
  final Map<String, String> erreurs;

  @override
  State<EtapeEquipement> createState() => _EtapeEquipementState();
}

class _EtapeEquipementState extends EtatEtape<EtapeEquipement> {
  late final Set<TypeEquipement> _choisis = {for (final e in widget.profil.equipements) e.type};

  @override
  Map<String, dynamic> reponses() {
    final depot = context.read<DepotDonnees>();
    return {
      'equipements': [for (final t in TypeEquipement.values) if (_choisis.contains(t)) depot.equipement(t)],
    };
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EnteteEcran(titre: 'Votre cuisine', sousTitre: 'Cochez ce que vous avez. Nous adaptons les recettes.'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.05,
            children: [for (final t in TypeEquipement.values) _tuile(t)],
          ),
          if (widget.erreurs['equipement'] != null) ...[
            const SizedBox(height: 8),
            MessageErreur(widget.erreurs['equipement']!),
          ],
          const SizedBox(height: 14),
          const Encadre(
            ton: TonEncadre.info,
            icone: LucideIcons.lightbulb,
            child: Text('Pas de mixeur ? Nous proposons une autre méthode, par exemple écraser à la fourchette. '
                'S’il n’en existe pas, la recette n’est pas proposée.'),
          ),
        ],
      );

  Widget _tuile(TypeEquipement t) {
    final on = _choisis.contains(t);
    return Semantics(
      selected: on,
      button: true,
      label: t.libelle,
      child: Material(
        color: on ? Couleurs.oliveClair : Couleurs.carte,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: on ? Couleurs.olive : Couleurs.trait, width: on ? 2 : 1),
        ),
        child: InkWell(
          key: Key('equipement-${t.name}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => on ? _choisis.remove(t) : _choisis.add(t)),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: on ? Couleurs.carte : Couleurs.fond,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: iconeEquipement(t, couleur: on ? Couleurs.olive : Couleurs.encre),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ExcludeSemantics(
                        child: Text(t.libelle, textAlign: TextAlign.center, style: Textes.inter(12, FontWeight.w600, hauteur: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
              if (on)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(color: Couleurs.olive, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
