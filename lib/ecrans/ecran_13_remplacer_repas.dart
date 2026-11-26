// Écran 13 — Remplacer un repas (feuille du bas, séquence 4).
// Le contexte reste visible derrière la feuille ; les trois propositions respectent déjà
// profil, exclusions et équipement ; effet sur le budget avant de valider ;
// rien ne change tant que l'utilisateur n'a pas appuyé sur « Remplacer ».
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../modeles/recette.dart';
import '../modeles/repas.dart';
import '../outils/format.dart';
import '../services/service_planning.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';

Future<void> afficherRemplacement(BuildContext context, Repas repas) async {
  final messager = ScaffoldMessenger.of(context);
  final remplace = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ServicePlanning>(),
      child: FeuilleRemplacement(repas: repas),
    ),
  );
  if (remplace == true) {
    messager.showSnackBar(SnackBar(content: Text('${repas.type.libelle} remplacé : ${repas.recette.titre}.')));
  }
}

class FeuilleRemplacement extends StatefulWidget {
  const FeuilleRemplacement({super.key, required this.repas});
  final Repas repas;

  @override
  State<FeuilleRemplacement> createState() => _FeuilleRemplacementState();
}

class _FeuilleRemplacementState extends State<FeuilleRemplacement> {
  late final Future<List<(Recette, double)>> _propositions = _charger();
  Recette? _choix;
  bool _envoi = false;

  Future<List<(Recette, double)>> _charger() async {
    final service = context.read<ServicePlanning>();
    final recettes = await service.proposerRemplacements(widget.repas); // 2 à 6
    final avecEcart = [for (final r in recettes) (r, service.ecartDePrix(widget.repas, r))];
    if (avecEcart.isNotEmpty && mounted) setState(() => _choix = avecEcart.first.$1);
    return avecEcart;
  }

  Future<void> _remplacer() async {
    final choix = _choix;
    if (choix == null) return;
    setState(() => _envoi = true);
    final navigateur = Navigator.of(context);
    await context.read<ServicePlanning>().remplacer(widget.repas, choix); // 8-9 : remplacer(repas, recette)
    navigateur.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.repas;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaces.marge, 0, Espaces.marge, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.type.libelle} du ${formaterJour(r.jour)}', style: Textes.etiquette),
            Text('Remplacer « ${r.recette.titre} »', style: Textes.poppins(20, FontWeight.w700, hauteur: 1.2)),
            const SizedBox(height: 12),
            const Encadre(
              ton: TonEncadre.olive,
              icone: LucideIcons.shieldCheck,
              child: Text('Ces plats respectent votre profil, vos exclusions et votre équipement.'),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<(Recette, double)>>(
              future: _propositions,
              builder: (context, s) {
                if (s.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (s.hasError) {
                  return Encadre(
                    ton: TonEncadre.erreur,
                    icone: LucideIcons.wifiOff,
                    child: Text('Pas de proposition pour le moment : ${s.error}'),
                  );
                }
                final props = s.data!;
                if (props.isEmpty) {
                  return const Encadre(
                    ton: TonEncadre.safran,
                    icone: LucideIcons.info,
                    child: Text('Aucune autre recette compatible pour ce repas.'),
                  );
                }
                return Column(
                  children: [
                    for (final (recette, ecart) in props) ...[
                      _Option(
                        recette: recette,
                        ecart: ecart,
                        selectionnee: _choix == recette,
                        onTap: () => setState(() => _choix = recette),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: BoutonSecondaire(libelle: 'Annuler', onPressed: () => Navigator.of(context).pop(false)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 14,
                  child: BoutonPrincipal(
                    key: const Key('bouton-remplacer'),
                    libelle: 'Remplacer',
                    chargement: _envoi,
                    onPressed: _choix == null ? null : _remplacer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.recette, required this.ecart, required this.selectionnee, required this.onTap});
  final Recette recette;
  final double ecart;
  final bool selectionnee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selectionnee,
        child: Carte(
          bordure: selectionnee ? Couleurs.primaire : null,
          onTap: onTap,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PhotoRecette(recette: recette, taille: 62),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recette.titre, style: Textes.poppins(14.5, FontWeight.w600)),
                    Text('${recette.tempsPreparationMin} min · ${recette.kcalParPortion} kcal',
                        style: Textes.inter(12, FontWeight.w400, couleur: Couleurs.doux)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ecart == 0 ? '0,000 DT' : formaterDT(ecart, signe: true),
                    style: Textes.inter(13, FontWeight.w600, couleur: ecart <= 0 ? Couleurs.oliveTexte : Couleurs.encre),
                  ),
                  Text('sur le panier', style: Textes.inter(11, FontWeight.w400, couleur: Couleurs.doux)),
                ],
              ),
            ],
          ),
        ),
      );
}
