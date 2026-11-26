// Écran 18 — Profil et réglages (cas « Gérer son profil et ses données »).
// Chaque rubrique du questionnaire reste modifiable, avec un résumé de la valeur actuelle ;
// changer d'enseigne recalcule la liste avec un autre catalogue ; actions sensibles à part,
// en rouge, avec confirmation. Rubrique « À propos » : données de démonstration et crédits.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/elements.dart';
import '../modeles/utilisateur.dart';
import '../outils/format.dart';
import '../services/service_authentification.dart';
import '../services/service_courses.dart';
import '../services/service_planning.dart';
import '../services/service_profil.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_01_bienvenue.dart';
import 'ecran_11_profil_nutritionnel.dart';
import 'ecran_questionnaire.dart';

class EcranProfil extends StatelessWidget {
  const EcranProfil({super.key});

  Future<void> _modifier(BuildContext context, int etape) async {
    context.read<ServiceProfil>().demarrer();
    final navigateur = Navigator.of(context);
    final enregistre = await navigateur.push<bool>(
      MaterialPageRoute(builder: (_) => EcranQuestionnaire(etapeAModifier: etape)),
    );
    if (enregistre != true || !context.mounted) return;
    context.read<ServicePlanning>().actualiser();
    final planning = context.read<ServicePlanning>().planning;
    final courses = context.read<ServiceCourses>();
    if (planning != null && courses.liste != null) await courses.genererListe(planning);
    // Le profil recalculé, avec « Générer ma semaine » pour appliquer les nouveaux choix.
    navigateur.push(MaterialPageRoute(builder: (_) => const EcranProfilNutritionnel(modification: true)));
  }

