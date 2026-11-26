// Écran 04 — Questionnaire 1/6 : Votre corps.
// Données du calcul calorique, avec leurs unités ; poids accepté de 30 à 250 kg ;
// niveaux d'activité décrits par des exemples concrets.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../modeles/enumerations.dart';
import '../modeles/profil_nutritionnel.dart';
import '../theme/typographie.dart';
import 'ecran_questionnaire.dart';

class EtapeCorps extends StatefulWidget {
  const EtapeCorps({super.key, required this.profil, required this.erreurs});
  final ProfilNutritionnel profil;
  final Map<String, String> erreurs;

  @override
  State<EtapeCorps> createState() => _EtapeCorpsState();
}

class _EtapeCorpsState extends EtatEtape<EtapeCorps> {
  late final _age = TextEditingController(text: widget.profil.age?.toString() ?? '');
  late final _taille = TextEditingController(text: widget.profil.tailleCm?.toString() ?? '');
  late final _poids = TextEditingController(
    text: widget.profil.poidsKg == null ? '' : _sansZero(widget.profil.poidsKg!),
  );
  late Sexe? _sexe = widget.profil.sexe;
  late NiveauActivite? _activite = widget.profil.activite;

  static String _sansZero(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');

  @override
  void dispose() {
    _age.dispose();
    _taille.dispose();
    _poids.dispose();
    super.dispose();
  }

  @override
  Map<String, dynamic> reponses() => {
        'age': int.tryParse(_age.text.trim()),
        'sexe': _sexe,
        'tailleCm': int.tryParse(_taille.text.trim()),
        'poidsKg': double.tryParse(_poids.text.trim().replaceAll(',', '.')),
        'activite': _activite,
      };

  @override
  Widget build(BuildContext context) {
    final e = widget.erreurs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnteteEcran(
          titre: 'Parlons de vous',
          sousTitre: 'Ces données servent à calculer votre besoin en calories.',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 10,
              child: ChampSaisie(
                cleChamp: const Key('champ-age'),
                libelle: 'Âge',
                controleur: _age,
                unite: 'ans',
                indice: '21',
                numerique: true,
                erreur: e['age'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sexe', style: Textes.libelleChamp),
                  const SizedBox(height: 6),
                  Segment<Sexe>(
                    options: Sexe.values,
                    valeur: _sexe,
                    libelle: (s) => s.libelle,
                    onChanged: (s) => setState(() => _sexe = s),
                  ),
                  if (e['sexe'] != null) ...[const SizedBox(height: 6), MessageErreur(e['sexe']!)],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ChampSaisie(
                cleChamp: const Key('champ-taille'),
                libelle: 'Taille',
                controleur: _taille,
                unite: 'cm',
                indice: '165',
                numerique: true,
                erreur: e['taille'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChampSaisie(
                cleChamp: const Key('champ-poids'),
                libelle: 'Poids',
                controleur: _poids,
                unite: 'kg',
                indice: '58',
                numerique: true,
                decimal: true,
                erreur: e['poids'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Niveau d’activité', style: Textes.libelleChamp),
        const SizedBox(height: 6),
        for (final (niveau, icone) in [
          (NiveauActivite.peuActif, LucideIcons.armchair),
          (NiveauActivite.moderementActif, LucideIcons.bike),
          (NiveauActivite.tresActif, LucideIcons.dumbbell),
        ]) ...[
          CarteChoix(
            key: Key('activite-${niveau.name}'),
            compacte: true,
            icone: icone,
            titre: niveau.libelle,
            description: niveau.description,
            selectionnee: _activite == niveau,
            onTap: () => setState(() => _activite = niveau),
          ),
          const SizedBox(height: 10),
        ],
        if (e['activite'] != null) MessageErreur(e['activite']!),
      ],
    );
  }
}
