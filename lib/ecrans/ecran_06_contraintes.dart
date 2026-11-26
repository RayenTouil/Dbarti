// Écran 06 — Questionnaire 3/6 : Contraintes.
// Allergies en puces (un appui, aucune saisie), régime, aliments refusés retirables (×).
// Règle annoncée : une recette qui contient un aliment exclu n'est jamais proposée.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../donnees/depot_donnees.dart';
import '../modeles/enumerations.dart';
import '../modeles/ingredient.dart';
import '../modeles/profil_nutritionnel.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_questionnaire.dart';

class EtapeContraintes extends StatefulWidget {
  const EtapeContraintes({super.key, required this.profil});
  final ProfilNutritionnel profil;

  @override
  State<EtapeContraintes> createState() => _EtapeContraintesState();
}

class _EtapeContraintesState extends EtatEtape<EtapeContraintes> {
  late final Set<Allergene> _allergies = {...widget.profil.allergies};
  late Regime _regime = widget.profil.regime;
  late final List<Ingredient> _exclus = [...widget.profil.exclus];

  @override
  Map<String, dynamic> reponses() => {
        'allergies': [for (final a in Allergene.values) if (_allergies.contains(a)) a],
        'regime': _regime,
        'exclus': List<Ingredient>.of(_exclus),
      };

  Future<void> _ajouterAliment() async {
    final depot = context.read<DepotDonnees>();
    final choix = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChoixAliment(
        ingredients: [for (final i in depot.ingredientsTries) if (!_exclus.contains(i)) i],
      ),
    );
    if (choix != null) setState(() => _exclus.add(choix));
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EnteteEcran(titre: 'Allergies et régimes', sousTitre: 'Sélectionnez tout ce qui vous concerne.'),
          const SizedBox(height: 16),
          Text('Allergies et intolérances', style: Textes.libelleChamp),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in Allergene.values)
                Puce(
                  key: Key('allergie-${a.name}'),
                  libelle: a.libelle,
                  selectionnee: _allergies.contains(a),
                  onTap: () => setState(() => _allergies.contains(a) ? _allergies.remove(a) : _allergies.add(a)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Régime', style: Textes.libelleChamp),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in Regime.values)
                Puce(
                  key: Key('regime-${r.name}'),
                  libelle: r.libelle,
                  selectionnee: _regime == r,
                  onTap: () => setState(() => _regime = r),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Aliments que je ne mange pas', style: Textes.libelleChamp),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Couleurs.carte,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Couleurs.traitFort, width: 1.5),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final i in _exclus)
                  Puce(libelle: i.nom, selectionnee: true, onSupprimer: () => setState(() => _exclus.remove(i))),
                TextButton.icon(
                  key: const Key('ajouter-aliment'),
                  onPressed: _ajouterAliment,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Ajouter un aliment…'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Encadre(
            ton: TonEncadre.olive,
            icone: LucideIcons.shieldCheck,
            child: const Text.rich(TextSpan(children: [
              TextSpan(text: 'Une recette qui contient un aliment exclu ne vous sera '),
              TextSpan(text: 'jamais', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' proposée.'),
            ])),
          ),
        ],
      );
}

/// Feuille du bas pour choisir un aliment à exclure, avec une recherche.
class _ChoixAliment extends StatefulWidget {
  const _ChoixAliment({required this.ingredients});
  final List<Ingredient> ingredients;

  @override
  State<_ChoixAliment> createState() => _ChoixAlimentState();
}

class _ChoixAlimentState extends State<_ChoixAliment> {
  String _filtre = '';

  @override
  Widget build(BuildContext context) {
    final visibles = widget.ingredients
        .where((i) => i.nom.toLowerCase().contains(_filtre.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Espaces.marge),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _filtre = v),
              decoration: InputDecoration(
                hintText: 'Chercher un aliment',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Couleurs.carte,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: visibles.length,
              itemBuilder: (_, i) => ListTile(
                key: Key('aliment-${visibles[i].id}'),
                minTileHeight: 48,
                title: Text(visibles[i].nom, style: Textes.corps),
                onTap: () => Navigator.of(context).pop(visibles[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