  Future<void> _seDeconnecter(BuildContext context) async {
    final navigateur = Navigator.of(context);
    await context.read<ServiceCourses>().oublierListeEnMemoire();
    if (!context.mounted) return;
    context.read<ServiceAuthentification>().seDeconnecter();
    navigateur.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const EcranBienvenue()), (_) => false);
  }

  Future<void> _supprimer(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(LucideIcons.trash2, color: Couleurs.erreur),
        title: const Text('Supprimer votre compte ?'),
        content: const Text('Votre profil, vos plannings et votre liste de courses seront effacés de ce téléphone. '
            'Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Garder mon compte')),
          TextButton(
            key: const Key('confirmer-suppression'),
            style: TextButton.styleFrom(foregroundColor: Couleurs.erreur),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;
    final navigateur = Navigator.of(context);
    await context.read<ServiceCourses>().oublierListeEnMemoire();
    if (!context.mounted) return;
    await context.read<ServiceAuthentification>().supprimerCompte();
    navigateur.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const EcranBienvenue()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<ServiceAuthentification>().utilisateurCourant;
    final p = u?.profil;
    if (u == null || p == null) return const SizedBox();
    final exclus = [for (final a in p.allergies) a.libelle, for (final i in p.exclus) i.nom.toLowerCase()];
    final cuisines = p.cuisinesPreferees.isEmpty ? 'Toutes les cuisines' : p.cuisinesPreferees.join(', ');
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Espaces.marge, 12, Espaces.marge, 20),
        children: [
          _Entete(utilisateur: u),
          const SizedBox(height: 14),
          Carte(
            child: Column(
              children: [
                LigneReglage(
                  icone: LucideIcons.user,
                  titre: 'Mon corps',
                  detail: '${p.age} ans · ${p.tailleCm} cm · ${_kg(p.poidsKg!)} kg',
                  onTap: () => _modifier(context, 1),
                ),
                LigneReglage(
                  icone: LucideIcons.target,
                  titre: 'Mon objectif',
                  detail: '${p.objectif.libelle} · ${formaterEntier(p.besoinKcal)} kcal',
                  onTap: () => _modifier(context, 2),
                ),
                LigneReglage(
                  icone: LucideIcons.ban,
                  titre: 'Allergies et exclusions',
                  detail: exclus.isEmpty ? 'Aucune · régime ${p.regime.libelle.toLowerCase()}' : _maj(exclus.join(', ')),
                  onTap: () => _modifier(context, 3),
                ),
                LigneReglage(
                  icone: LucideIcons.heart,
                  titre: 'Mes préférences',
                  detail: '$cuisines · ${p.tempsMaxMinutes} min',
                  onTap: () => _modifier(context, 4),
                ),
                LigneReglage(
                  icone: LucideIcons.cookingPot,
                  titre: 'Mon équipement',
                  detail: '${p.equipements.length} appareil${p.equipements.length > 1 ? 's' : ''}',
                  onTap: () => _modifier(context, 6),
                ),
                LigneReglage(
                  icone: LucideIcons.wallet,
                  titre: 'Foyer et budget',
                  detail: '${p.nbPersonnes} personne${p.nbPersonnes > 1 ? 's' : ''} · '
                      '${formaterEntier((p.budgetHebdoDT ?? 0).round())} DT par semaine',
                  onTap: () => _modifier(context, 5),
                  derniere: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Carte(
            child: LigneReglage(
              icone: LucideIcons.store,
              titre: 'Enseigne',
              detail: p.enseigne?.nom ?? '',
              onTap: () => _modifier(context, 5),
              derniere: true,
            ),
          ),
          const SizedBox(height: 12),
          Carte(
            child: Column(
              children: [
                LigneReglage(
                  icone: LucideIcons.logOut,
                  titre: 'Se déconnecter',
                  onTap: () => _seDeconnecter(context),
                ),
                LigneReglage(
                  key: const Key('supprimer-compte'),
                  icone: LucideIcons.trash2,
                  titre: 'Supprimer mon compte et mes données',
                  danger: true,
                  onTap: () => _supprimer(context),
                  derniere: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Carte(
            child: LigneReglage(
              key: const Key('a-propos'),
              icone: LucideIcons.info,
              titre: 'À propos',
              detail: 'Données de démonstration, crédits',
              onTap: () => afficherAPropos(context),
              derniere: true,
            ),
          ),
        ],
      ),
    );
  }

  static String _kg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toString().replaceAll('.', ',');
  static String _maj(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Entete extends StatelessWidget {
  const _Entete({required this.utilisateur});
  final Utilisateur utilisateur;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Couleurs.primaire, shape: BoxShape.circle),
            child: Text(
              utilisateur.nomComplet.isEmpty ? '?' : utilisateur.nomComplet[0].toUpperCase(),
              style: Textes.poppins(24, FontWeight.w700, couleur: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(utilisateur.nomComplet, style: Textes.poppins(21, FontWeight.w700)),
                Text(utilisateur.email, style: Textes.aide),
              ],
            ),
          ),
        ],
      );
}

/// Rubrique « À propos » : la mention des données de démonstration et les crédits.
void afficherAPropos(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, defilement) => ListView(
          controller: defilement,
          padding: const EdgeInsets.fromLTRB(Espaces.marge, 0, Espaces.marge, 28),
          children: [
            Text('À propos de Dbarti', style: Textes.poppins(19, FontWeight.w600)),
            const SizedBox(height: 10),
            const Encadre(
              key: Key('mention-demonstration'),
              ton: TonEncadre.safran,
              icone: LucideIcons.flaskConical,
              child: Text('Données de démonstration : les plats, les produits et les prix sont inventés pour la '
                  'démonstration. Ils ne correspondent pas aux catalogues réels des enseignes.'),
            ),
            const SizedBox(height: 12),
            Text(
              'Dbarti fonctionne sans serveur : votre compte, votre profil et vos listes restent sur ce téléphone. '
              'Le calcul des calories utilise la formule de Mifflin-St Jeor. Dbarti ne remplace pas un avis médical.',
              style: Textes.corps,
            ),
            const SizedBox(height: 14),
            Text('Crédits', style: Textes.poppins(15, FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Photos des plats : Wikimedia Commons (licences CC0, CC BY et CC BY-SA ; auteurs et liens dans le '
              'fichier CREDITS.md du code source).\n'
              'Polices : Poppins et Inter, licence SIL Open Font.\n'
              'Icônes : Lucide, licence ISC.',
              style: Textes.aide,
            ),
            const SizedBox(height: 10),
            Text('Version 1.0.0', style: Textes.aide),
          ],
        ),
      ),
    );
