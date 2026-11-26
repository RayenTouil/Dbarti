// Écran 14 — Recette détaillée.
// Trois blocs identiques (temps, portions, calories) ; adaptations visibles avant de commencer ;
// onglets Ingrédients, Étapes et Nutrition ; portions ajustables ; ingrédients remplacés signalés.
import 'package:flutter/material.dart' hide Adaptation;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../donnees/depot_donnees.dart';
import '../modeles/adaptation.dart';
import '../modeles/enumerations.dart';
import '../modeles/ligne_ingredient.dart';
import '../modeles/recette.dart';
import '../modeles/repas.dart';
import '../outils/format.dart';
import '../services/service_authentification.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_15_mode_cuisine.dart';

class EcranRecette extends StatefulWidget {
  const EcranRecette({super.key, required this.repas});
  final Repas repas;

  @override
  State<EcranRecette> createState() => _EcranRecetteState();
}

class _EcranRecetteState extends State<EcranRecette> {
  late Recette _recette; // copie : ajuster les portions ne touche pas la base
  late int _portions = widget.repas.portions;
  int _onglet = 0;

  @override
  void initState() {
    super.initState();
    _recette = widget.repas.recette.copie(context.read<DepotDonnees>());
    _recette.ajusterPortions(_portions);
  }

  void _changerPortions(int n) {
    if (n < 1 || n > 12) return;
    setState(() {
      _portions = n;
      _recette.ajusterPortions(n);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repas = widget.repas;
    final adaptations = repas.adaptations;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 214,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoRecette(recette: repas.recette, rayon: 0),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 8,
                        left: 12,
                        child: IconButton.filled(
                          tooltip: 'Retour',
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.92), foregroundColor: Couleurs.encre),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Couleurs.fond,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    padding: const EdgeInsets.fromLTRB(Espaces.marge, 16, Espaces.marge, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${repas.type.libelle} · ${formaterJour(repas.jour)}', style: Textes.etiquette),
                        Text(repas.recette.titre, style: Textes.poppins(21, FontWeight.w700, hauteur: 1.2)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _Meta(valeur: '${_recette.tempsPreparationMin} min', libelle: 'préparation')),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _Meta(
                                valeur: '$_portions portion${_portions > 1 ? 's' : ''}',
                                libelle: _portions == 1 ? 'pour vous' : 'à préparer',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _Meta(valeur: '${_recette.kcalParPortion} kcal', libelle: 'par portion')),
                          ],
                        ),
                        if (adaptations.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _EncadreAdaptations(adaptations: adaptations),
                        ],
                        const SizedBox(height: 12),
                        _Onglets(index: _onglet, onChanged: (i) => setState(() => _onglet = i)),
                        const SizedBox(height: 4),
                        switch (_onglet) {
                          0 => Column(
                              children: [
                                _ReglagePortions(portions: _portions, onChanged: _changerPortions),
                                _Ingredients(lignes: _recette.lignes, adaptations: adaptations),
                              ],
                            ),
                          1 => _Etapes(recette: _recette, adaptations: adaptations),
                          _ => _Nutrition(recette: _recette, portions: _portions),
                        },
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PiedFixe(
            ligne: true,
            children: [
              BoutonPrincipal(
                icone: LucideIcons.chefHat,
                libelle: 'Commencer la recette',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EcranModeCuisine(repas: repas))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.valeur, required this.libelle});
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Couleurs.carte,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Couleurs.trait),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(valeur, style: Textes.poppins(14, FontWeight.w600)),
            Text(libelle, style: Textes.inter(11, FontWeight.w400, couleur: Couleurs.doux)),
          ],
        ),
      );
}

/// Portions ajustables (Recette.ajusterPortions) : les quantités sont recalculées.
class _ReglagePortions extends StatelessWidget {
  const _ReglagePortions({required this.portions, required this.onChanged});
  final int portions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(child: Text('Quantités pour', style: Textes.inter(13.5, FontWeight.w500, couleur: Couleurs.doux))),
            IconButton(
              key: const Key('portion-moins'),
              tooltip: 'Une portion de moins',
              onPressed: portions > 1 ? () => onChanged(portions - 1) : null,
              icon: const Icon(LucideIcons.minus, size: 18),
            ),
            Text('$portions portion${portions > 1 ? 's' : ''}', style: Textes.poppins(14, FontWeight.w600)),
            IconButton(
              key: const Key('portion-plus'),
              tooltip: 'Une portion de plus',
              onPressed: portions < 12 ? () => onChanged(portions + 1) : null,
              icon: const Icon(LucideIcons.plus, size: 18),
            ),
          ],
        ),
      );
}

class _EncadreAdaptations extends StatelessWidget {
  const _EncadreAdaptations({required this.adaptations});
  final List<Adaptation> adaptations;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Couleurs.oliveClair, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in adaptations)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a.type == TypeAdaptation.ingredientLocal ? LucideIcons.leaf : LucideIcons.check,
                        size: 16, color: Couleurs.oliveTexte),
                    const SizedBox(width: 8),
                    Expanded(child: _texte(a)),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _texte(Adaptation a) {
    final style = Textes.inter(13, FontWeight.w400, couleur: Couleurs.oliveTexte, hauteur: 1.45);
    if (a.type == TypeAdaptation.ingredientLocal) {
      return texteAvecGras('Ingrédient local', ' : ${_minuscule(a.description)}', style: style);
    }
    final i = a.description.indexOf(' :');
    return i < 0
        ? Text(a.description, style: style)
        : texteAvecGras(a.description.substring(0, i), a.description.substring(i), style: style);
  }

  static String _minuscule(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}

