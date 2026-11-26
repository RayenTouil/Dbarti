// Écran 10 — Analyse par l'agent IA.
// L'attente est expliquée étape par étape (fait, en cours, à venir) ; le calcul des calories
// est fait par une formule, et c'est dit ; l'analyse est annulable (contrôle explicite).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../modeles/enumerations.dart';
import '../modeles/profil_nutritionnel.dart';
import '../outils/format.dart';
import '../services/service_authentification.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_11_profil_nutritionnel.dart';

class EcranAnalyseIA extends StatefulWidget {
  const EcranAnalyseIA({super.key});

  static const duree = Duration(milliseconds: 2600);

  @override
  State<EcranAnalyseIA> createState() => _EcranAnalyseIAState();
}

class _EcranAnalyseIAState extends State<EcranAnalyseIA> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: EcranAnalyseIA.duree)
    ..addListener(() => setState(() {}))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EcranProfilNutritionnel()),
        );
      }
    })
    ..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<(String, String)> _etapes(ProfilNutritionnel p) {
    final exclus = [
      for (final a in p.allergies) a.libelle.toLowerCase(),
      for (final i in p.exclus) i.nom.toLowerCase(),
    ];
    final appareils = [for (final e in p.equipements) 'votre ${e.type.nomCourt}'];
    String liste(List<String> l, String et) =>
        l.length <= 1 ? l.join() : '${l.sublist(0, l.length - 1).join(', ')} $et ${l.last}';
    final regime = p.regime == Regime.aucun ? '' : ' · régime ${p.regime.libelle.toLowerCase()}';
    return [
      ('Besoin calorique calculé', 'Formule de Mifflin-St Jeor : ${formaterEntier(p.besoinKcal)} kcal par jour'),
      (
        'Contraintes appliquées',
        exclus.isEmpty ? 'Aucune allergie ni exclusion$regime' : 'Sans ${liste(exclus, 'ni')}$regime',
      ),
      ('Choix des recettes', 'Compatibles avec ${liste(appareils, 'et')}'),
      ('Calcul du panier', 'Prix ${p.enseigne?.nom ?? ''}, budget ${formaterEntier((p.budgetHebdoDT ?? 0).round())} DT'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ServiceAuthentification>().utilisateurCourant?.profil;
    final etapes = p == null ? <(String, String)>[] : _etapes(p);
    final avance = _anim.value * (etapes.length + 0.6);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Espaces.marge, 38, Espaces.marge, 16),
                children: [
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: _anim.value,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Couleurs.trait,
                            ),
                          ),
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(color: Couleurs.primaire, borderRadius: BorderRadius.circular(22)),
                            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 34),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Votre profil se prépare', textAlign: TextAlign.center, style: Textes.titreEcran),
                  const SizedBox(height: 4),
                  Text('Cela prend moins d’une minute.', textAlign: TextAlign.center, style: Textes.sousTitre),
                  const SizedBox(height: 18),
                  Carte(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < etapes.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _EtapeAgent(
                            titre: etapes[i].$1,
                            detail: etapes[i].$2,
                            etat: avance >= i + 1 ? _Etat.fait : (avance >= i ? _Etat.enCours : _Etat.attente),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            PiedFixe(children: [
              BoutonTexte(libelle: 'Annuler', onPressed: () => Navigator.of(context).pop()),
            ]),
          ],
        ),
      ),
    );
  }
}

enum _Etat { fait, enCours, attente }

class _EtapeAgent extends StatelessWidget {
  const _EtapeAgent({required this.titre, required this.detail, required this.etat});
  final String titre;
  final String detail;
  final _Etat etat;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: switch (etat) {
              _Etat.fait => Container(
                  decoration: const BoxDecoration(color: Couleurs.olive, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 15, color: Colors.white, semanticLabel: 'fait'),
                ),
              _Etat.enCours => const CircularProgressIndicator(strokeWidth: 2.5, semanticsLabel: 'en cours'),
              _Etat.attente => Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Couleurs.traitFort, width: 2)),
                ),
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: Textes.inter(14, FontWeight.w600, couleur: etat == _Etat.attente ? Couleurs.doux : Couleurs.encre)),
                Text(detail, style: Textes.aide),
              ],
            ),
          ),
        ],
      );
}
