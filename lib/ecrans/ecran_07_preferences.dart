// Écran 07 — Questionnaire 4/6 : Préférences (étape facultative).
// « Passer » applique les valeurs par défaut : toutes les cuisines, 30 minutes au plus.
import 'package:flutter/material.dart';

import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../donnees/depot_donnees.dart';
import '../modeles/profil_nutritionnel.dart';
import '../theme/typographie.dart';
import 'ecran_questionnaire.dart';

class EtapePreferences extends StatefulWidget {
  const EtapePreferences({super.key, required this.profil});
  final ProfilNutritionnel profil;

  @override
  State<EtapePreferences> createState() => _EtapePreferencesState();
}

class _EtapePreferencesState extends EtatEtape<EtapePreferences> {
  late final Set<String> _cuisines = {...widget.profil.cuisinesPreferees};
  late int _tempsMax = widget.profil.tempsMaxMinutes;

  @override
  Map<String, dynamic> reponses() => {
        'cuisinesPreferees': [for (final c in DepotDonnees.cuisines) if (_cuisines.contains(c)) c],
        'tempsMaxMinutes': _tempsMax,
      };

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EnteteEcran(
            titre: 'Qu’aimez-vous manger ?',
            sousTitre: 'Des plats du monde entier, avec des ingrédients vendus près de chez vous.',
          ),
          const SizedBox(height: 16),
          Text('Cuisines préférées', style: Textes.libelleChamp),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in DepotDonnees.cuisines)
                Puce(
                  key: Key('cuisine-$c'),
                  libelle: c,
                  selectionnee: _cuisines.contains(c),
                  onTap: () => setState(() => _cuisines.contains(c) ? _cuisines.remove(c) : _cuisines.add(c)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Temps de préparation maximal', style: Textes.libelleChamp),
          const SizedBox(height: 8),
          Segment<int>(
            options: const [15, 30, 45, 60],
            valeur: _tempsMax,
            libelle: (m) => m == 60 ? '1 h' : '$m min',
            onChanged: (m) => setState(() => _tempsMax = m),
          ),
        ],
      );
}
