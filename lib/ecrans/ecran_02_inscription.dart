// Écran 02 — Créer un compte, et son état d'erreur 02E.
// Trois champs seulement ; règle du mot de passe affichée avant la saisie ;
// consentement explicite aux données de santé (loi organique n° 2004-63), non coché par défaut.
// Le bouton reste actif : un appui montre toutes les erreurs en une fois.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/formulaire.dart';
import '../services/service_authentification.dart';
import '../services/service_profil.dart';
import '../outils/validation.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_questionnaire.dart';

class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});

  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _consentement = false;
  bool _masque = true;
  bool _envoi = false;
  Map<String, String> _erreurs = {}; // écran 02E quand non vide

  @override
  void dispose() {
    _nom.dispose();
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    final erreurs = <String, String>{
      'nom': ?erreurNom(_nom.text),
      'email': ?erreurEmail(_email.text),
      'motDePasse': ?erreurMotDePasse(_motDePasse.text),
      if (!_consentement) 'consentement': 'Cochez la case pour que Dbarti puisse personnaliser vos repas.',
    };
    setState(() => _erreurs = erreurs);
    if (erreurs.isNotEmpty) return;
    setState(() => _envoi = true);
    final auth = context.read<ServiceAuthentification>();
    final profil = context.read<ServiceProfil>();
    final navigateur = Navigator.of(context);
    try {
      await auth.inscrire(_nom.text, _email.text, _motDePasse.text, _consentement);
      profil.demarrer();
      navigateur.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const EcranQuestionnaire()), (_) => false);
    } on ErreurAuthentification catch (e) {
      setState(() => _erreurs = {'email': e.message});
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _enSavoirPlus() => showModalBottomSheet<void>(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(Espaces.marge, 0, Espaces.marge, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vos données de santé', style: Textes.poppins(19, FontWeight.w600)),
              const SizedBox(height: 10),
              Text(
                'Votre poids, votre objectif et vos allergies servent uniquement à calculer votre besoin en '
                'calories et à choisir des recettes sûres pour vous.\n\n'
                'Elles restent sur votre téléphone : Dbarti n’a pas de serveur. Vous pouvez les modifier ou '
                'les supprimer à tout moment dans l’onglet Profil (« Supprimer mon compte et mes données »).',
                style: Textes.corps,
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Créer un compte')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Espaces.marge, 4, Espaces.marge, 16),
                children: [
                  ChampSaisie(
                    cleChamp: const Key('champ-nom'),
                    libelle: 'Prénom et nom',
                    controleur: _nom,
                    icone: LucideIcons.user,
                    indice: 'Yasmine Trabelsi',
                    erreur: _erreurs['nom'],
                    clavier: TextInputType.name,
                  ),
                  const SizedBox(height: 14),
                  ChampSaisie(
                    cleChamp: const Key('champ-email'),
                    libelle: 'Adresse e-mail',
                    controleur: _email,
                    icone: LucideIcons.mail,
                    indice: 'yasmine@exemple.tn',
                    erreur: _erreurs['email'],
                    clavier: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  ChampSaisie(
                    cleChamp: const Key('champ-mot-de-passe'),
                    libelle: 'Mot de passe',
                    controleur: _motDePasse,
                    icone: LucideIcons.lock,
                    motDePasse: _masque,
                    erreur: _erreurs['motDePasse'],
                    aide: '8 caractères minimum, dont un chiffre.',
                    fin: IconButton(
                      tooltip: _masque ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                      onPressed: () => setState(() => _masque = !_masque),
                      icon: Icon(_masque ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: Couleurs.doux),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Consentement(
                    coche: _consentement,
                    erreur: _erreurs['consentement'],
                    onChanged: () => setState(() => _consentement = !_consentement),
                    onEnSavoirPlus: _enSavoirPlus,
                  ),
                ],
              ),
            ),
            PiedFixe(children: [
              BoutonPrincipal(
                key: const Key('bouton-continuer-inscription'),
                libelle: 'Continuer',
                chargement: _envoi,
                onPressed: _continuer,
              ),
            ]),
          ],
        ),
      );
}

class _Consentement extends StatelessWidget {
  const _Consentement({required this.coche, required this.onChanged, required this.onEnSavoirPlus, this.erreur});
  final bool coche;
  final VoidCallback onChanged;
  final VoidCallback onEnSavoirPlus;
  final String? erreur;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            checked: coche,
            child: Material(
              color: Couleurs.carte,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: erreur != null ? Couleurs.erreur : Couleurs.trait, width: erreur != null ? 2 : 1),
              ),
              child: InkWell(
                key: const Key('case-consentement'),
                borderRadius: BorderRadius.circular(14),
                onTap: onChanged,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseACocher(cochee: coche),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'J’accepte que Dbarti utilise mon poids, mon objectif et mes allergies '),
                            TextSpan(
                              text: 'uniquement pour personnaliser mes repas',
                              style: Textes.inter(13, FontWeight.w700),
                            ),
                            const TextSpan(text: '.'),
                          ]),
                          style: Textes.inter(13, FontWeight.w400, couleur: Couleurs.doux, hauteur: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          TextButton(onPressed: onEnSavoirPlus, child: const Text('En savoir plus')),
          if (erreur != null) MessageErreur(erreur!),
        ],
      );
}
