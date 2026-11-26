// Écran 01V — Continuer sans compte (séquence 1, alt « visiteur », messages 2 à 7).
// Seul le consentement aux données de santé est demandé, obligatoire et non coché par défaut.
// Aucun e-mail, aucun mot de passe : les données restent sur le téléphone.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../services/service_authentification.dart';
import '../services/service_profil.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_questionnaire.dart';

class EcranConsentementVisiteur extends StatefulWidget {
  const EcranConsentementVisiteur({super.key});

  @override
  State<EcranConsentementVisiteur> createState() => _EcranConsentementVisiteurState();
}

class _EcranConsentementVisiteurState extends State<EcranConsentementVisiteur> {
  bool _consentement = false;
  bool _envoi = false;
  String? _erreur;

  Future<void> _continuer() async {
    if (!_consentement) {
      setState(() => _erreur = 'Cochez la case pour que Dbarti puisse personnaliser vos repas.');
      return;
    }
    setState(() => _envoi = true);
    final auth = context.read<ServiceAuthentification>();
    final profil = context.read<ServiceProfil>();
    final navigateur = Navigator.of(context);
    await auth.demarrerVisiteur(_consentement); // 3 : demarrerVisiteur(consentement)
    profil.demarrer();
    navigateur.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EcranQuestionnaire()), // 7 : questionnaire (écran 04)
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Continuer sans compte')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Espaces.marge, 4, Espaces.marge, 16),
                children: [
                  const EnteteEcran(
                    titre: 'Une seule question avant de commencer',
                    sousTitre: 'Pas besoin d’e-mail ni de mot de passe. Vos réponses restent sur ce téléphone.',
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    checked: _consentement,
                    child: Material(
                      color: Couleurs.carte,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: _erreur != null ? Couleurs.erreur : Couleurs.trait,
                          width: _erreur != null ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        key: const Key('case-consentement-visiteur'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() {
                          _consentement = !_consentement;
                          _erreur = null;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CaseACocher(cochee: _consentement),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    const TextSpan(text: 'J’accepte que Dbarti utilise mon poids, mon objectif et mes allergies '),
                                    TextSpan(text: 'uniquement pour personnaliser mes repas', style: Textes.inter(13, FontWeight.w700)),
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
                  if (_erreur != null) ...[const SizedBox(height: 6), MessageErreur(_erreur!)],
                  const SizedBox(height: 14),
                  const Encadre(
                    ton: TonEncadre.info,
                    icone: LucideIcons.smartphone,
                    child: Text('Toutes les fonctions sont disponibles sans compte. Vous pourrez en créer un plus tard '
                        'dans l’onglet Profil, sans perdre votre planning ni votre liste de courses.'),
                  ),
                ],
              ),
            ),
            PiedFixe(children: [
              BoutonPrincipal(
                key: const Key('bouton-commencer-visiteur'),
                libelle: 'Commencer',
                chargement: _envoi,
                onPressed: _continuer,
              ),
            ]),
          ],
        ),
      );
}
