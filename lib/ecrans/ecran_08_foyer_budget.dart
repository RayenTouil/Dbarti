// Écran 08 — Questionnaire 5/6 : Foyer et budget.
// Personnes réglées avec − et + (pas de clavier), budget en dinars traduit en coût par jour,
// enseigne qui détermine le catalogue et les prix de la liste de courses.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../donnees/depot_donnees.dart';
import '../modeles/enseigne.dart';
import '../modeles/profil_nutritionnel.dart';
import '../outils/format.dart';
import '../theme/couleurs.dart';
import '../theme/typographie.dart';
import 'ecran_questionnaire.dart';

class EtapeFoyerBudget extends StatefulWidget {
  const EtapeFoyerBudget({super.key, required this.profil, required this.erreurs});
  final ProfilNutritionnel profil;
  final Map<String, String> erreurs;

  @override
  State<EtapeFoyerBudget> createState() => _EtapeFoyerBudgetState();
}

class _EtapeFoyerBudgetState extends EtatEtape<EtapeFoyerBudget> {
  late int _personnes = widget.profil.nbPersonnes;
  late final _budget = TextEditingController(
    text: widget.profil.budgetHebdoDT == null ? '' : formaterDT(widget.profil.budgetHebdoDT!, unite: false).replaceAll(RegExp(r',000$'), ''),
  );
  late Enseigne? _enseigne = widget.profil.enseigne;

  double? get _budgetSaisi => double.tryParse(_budget.text.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  @override
  Map<String, dynamic> reponses() => {'nbPersonnes': _personnes, 'budgetHebdoDT': _budgetSaisi, 'enseigne': _enseigne};

  @override
  Widget build(BuildContext context) {
    final enseignes = context.read<DepotDonnees>().enseignes;
    final e = widget.erreurs;
    final parJour = _budgetSaisi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnteteEcran(
          titre: 'Votre foyer et votre budget',
          sousTitre: 'Pour calculer les quantités et le coût de vos courses.',
        ),
        const SizedBox(height: 16),
        Text('Nombre de personnes', style: Textes.libelleChamp),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Couleurs.carte,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Couleurs.traitFort, width: 1.5),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Une personne de moins',
                onPressed: _personnes > 1 ? () => setState(() => _personnes--) : null,
                icon: const Icon(LucideIcons.minus, size: 18),
              ),
              Expanded(
                child: Text(
                  '$_personnes personne${_personnes > 1 ? 's' : ''}',
                  textAlign: TextAlign.center,
                  style: Textes.poppins(18, FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Une personne de plus',
                onPressed: _personnes < 10 ? () => setState(() => _personnes++) : null,
                icon: const Icon(LucideIcons.plus, size: 18),
              ),
            ],
          ),
        ),
        if (e['personnes'] != null) ...[const SizedBox(height: 6), MessageErreur(e['personnes']!)],
        const SizedBox(height: 14),
        ChampSaisie(
          cleChamp: const Key('champ-budget'),
          libelle: 'Budget courses par semaine',
          controleur: _budget,
          unite: 'DT',
          indice: '60',
          numerique: true,
          decimal: true,
          erreur: e['budget'],
          onChanged: (_) => setState(() {}),
          aide: parJour == null || parJour <= 0 ? 'Le budget de la semaine, en dinars.' : 'Soit environ ${formaterDT(parJour / 7)} par jour.',
        ),
        const SizedBox(height: 14),
        Text('Où faites-vous vos courses ?', style: Textes.libelleChamp),
        const SizedBox(height: 6),
        for (final enseigne in enseignes) ...[
          CarteChoix(
            key: Key('enseigne-${enseigne.id}'),
            compacte: true,
            icone: LucideIcons.store,
            titre: enseigne.nom,
            description: enseigne.description,
            selectionnee: _enseigne == enseigne,
            onTap: () => setState(() => _enseigne = enseigne),
          ),
          const SizedBox(height: 10),
        ],
        if (e['enseigne'] != null) ...[MessageErreur(e['enseigne']!), const SizedBox(height: 6)],
        Text('D’autres enseignes arriveront après le lancement.', style: Textes.aide),
      ],
    );
  }
}
