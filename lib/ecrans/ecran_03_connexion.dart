// Écran 03 — Se connecter (séquence 1).
// verifierFormat() sur le téléphone avant tout envoi ; si les identifiants sont corrects :
// planning (profil complet) ou questionnaire (écran 04) ; sinon « E-mail ou mot de passe incorrect ».
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../outils/validation.dart';
import '../services/service_authentification.dart';
import '../services/service_courses.dart';
import '../services/service_planning.dart';
import '../services/service_profil.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import 'coquille_onglets.dart';
import 'ecran_02_inscription.dart';
import 'ecran_questionnaire.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _masque = true;
  bool _envoi = false;
  String? _erreurEmail;
  String? _erreurMotDePasse;
  String? _erreurIdentifiants;

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  /// Message 3 : verifierFormat() — sans rien envoyer.
  bool verifierFormat() {
    setState(() {
      _erreurEmail = erreurEmail(_email.text);
      _erreurMotDePasse = _motDePasse.text.isEmpty ? 'Saisissez votre mot de passe.' : null;
      _erreurIdentifiants = null;
    });
    return _erreurEmail == null && _erreurMotDePasse == null;
  }

  Future<void> _seConnecter() async {
    if (!verifierFormat()) return; // 4 : message sous le champ
    setState(() => _envoi = true);
    final auth = context.read<ServiceAuthentification>();
    final profil = context.read<ServiceProfil>();
    final courses = context.read<ServiceCourses>();
    final planning = context.read<ServicePlanning>();
    final navigateur = Navigator.of(context);
    final u = await auth.connecter(_email.text, _motDePasse.text); // 5 : connecter(email, motDePasse)
    if (!mounted) return;
    setState(() => _envoi = false);
    if (u == null) {
      setState(() => _erreurIdentifiants = 'E-mail ou mot de passe incorrect'); // 13-14
      return;
    }
    if (u.profil?.estComplet() ?? false) {
      final p = u.planningCourant;
      if (p != null) await courses.restaurer(p);
      planning.actualiser();
      navigateur.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CoquilleOnglets()), (_) => false); // 11
    } else {
      profil.demarrer();
      navigateur.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const EcranQuestionnaire()), (_) => false); // 12
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Se connecter')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Espaces.marge, 4, Espaces.marge, 16),
                children: [
                  const EnteteEcran(titre: 'Bon retour !', sousTitre: 'Votre planning vous attend.'),
                  const SizedBox(height: 18),
                  ChampSaisie(
                    cleChamp: const Key('connexion-email'),
                    libelle: 'Adresse e-mail',
                    controleur: _email,
                    icone: LucideIcons.mail,
                    erreur: _erreurEmail,
                    clavier: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  ChampSaisie(
                    cleChamp: const Key('connexion-mot-de-passe'),
                    libelle: 'Mot de passe',
                    controleur: _motDePasse,
                    icone: LucideIcons.lock,
                    motDePasse: _masque,
                    erreur: _erreurMotDePasse,
                    fin: IconButton(
                      tooltip: _masque ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                      onPressed: () => setState(() => _masque = !_masque),
                      icon: Icon(_masque ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: Couleurs.doux),
                    ),
                  ),
                  if (_erreurIdentifiants != null) ...[
                    const SizedBox(height: 14),
                    Encadre(
                      ton: TonEncadre.erreur,
                      icone: LucideIcons.circleAlert,
                      child: Text(_erreurIdentifiants!),
                    ),
                  ],
                ],
              ),
            ),
            PiedFixe(children: [
              BoutonPrincipal(
                key: const Key('bouton-se-connecter'),
                libelle: 'Se connecter',
                chargement: _envoi,
                onPressed: _seConnecter,
              ),
              BoutonTexte(
                libelle: 'Nouveau ? Créer un compte',
                onPressed: () => Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (_) => const EcranInscription())),
              ),
            ]),
          ],
        ),
      );
}
