// Écran 17D — Confirmation avant de quitter Dbarti pour le site de l'enseigne.
// Confirmation explicite ; message rassurant (la liste reste dans Dbarti) ;
// deux choix nommés par leur effet (« Rester », « Ouvrir carrefour.tn ») plutôt que « Oui / Non ».
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/couleurs.dart';

Future<bool?> confirmerOuvertureEnseigne(BuildContext context, String domaine) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: Couleurs.primaireClair, shape: BoxShape.circle),
          child: const Icon(LucideIcons.externalLink, color: Couleurs.primaire, size: 22),
        ),
        title: Text('Ouvrir $domaine ?'),
        content: const Text('Vous quittez Dbarti. Votre liste de courses reste disponible dans l’onglet Courses.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Rester')),
          TextButton(
            key: const Key('ouvrir-enseigne'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Ouvrir $domaine'),
          ),
        ],
      ),
    );
