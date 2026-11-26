// Écran 15 — Mode cuisine, étape par étape (cas « Suivre la recette pas à pas », «extend»).
// Une consigne par écran, en grand, lisible à un mètre ; méthode adaptée rappelée au moment
// où elle sert ; minuteur lancé depuis l'étape ; précédent / suivant à portée du pouce.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../modeles/enumerations.dart';
import '../modeles/repas.dart';
import '../outils/format.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';

class EcranModeCuisine extends StatefulWidget {
  const EcranModeCuisine({super.key, required this.repas});
  final Repas repas;

  @override
  State<EcranModeCuisine> createState() => _EcranModeCuisineState();
}

class _EcranModeCuisineState extends State<EcranModeCuisine> {
  int _index = 0;
  Timer? _minuterie;
  int _restant = 0;
  bool _enMarche = false;
  bool _termine = false;

  @override
  void initState() {
    super.initState();
    _preparerMinuteur();
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  void _preparerMinuteur() {
    _minuterie?.cancel();
    final duree = widget.repas.recette.etapes[_index].dureeMinuteur;
    _restant = (duree ?? 0) * 60;
    _enMarche = false;
    _termine = false;
  }

  void _basculerMinuteur() {
    if (_enMarche) {
      _minuterie?.cancel();
      setState(() => _enMarche = false);
      return;
    }
    if (_termine) _preparerMinuteur();
    setState(() => _enMarche = true);
    _minuterie = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _restant--);
      if (_restant <= 0) {
        t.cancel();
        setState(() {
          _enMarche = false;
          _termine = true;
          _restant = 0;
        });
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
      }
    });
  }

  void _aller(int delta) {
    final etapes = widget.repas.recette.etapes;
    final suivant = _index + delta;
    if (suivant >= etapes.length) {
      Navigator.of(context).pop();
      return;
    }
    if (suivant < 0) return;
    setState(() {
      _index = suivant;
      _preparerMinuteur();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recette = widget.repas.recette;
    final etapes = recette.etapes;
    final etape = etapes[_index];
    final adaptation = widget.repas.adaptations
        .where((a) => a.type == TypeAdaptation.equipement && a.ordreEtape == etape.ordre)
        .firstOrNull;
    final derniere = _index == etapes.length - 1;
    final manque = adaptation == null ? '' : titreAdaptation(adaptation).replaceFirst('Sans ', '');

    return Scaffold(
      backgroundColor: Couleurs.sombre,
      appBar: AppBar(
        backgroundColor: Couleurs.sombre,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Quitter le mode cuisine',
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(recette.titre, style: Textes.poppins(15, FontWeight.w600, couleur: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Espaces.marge, 4, Espaces.marge, 16),
              children: [
                BarreEtapes(etape: _index + 1, total: etapes.length, theme: '', surSombre: true),
                const SizedBox(height: 18),
                Text(
                  adaptation?.instruction ?? etape.instruction,
                  key: const Key('consigne'),
                  style: Textes.poppins(25, FontWeight.w600, couleur: Colors.white, hauteur: 1.3).copyWith(letterSpacing: -0.3),
                ),
                if (adaptation != null) ...[
                  const SizedBox(height: 18),
                  Encadre(
                    ton: TonEncadre.olive,
                    surSombre: true,
                    icone: LucideIcons.lightbulb,
                    child: Text('Méthode adaptée : vous n’avez pas de $manque.'
                        '${adaptation.conseil == null ? '' : ' ${adaptation.conseil}'}'),
                  ),
                ],
                if (etape.dureeMinuteur != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      children: [
                        Icon(_termine ? LucideIcons.bellRing : LucideIcons.timer, color: Colors.white, size: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formaterMinuteur(_restant),
                                key: const Key('minuteur'),
                                style: Textes.poppins(30, FontWeight.w700, couleur: Colors.white)
                                    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                              Text(_termine ? 'Terminé !' : 'Minuteur de l’étape',
                                  style: Textes.inter(12, FontWeight.w400, couleur: Couleurs.douxSurSombre)),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: TextButton.icon(
                            key: const Key('bouton-minuteur'),
                            onPressed: _basculerMinuteur,
                            style: TextButton.styleFrom(
                              backgroundColor: Couleurs.safran,
                              foregroundColor: Couleurs.encre,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: Icon(_enMarche ? LucideIcons.pause : LucideIcons.play, size: 16),
                            label: Text(
                              _enMarche ? 'Pause' : (_termine ? 'Relancer' : 'Lancer'),
                              style: Textes.poppins(14, FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          PiedFixe(
            fond: Colors.transparent,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: BoutonSecondaire(
                      surSombre: true,
                      libelle: 'Précédente',
                      onPressed: _index == 0 ? null : () => _aller(-1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 15,
                    child: BoutonPrincipal(
                      key: const Key('etape-suivante'),
                      libelle: derniere ? 'Terminer' : 'Étape suivante',
                      iconeFin: derniere ? LucideIcons.check : LucideIcons.chevronRight,
                      onPressed: () => _aller(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