class _Onglets extends StatelessWidget {
  const _Onglets({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Couleurs.trait))),
        child: Row(
          children: [
            for (final (i, libelle) in [(0, 'Ingrédients'), (1, 'Étapes'), (2, 'Nutrition')])
              Expanded(
                child: Semantics(
                  selected: index == i,
                  button: true,
                  child: InkWell(
                    key: Key('onglet-$i'),
                    onTap: () => onChanged(i),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: index == i ? Couleurs.primaire : Colors.transparent, width: 3),
                        ),
                      ),
                      child: Text(libelle,
                          style: Textes.inter(13.5, FontWeight.w600, couleur: index == i ? Couleurs.encre : Couleurs.doux)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.lignes, required this.adaptations});
  final List<LigneIngredient> lignes;
  final List<Adaptation> adaptations;

  /// « Yaourt nature à la place du lait de coco. » → sous-titre « remplace le lait de coco ».
  String? _remplace(LigneIngredient l) {
    const marque = ' à la place ';
    for (final a in adaptations.where((a) => a.type == TypeAdaptation.ingredientLocal)) {
      final d = a.description;
      final i = d.indexOf(marque);
      if (i > 0 && d.toLowerCase().startsWith(l.ingredient.nom.toLowerCase())) {
        final reste = d
            .substring(i + marque.length)
            .replaceAll(RegExp(r'\.$'), '')
            .replaceFirstMapped(RegExp(r'^(du |de la |de l’|des )'), (m) => switch (m[1]) {
                  'du ' => 'le ',
                  'de la ' => 'la ',
                  'de l’' => 'l’',
                  _ => 'les ',
                });
        return 'remplace $reste';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final l in lignes)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Couleurs.trait))),
              child: Row(
                children: [
                  const CaseACocher(cochee: true, taille: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.ingredient.nom, style: Textes.inter(13.5, FontWeight.w400)),
                        if (_remplace(l) case final r?)
                          Text(r, style: Textes.inter(11.5, FontWeight.w500, couleur: Couleurs.oliveTexte)),
                      ],
                    ),
                  ),
                  Text(formaterQuantite(l.quantite, l.unite), style: Textes.inter(13.5, FontWeight.w500, couleur: Couleurs.doux)),
                ],
              ),
            ),
        ],
      );
}

class _Etapes extends StatelessWidget {
  const _Etapes({required this.recette, required this.adaptations});
  final Recette recette;
  final List<Adaptation> adaptations;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final e in recette.etapes)
            Builder(builder: (context) {
              final adaptee = adaptations.where((a) => a.ordreEtape == e.ordre && a.instruction != null).firstOrNull;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Couleurs.trait))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: adaptee != null ? Couleurs.olive : Couleurs.encre,
                      child: Text('${e.ordre}', style: Textes.inter(12, FontWeight.w700, couleur: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(adaptee?.instruction ?? e.instruction, style: Textes.corps),
                          if (adaptee != null)
                            Text('Méthode adaptée à votre équipement',
                                style: Textes.inter(11.5, FontWeight.w600, couleur: Couleurs.oliveTexte)),
                          if (e.dureeMinuteur != null)
                            Text('Minuteur : ${e.dureeMinuteur} min', style: Textes.aide),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
}

class _Nutrition extends StatelessWidget {
  const _Nutrition({required this.recette, required this.portions});
  final Recette recette;
  final int portions;

  @override
  Widget build(BuildContext context) {
    final cible = context.read<ServiceAuthentification>().utilisateurCourant?.profil?.besoinKcal ?? 0;
    final part = cible == 0 ? 0 : (recette.kcalParPortion * 100 / cible).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Carte(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${recette.kcalParPortion} kcal', style: Textes.poppins(20, FontWeight.w700)),
                    Text('par portion', style: Textes.aide),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$part %', style: Textes.poppins(20, FontWeight.w700, couleur: Couleurs.oliveTexte)),
                    Text('de votre cible du jour', style: Textes.aide),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Apport des ingrédients pesés (pour $portions portion${portions > 1 ? 's' : ''})', style: Textes.libelleChamp),
        for (final l in recette.lignes)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Couleurs.trait))),
            child: Row(
              children: [
                Expanded(child: Text(l.ingredient.nom, style: Textes.inter(13.5, FontWeight.w400))),
                Text(
                  l.unite == 'g' || l.unite == 'ml'
                      ? '${(l.quantite * l.ingredient.kcalPour100g / 100).round()} kcal'
                      : '—',
                  style: Textes.inter(13.5, FontWeight.w500, couleur: Couleurs.doux),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Valeurs indicatives, calculées à partir des données de démonstration.', style: Textes.aide),
        const SizedBox(height: 16),
      ],
    );
  }
}
