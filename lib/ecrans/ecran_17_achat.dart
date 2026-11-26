// Écran 17 — Faire ses courses (séquence 6).
// Deux options présentées de la même manière, l'option choisie est encadrée ;
// la livraison est assurée par l'enseigne, et c'est dit avant de quitter l'application.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../modeles/enumerations.dart';
import '../outils/format.dart';
import '../services/service_authentification.dart';
import '../services/service_courses.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_17d_confirmation.dart';

class EcranAchat extends StatefulWidget {
  const EcranAchat({super.key});

  @override
  State<EcranAchat> createState() => _EcranAchatState();
}

class _EcranAchatState extends State<EcranAchat> {
  ModeAchat _mode = ModeAchat.livraison;
  bool _copiee = false;
  bool _envoi = false;

  Future<void> _ouvrir(String lien) async {
    final ok = await launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ouvrir $lien. Votre liste reste dans l’onglet Courses.')),
      );
    }
  }

  Future<void> _continuer() async {
    final courses = context.read<ServiceCourses>();
    final liste = courses.liste;
    if (liste == null) return;
    setState(() => _envoi = true);
    await courses.acheter(liste, _mode); // 4 : acheter(liste, mode)
    if (!mounted) return;
    setState(() {
      _envoi = false;
      _copiee = _mode == ModeAchat.livraison;
    });
    final lien = courses.lien!;
    if (_mode == ModeAchat.livraison) {
      final enseigne = context.read<ServiceAuthentification>().utilisateurCourant!.profil!.enseigne!;
      final ouvrir = await confirmerOuvertureEnseigne(context, enseigne.domaine); // 13 : écran 17D
      if (ouvrir == true) await _ouvrir(lien); // 14-15 : redirection vers le site de l'enseigne
    } else {
      await _ouvrir(lien); // 16-19 : itinéraire vers le magasin
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre liste reste dans l’onglet Courses.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<ServiceCourses>();
    final enseigne = context.watch<ServiceAuthentification>().utilisateurCourant?.profil?.enseigne;
    final liste = courses.liste;
    if (liste == null || enseigne == null) return const Scaffold();
    final domaine = enseigne.domaine;
    final livraison = _mode == ModeAchat.livraison;
    return Scaffold(
      appBar: AppBar(title: const Text('Faire mes courses')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Espaces.marge, 4, Espaces.marge, 16),
              children: [
                EnteteEcran(
                  titre: 'Comment voulez-vous acheter ?',
                  sousTitre: '${formaterDT(liste.totalDT)} · ${liste.nbArticlesComptes} articles · ${enseigne.nom}',
                ),
                const SizedBox(height: 16),
                _OptionAchat(
                  cle: const Key('option-magasin'),
                  icone: LucideIcons.store,
                  titre: 'En magasin',
                  detail: '${enseigne.nom} le plus proche',
                  selectionnee: !livraison,
                  onTap: () => setState(() => _mode = ModeAchat.magasin),
                  extra: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(height: 92, width: double.infinity, child: CustomPaint(painter: _CarteMini())),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.navigation, size: 16, color: Couleurs.primaire),
                          const SizedBox(width: 6),
                          Text('Ouvrir l’itinéraire', style: Textes.inter(14, FontWeight.w600, couleur: Couleurs.primaire)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _OptionAchat(
                  cle: const Key('option-livraison'),
                  icone: LucideIcons.truck,
                  titre: 'En livraison',
                  detail: enseigne.livraisonDisponible
                      ? 'Sur $domaine, selon les conditions de l’enseigne'
                      : 'Pas de livraison chez ${enseigne.nom} pour le moment',
                  selectionnee: livraison,
                  onTap: enseigne.livraisonDisponible ? () => setState(() => _mode = ModeAchat.livraison) : null,
                ),
                const SizedBox(height: 14),
                if (livraison)
                  Encadre(
                    ton: _copiee ? TonEncadre.olive : TonEncadre.info,
                    icone: _copiee ? LucideIcons.clipboardCheck : LucideIcons.info,
                    child: Text(_copiee
                        ? 'Votre liste est copiée. Vous la retrouvez sur $domaine pour remplir votre panier et payer.'
                        : 'La livraison est assurée par ${enseigne.nom} : le panier, le paiement et la livraison '
                            'se font sur $domaine, pas dans Dbarti. Votre liste sera copiée pour la coller sur le site.'),
                  )
                else
                  const Encadre(
                    ton: TonEncadre.info,
                    icone: LucideIcons.info,
                    child: Text('L’itinéraire s’ouvre dans votre application de cartes. Votre liste reste dans l’onglet Courses.'),
                  ),
              ],
            ),
          ),
          PiedFixe(children: [
            BoutonPrincipal(
              key: const Key('bouton-continuer-achat'),
              libelle: livraison ? 'Continuer sur $domaine' : 'Ouvrir l’itinéraire',
              iconeFin: livraison ? LucideIcons.externalLink : LucideIcons.navigation,
              chargement: _envoi,
              onPressed: _continuer,
            ),
          ]),
        ],
      ),
    );
  }
}

class _OptionAchat extends StatelessWidget {
  const _OptionAchat({
    required this.cle,
    required this.icone,
    required this.titre,
    required this.detail,
    required this.selectionnee,
    required this.onTap,
    this.extra,
  });

  final Key cle;
  final IconData icone;
  final String titre;
  final String detail;
  final bool selectionnee;
  final VoidCallback? onTap;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selectionnee,
        child: Carte(
          key: cle,
          bordure: selectionnee ? Couleurs.primaire : null,
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: Couleurs.fond, borderRadius: BorderRadius.circular(12)),
                    child: Icon(icone, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: Textes.titreCarte),
                        Text(detail, style: Textes.aide),
                      ],
                    ),
                  ),
                  BoutonRadio(selectionne: selectionnee),
                ],
              ),
              ?extra,
            ],
          ),
        ),
      );
}

/// Mini-plan décoratif (comme le prototype) : rues, trajet en pointillés, départ et magasin.
class _CarteMini extends CustomPainter {
  const _CarteMini();

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFEFE6D8));
    final rue = Paint()
      ..color = Colors.white
      ..strokeWidth = 7;
    canvas
      ..drawLine(Offset(0, s.height * 0.65), Offset(s.width, s.height * 0.33), rue)
      ..drawLine(Offset(s.width * 0.2, 0), Offset(s.width * 0.3, s.height), rue)
      ..drawLine(Offset(s.width * 0.6, 0), Offset(s.width * 0.7, s.height), rue)
      ..drawLine(Offset(0, s.height * 0.22), Offset(s.width, s.height * 0.87), rue);
    final trajet = Paint()
      ..color = Couleurs.primaire
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final chemin = Path()
      ..moveTo(s.width * 0.13, s.height * 0.76)
      ..cubicTo(s.width * 0.3, s.height * 0.65, s.width * 0.43, s.height * 0.43, s.width * 0.65, s.height * 0.37);
    for (final m in chemin.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, d + 6), trajet);
      }
    }
    canvas
      ..drawCircle(Offset(s.width * 0.13, s.height * 0.76), 7, Paint()..color = Couleurs.encre)
      ..drawCircle(Offset(s.width * 0.65, s.height * 0.37), 8, Paint()..color = Couleurs.primaire);
  }

  @override
  bool shouldRepaint(_CarteMini oldDelegate) => false;
}
