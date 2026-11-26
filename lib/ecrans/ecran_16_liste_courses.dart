// Écran 16 — Liste de courses chiffrée (séquence 5).
// Total comparé au budget (jauge et message clair) ; articles groupés par rayon ;
// conditionnement et nombre de recettes ; « déjà à la maison » barré, retiré du total,
// réversible en un appui ; « à acheter ailleurs » sans prix ; prix « indicatifs » si le
// catalogue a plus de 7 jours.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../composants/boutons.dart';
import '../composants/elements.dart';
import '../composants/formulaire.dart';
import '../modeles/article_course.dart';
import '../outils/format.dart';
import '../outils/horloge.dart';
import '../services/service_authentification.dart';
import '../services/service_courses.dart';
import '../services/service_planning.dart';
import '../theme/couleurs.dart';
import '../theme/theme.dart';
import '../theme/typographie.dart';
import 'ecran_17_achat.dart';

class EcranListeCourses extends StatefulWidget {
  const EcranListeCourses({super.key});

  @override
  State<EcranListeCourses> createState() => _EcranListeCoursesState();
}

class _EcranListeCoursesState extends State<EcranListeCourses> {
  @override
  void initState() {
    super.initState();
    // 1-2 : ouvrir l'onglet « Courses » → genererListe(planning)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final planning = context.read<ServicePlanning>().planning;
      if (planning != null && mounted) context.read<ServiceCourses>().genererListe(planning);
    });
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<ServiceCourses>();
    final planning = context.watch<ServicePlanning>().planning;
    final enseigne = context.watch<ServiceAuthentification>().utilisateurCourant?.profil?.enseigne;
    final liste = courses.liste;

    if (planning == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Espaces.marge),
          child: EnteteEcran(
            titre: 'Liste de courses',
            sousTitre: 'Générez d’abord votre semaine dans l’onglet Semaine : la liste se remplit toute seule.',
          ),
        ),
      );
    }
    if (liste == null) return const Center(child: CircularProgressIndicator());

    final budget = courses.budget;
    final total = liste.totalDT;
    final reste = liste.resteBudget(budget);
    final dansLeBudget = reste >= 0;
    final rayons = liste.articlesParRayon();
    final ageCatalogue = maintenant().difference(liste.catalogue.dateMiseAJour).inDays;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Espaces.marge, 8, Espaces.marge, 16),
              children: [
                Text('${enseigne?.nom ?? ''} · semaine du ${planning.dateDebut.day} ${mois[planning.dateDebut.month - 1]}',
                    style: Textes.etiquette),
                Text('Liste de courses', style: Textes.titreEcran),
                const SizedBox(height: 12),
                Carte(
                  key: const Key('carte-budget'),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(formaterDT(total), key: const Key('total-liste'), style: Textes.poppins(22, FontWeight.w700)),
                          const Spacer(),
                          Text('budget ${formaterDT(budget)}', style: Textes.inter(13, FontWeight.w500, couleur: Couleurs.doux)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: budget == 0 ? 0 : (total / budget).clamp(0, 1).toDouble(),
                          minHeight: 8,
                          color: dansLeBudget ? Couleurs.olive : Couleurs.safran,
                          backgroundColor: Couleurs.fond,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(dansLeBudget ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
                              size: 15, color: dansLeBudget ? Couleurs.oliveTexte : Couleurs.safranTexte),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dansLeBudget
                                  ? 'Dans votre budget : il reste ${formaterDT(reste)}.'
                                  : 'Au-dessus de votre budget de ${formaterDT(-reste)}.',
                              key: const Key('reste-budget'),
                              style: Textes.inter(12.5, FontWeight.w600,
                                  couleur: dansLeBudget ? Couleurs.oliveTexte : Couleurs.safranTexte),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (courses.prixIndicatifs) ...[
                  const SizedBox(height: 10),
                  Encadre(
                    key: const Key('prix-indicatifs'),
                    ton: TonEncadre.safran,
                    icone: LucideIcons.clock,
                    child: Text('Prix indicatifs : le catalogue ${enseigne?.nom ?? ''} n’a pas été mis à jour '
                        'depuis $ageCatalogue jours.'),
                  ),
                ],
                for (final MapEntry(key: rayon, value: articles) in rayons.entries) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(rayon, style: Textes.poppins(13, FontWeight.w600, couleur: Couleurs.doux)),
                      const Spacer(),
                      Text('${articles.length} article${articles.length > 1 ? 's' : ''}',
                          style: Textes.poppins(13, FontWeight.w600, couleur: Couleurs.doux)),
                    ],
                  ),
                  for (final a in articles)
                    _LigneArticle(
                      article: a,
                      indicatif: courses.prixIndicatifs,
                      onTap: () => courses.marquerArticle(a), // 19-20 : cocher → marquerArticle(article)
                    ),
                ],
              ],
            ),
          ),
          PiedFixe(children: [
            BoutonPrincipal(
              key: const Key('bouton-faire-courses'),
              icone: LucideIcons.shoppingCart,
              libelle: 'Faire mes courses',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcranAchat())),
            ),
          ]),
        ],
      ),
    );
  }
}

class _LigneArticle extends StatelessWidget {
  const _LigneArticle({required this.article, required this.onTap, required this.indicatif});
  final ArticleCourse article;
  final VoidCallback onTap;
  final bool indicatif;

  String get _detail {
    final a = article;
    final recettes = '${a.nbRecettes} recette${a.nbRecettes > 1 ? 's' : ''}';
    if (a.dejaALaMaison) return 'Déjà à la maison · non compté';
    if (a.aAcheterAilleurs()) return 'À acheter ailleurs · ${formaterQuantite(a.quantite, a.unite)} · $recettes';
    final p = a.produit!;
    final n = a.nbConditionnements;
    final contenu = p.contenu;
    final conditionnement = n <= 1
        ? p.conditionnement
        : (p.conditionnement.startsWith('1 ') ? formaterQuantite(contenu.quantite * n, contenu.unite) : '$n × ${p.conditionnement}');
    return '$conditionnement · $recettes';
  }

  @override
  Widget build(BuildContext context) {
    final a = article;
    final barre = a.dejaALaMaison;
    final nom = a.produit?.libelle ?? a.ingredient.nom;
    return Semantics(
      checked: barre,
      label: '$nom, ${barre ? 'déjà à la maison' : 'à acheter'}',
      child: InkWell(
        key: Key('article-${a.ingredient.id}'),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Couleurs.trait))),
          child: Row(
            children: [
              CaseACocher(cochee: barre),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: Textes.inter(14, FontWeight.w500, couleur: barre ? Couleurs.doux : Couleurs.encre).copyWith(
                        decoration: barre ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      _detail,
                      style: barre
                          ? Textes.inter(11.5, FontWeight.w600, couleur: Couleurs.oliveTexte)
                          : Textes.inter(11.5, FontWeight.w400,
                              couleur: a.aAcheterAilleurs() ? Couleurs.safranTexte : Couleurs.doux),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                a.aAcheterAilleurs() ? '—' : '${formaterDT(a.prixDT, unite: false)}${indicatif ? '*' : ''}',
                style: Textes.inter(14, FontWeight.w600, couleur: barre ? Couleurs.doux : Couleurs.encre).copyWith(
                  decoration: barre ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
