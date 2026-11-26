// Écrans 04 à 09 — Questionnaire de profil en 6 étapes (séquence 2).
// Ce fichier porte ce qui est commun aux 6 étapes : barre « Étape i sur 6 », retour,
// « Passer » (étape 4 seulement), bouton « Continuer » puis « Créer mon profil ».
// Il sert aussi à modifier une rubrique depuis l'écran 18 (mode modification).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../modeles/profil_nutritionnel.dart';
import '../services/service_authentification.dart';
import '../services/service_profil.dart';
import '../theme/theme.dart';
import 'ecran_04_corps.dart';
import 'ecran_05_objectif.dart';
import 'ecran_06_contraintes.dart';
import 'ecran_07_preferences.dart';
import 'ecran_08_foyer_budget.dart';
import 'ecran_09_equipement.dart';
import 'ecran_10_analyse_ia.dart';

/// État commun des étapes : chacune sait rendre ses réponses.
abstract class EtatEtape<T extends StatefulWidget> extends State<T> {
  Map<String, dynamic> reponses();
}

class EcranQuestionnaire extends StatefulWidget {
  const EcranQuestionnaire({super.key, this.etapeAModifier});

  /// Mode modification (depuis l'écran 18 ou 11) : une seule étape, puis « Enregistrer ».
  final int? etapeAModifier;

  @override
  State<EcranQuestionnaire> createState() => _EcranQuestionnaireState();
}

class _EcranQuestionnaireState extends State<EcranQuestionnaire> {
  late int _etape = widget.etapeAModifier ?? 1;
  final _cle = GlobalKey<EtatEtape>();
  Map<String, String> _erreurs = {};
  bool _envoi = false;
  final _defilement = ScrollController();

  bool get _modification => widget.etapeAModifier != null;

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  Widget _contenuEtape(ProfilNutritionnel p) => switch (_etape) {
        1 => EtapeCorps(key: _cle, profil: p, erreurs: _erreurs),
        2 => EtapeObjectif(key: _cle, profil: p),
        3 => EtapeContraintes(key: _cle, profil: p),
        4 => EtapePreferences(key: _cle, profil: p),
        5 => EtapeFoyerBudget(key: _cle, profil: p, erreurs: _erreurs),
        _ => EtapeEquipement(key: _cle, profil: p, erreurs: _erreurs),
      };

  void _allerA(int etape) {
    setState(() {
      _etape = etape;
      _erreurs = {};
    });
    if (_defilement.hasClients) _defilement.jumpTo(0);
  }

  /// Retour à l'étape précédente, sans perte des réponses.
  void _precedent() {
    final service = context.read<ServiceProfil>();
    final r = _cle.currentState?.reponses();
    if (r != null) service.enregistrerEtape(_etape, r);
    if (_etape > 1 && !_modification) {
      _allerA(_etape - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _continuer({bool passer = false}) async {
    final service = context.read<ServiceProfil>();
    final reponses = passer ? {'passer': true} : _cle.currentState!.reponses();
    final valide = service.enregistrerEtape(_etape, reponses); // 3 : enregistrerEtape(i, réponses)
    if (!valide) {
      setState(() => _erreurs = service.erreurs); // 6-7 : message sous le champ, étape non validée
      return;
    }
    if (!_modification && _etape < 6) {
      _allerA(_etape + 1);
      return;
    }
    // 11-12 : « Créer mon profil » (ou « Enregistrer ») → finaliserProfil(utilisateur)
    setState(() => _envoi = true);
    final auth = context.read<ServiceAuthentification>();
    final navigateur = Navigator.of(context);
    await service.finaliserProfil(auth.utilisateurCourant!);
    if (!mounted) return;
    setState(() => _envoi = false);
    if (_modification) {
      navigateur.pop(true); // l'écran appelant affiche le profil recalculé (écran 11)
    } else {
      navigateur.push(MaterialPageRoute(builder: (_) => const EcranAnalyseIA())); // 18 : écrans 10 et 11
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = context.watch<ServiceProfil>().brouillon;
    final peutRevenir = _etape > 1 || Navigator.of(context).canPop();
    final libelle = _modification ? 'Enregistrer' : (_etape == 6 ? 'Créer mon profil' : 'Continuer');
    return PopScope(
      canPop: _etape == 1 || _modification,
      onPopInvokedWithResult: (aQuitte, _) {
        if (!aQuitte) _precedent();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mon profil'),
          automaticallyImplyLeading: false,
          leading: peutRevenir ? BackButton(onPressed: _precedent) : null,
          actions: [
            if (_etape == 4 && !_modification)
              TextButton(onPressed: () => _continuer(passer: true), child: const Text('Passer')),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _defilement,
                padding: const EdgeInsets.fromLTRB(Espaces.marge, 4, Espaces.marge, 20),
                children: [
                  BarreEtapes(etape: _etape, total: 6, theme: ProfilNutritionnel.etapes[_etape - 1]),
                  const SizedBox(height: 16),
                  _contenuEtape(profil),
                ],
              ),
            ),
            PiedFixe(children: [
              BoutonPrincipal(
                key: const Key('bouton-questionnaire'),
                libelle: libelle,
                chargement: _envoi,
                onPressed: _continuer,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
