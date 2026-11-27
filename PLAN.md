# PLAN — application Dbarti (Flutter, Android)

> Plan écrit après la lecture complète du dossier de cours. Rien n'est codé avant ton accord.

## 0. Ce qui a été lu

| Dossier | Fichier | Contenu utile |
|---|---|---|
| obj1 | `Dbarti_Presentation.pptx` (14 diapos + notes) | Concept, cibles, objectifs, 6 fonctionnalités (4 essentielles, 2 secondaires), choix de Flutter |
| obj1 | `Dbarti_Rapport_IA.pdf` | Rapport sur la vidéo pitch : aucune exigence fonctionnelle pour l'application |
| obj1 | `Dbarti_Manuel_Installation.pdf` | Installation de Flutter et d'Android : aucune exigence fonctionnelle |
| obj1 | 3 vidéos pitch (.mp4) | Mêmes informations que la présentation, sans exigence nouvelle |
| obj3 | `Dbarti_Presentation_Semaine3(.pptx/.pdf/_10min.pptx)` | 19 cas d'utilisation, 3 descriptions détaillées, charte, 20 écrans annotés, 8 critères de Bastien et Scapin, persona Yasmine |
| obj3 | `Prototype/index.html`, `ecrans.js`, `app.css` | Textes exacts, ordre des éléments et données des 20 écrans (S01 à S18, S02E, S17D) |
| obj3 | `Ecrans/Fil_de_fer`, `Ecrans/Haute_fidelite`, carte de navigation, diagramme de cas d'utilisation | Rendus visuels des écrans |
| obj3 | `source/rendus/logo.png` | Logo : carré rouge harissa arrondi avec une marmite (icône Lucide `cooking-pot`) |
| obj 4 | `Obj_04.pdf` | **Seul énoncé présent dans le dossier** |
| obj 4 | `Dbarti_Presentation_Semaine4.pptx` (22 diapos + notes) | Diagramme de classes (4 zooms + annexe complète), 7 diagrammes de séquence, structure du code |

**À noter**
- Les énoncés des semaines 1 et 3 ne sont pas dans le dossier. Pour ces semaines, je me fonde sur les livrables, qui citent l'énoncé (« dans l'ordre demandé par l'énoncé », « partie A de l'énoncé »).
- Il n'y a aucun fichier `.puml`. Les diagrammes ont été lus dans les images de la présentation de la semaine 4 (zooms, plus l'annexe en 8772 × 4173 px découpée en tuiles). L'annexe contient trois associations absentes des zooms : `ProfilNutritionnel —exclut→ Ingredient [0..*]`, `ProfilNutritionnel —achète chez→ Enseigne [1]` et `Recette —nécessite→ Equipement [0..*]`. Elles seront codées.

## 1. Objectifs et exigences (avec leur source)

### Énoncé de la semaine 4 (`Obj_04.pdf`)
| # | Objectif | Où dans l'application |
|---|---|---|
| E4.1 | Diagramme de classes | `lib/modeles/` (16 classes, 9 énumérations), `lib/services/` (4 contrôleurs), `lib/externes/` (3 classes abstraites) |
| E4.2 | Diagrammes de séquence | Les 7 séquences codées message par message (§4) |
| E4.3 | Commencer la programmation | Application complète, testée, APK |

Prochaines étapes annoncées dans le livrable 4 (diapo 20) : coder les 16 modèles et tester leurs calculs (besoin, coût, reste du budget) ; coder les écrans d'accès et du questionnaire, reliés aux services ; relier l'agent IA à ServicePlanning, avec le filtre strict des allergies.

### Livrable de la semaine 3 : 19 cas d'utilisation, 5 acteurs
| Cas d'utilisation | Relation | Écrans | Séquence |
|---|---|---|---|
| Créer un compte | — | 01, 02, 02E | (lecture simple) |
| S'authentifier | — | 03 | 1 |
| Remplir le questionnaire de profil | include : Déclarer son équipement, Calculer le besoin nutritionnel | 04 à 11 | 2 |
| Générer le planning de la semaine | include : Composer les menus, Adapter les recettes à l'équipement | 11, 12 | 3 |
| Consulter le planning | extend : Remplacer un repas | 12, 13 | 4 |
| Consulter une recette détaillée | extend : Suivre la recette pas à pas | 14, 15 | (lecture simple) |
| Générer la liste de courses chiffrée | include : Associer les produits du catalogue ; extend : Marquer « déjà à la maison » | 16 | 5 |
| Faire ses courses | extend : Commander en livraison auprès de l'enseigne | 17, 17D | 6 |
| Gérer son profil et ses données | — | 18 | (lecture simple) |
| Mettre à jour le catalogue des produits et des prix | acteur : outil de collecte | aucun | 7 |

Autres exigences de la semaine 3 :
- Charte : rouge harissa #E0482B pour l'action principale et l'onglet actif, brun #2A201C pour le texte, olive #5B8A3A pour ce qui est validé ou adapté, safran #F2A32A pour l'attention, crème #FFFAF2 pour le fond. Poppins pour les titres, Inter pour le texte, 14 sp minimum.
- Mise en page : Android d'abord (360 × 800 dp), marges de 20 dp, trois onglets fixes, une seule action principale par écran, en bas.
- Les 8 critères de Bastien et Scapin (§5).
- Persona Yasmine et données de démonstration (panier de 55,830 DT).

### Livrable de la semaine 1 (concept)
| Idée du concept | Décision | Raison |
|---|---|---|
| Planning de la semaine | Oui | Cas d'utilisation 3, séquence 3 |
| Modes et calories | Oui, sous la forme des 4 objectifs du diagramme : EQUILIBRE, PERTE_DE_POIDS, PRISE_DE_MUSCLE, GLYCEMIE | Le diagramme de la semaine 4 a priorité sur la liste plus large de la semaine 1 |
| Régimes végétarien, végane, sans gluten | Oui : énumération `Regime` et filtre strict | Diagramme et écran 06 |
| Recettes adaptées | Oui, comme dans le livrable 3 : méthode adaptée à l'équipement et ingrédient local (écrans 12 et 14) | La réécriture complète d'une recette était « secondaire » en semaine 1 et ne figure dans aucun écran ni aucune séquence |
| Courses et livraison | Oui | Séquences 5 et 6 |
| Mon frigo | **Non** | Absent des 19 cas d'utilisation et du diagramme de classes |
| Carte des restaurants et des marchés | **Non** | Fonctionnalité secondaire en semaine 1, absente des semaines 3 et 4 |
| Firebase, Google Maps, paiement | **Non** | Ta règle : tout est local, sans clé ni serveur |

## 2. Architecture

```
dbarti_app/
├─ lib/
│  ├─ main.dart                  démarrage, choix de l'agent IA, Provider
│  ├─ modeles/                   16 classes + 9 énumérations (noms exacts du diagramme)
│  ├─ services/                  ServiceAuthentification, ServiceProfil, ServicePlanning, ServiceCourses
│  ├─ externes/                  AgentIA, ServiceLivraisonEnseigne, OutilCollecte (abstraites) + implémentations
│  ├─ donnees/                   BaseDeDonnees (participant des séquences) + chargement des JSON
│  ├─ ecrans/                    un fichier par écran, numéro de l'écran en commentaire
│  ├─ composants/                éléments réutilisés : carte de repas, champ, bouton principal, barre d'étapes
│  └─ theme/                     couleurs, typographie, espacements (charte de la semaine 3)
├─ assets/
│  ├─ donnees/                   recettes.json, ingredients.json, enseignes.json, catalogues.json,
│  │                             agent_ia.json, collecte/*.json
│  ├─ images/                    10 photos du prototype (Wikimedia Commons, crédits dans le README)
│  └─ polices/                   Poppins (5 graisses) et Inter, licence SIL OFL
├─ test/                         tests unitaires et test de widget
├─ docs/diagrammes/              PNG des diagrammes, extraits de la présentation de la semaine 4
└─ .github/workflows/build-apk.yml
```

### Du diagramme UML au code Dart
- Classe → `class` ; énumération → `enum`, avec les valeurs du diagramme en camelCase (`TypeEquipement.microOndes`), comme dans l'extrait de code de la diapo 19.
- « − » privé → champ `_nom` avec un accesseur en lecture ; « + » → membre public.
- Composition → liste possédée par l'objet (`PlanningSemaine._repas` : exactement 21, vérifié dans le constructeur ; `Recette._lignes`, `Recette._etapes` ; `ListeCourses._articles` ; `Enseigne` ◆ `Catalogue` ◆ `Produit` ; `Utilisateur` ◆ `ProfilNutritionnel` [0..1] ; `Repas` ◆ `Adaptation`).
- Association → référence vers l'autre objet (`Repas.recette`, `ArticleCourse.produit` [0..1], `Produit.ingredient`, `ProfilNutritionnel.equipements`, `.exclus`, `.enseigne`).
- «système externe» → `abstract class`.
- «contrôleur» → classe de service, qui hérite de `ChangeNotifier` pour prévenir les écrans (Provider). Un écran n'appelle jamais une entité directement : il passe par son service (choix de conception n° 6 de la semaine 4).

### Systèmes externes
| Classe abstraite | Implémentation par défaut (hors ligne) | Remarque |
|---|---|---|
| `AgentIA` | `AgentIALocal` : règles déterministes et base de connaissances `agent_ia.json` (repas types, méthodes de remplacement par appareil, ingrédients locaux) | Les allergies et les exclusions ne sont **jamais** filtrées par l'agent : c'est le code de `ServicePlanning` qui le fait |
| `AgentIA` (option) | `AgentIAClaude` : API Anthropic, activée seulement avec `--dart-define=DBARTI_CLE_IA=...` | Le modèle choisit parmi les identifiants de recettes de la base locale, puis le code vérifie. Sans clé, l'application n'appelle aucun réseau |
| `ServiceLivraisonEnseigne` | `ServiceLivraisonEnseigneLocal` : `ouvrirPanier()` renvoie le site de l'enseigne (`https://www.carrefour.tn`) | Aucune commande n'est passée dans Dbarti |
| `OutilCollecte` | `OutilCollecteLocal` : import des fichiers JSON `assets/donnees/collecte/` | Lancé au démarrage, au plus une fois par jour (simule « chaque nuit »). Aucun scraping |

### Persistance et état
- **Hive** (`hive_ce`, version maintenue de Hive) : boîtes clé → JSON, sans génération de code. La classe `BaseDeDonnees` regroupe toutes les lectures et écritures (participant `:BaseDeDonnees` des séquences).
- Les données de démonstration sont chargées depuis `assets/donnees/*.json` au premier lancement.
- Mot de passe : PBKDF2-HMAC-SHA256 (paquet `crypto`), sel aléatoire de 16 octets, 10 000 itérations. Seuls le sel et l'empreinte sont stockés, jamais le mot de passe.
- Gestion d'état : `provider`, avec les 4 services comme `ChangeNotifier`.

### Paquets prévus (tous sans clé)
`provider`, `hive_ce`, `hive_ce_flutter`, `crypto`, `url_launcher`, `lucide_icons_flutter` (icônes Lucide, comme le prototype), `http` (seulement pour l'agent IA facultatif) ; en développement : `flutter_launcher_icons`, `flutter_lints`. Les dates sont formatées par une petite fonction maison (« 17 – 23 novembre »), sans `intl`.

## 3. Écrans (fidèles au prototype `ecrans.js`)

| N° | Écran | Fichier | Service utilisé |
|---|---|---|---|
| 01 | Bienvenue | `ecran_01_bienvenue.dart` | — |
| 02 / 02E | Créer un compte / état d'erreur | `ecran_02_inscription.dart` | ServiceAuthentification.inscrire |
| 03 | Se connecter | `ecran_03_connexion.dart` | ServiceAuthentification.connecter |
| 04 à 09 | Questionnaire, étapes 1 à 6 | `ecran_questionnaire.dart` + `ecran_04_corps.dart` … `ecran_09_equipement.dart` | ServiceProfil.enregistrerEtape |
| 10 | Le mode cuisine doit afficher la consigne adaptée (« Écrasez les tomates à la fourchette… »), alors qu'`Adaptation` n'a que `type` et `description` | Ajout de 3 attributs privés facultatifs à `Adaptation` : `_ordreEtape`, `_instruction` et `_conseil`. Ils sont signalés dans le code et dans le README |
| 11 | Profil nutritionnel | `ecran_11_profil_nutritionnel.dart` | ServicePlanning.genererSemaine |
| 12 | Planning de la semaine | `ecran_12_planning.dart` | ServicePlanning |
| 13 | Remplacer un repas (feuille du bas) | `ecran_13_remplacer_repas.dart` | proposerRemplacements, remplacer |
| 14 | Recette détaillée (onglets Ingrédients, Étapes, Nutrition ; portions ajustables) | `ecran_14_recette.dart` | Recette.ajusterPortions |
| 15 | Mode cuisine, étape par étape, avec minuteur | `ecran_15_mode_cuisine.dart` | — |
| 16 | Liste de courses | `ecran_16_liste_courses.dart` | ServiceCourses.genererListe, marquerArticle |
| 17 | Faire mes courses | `ecran_17_achat.dart` | ServiceCourses.acheter |
| 17D | Confirmation avant de quitter | `ecran_17d_confirmation.dart` | url_launcher |
| 18 | Profil et réglages (+ « À propos », données de démonstration) | `ecran_18_profil.dart` | ServiceProfil, ServiceAuthentification |

Navigation : trois onglets fixes, Semaine, Courses et Profil (`coquille_onglets.dart`). Le bouton retour d'Android est respecté.

## 4. Les 7 séquences dans le code

1. **S'authentifier.** `EcranConnexion.verifierFormat()` (e-mail et champs non vides) → `connecter()` → `chercher(email)` → `Utilisateur.seConnecter()` (vérifie l'empreinte) → planning si `profil.estComplet()`, sinon questionnaire (écran 04). En cas d'échec : « E-mail ou mot de passe incorrect ». Inscription (écrans 02 et 02E) : règle du mot de passe affichée avant la saisie (8 caractères, dont un chiffre), case de consentement non cochée par défaut et obligatoire, erreurs affichées sous les champs (bordure, icône et texte).
2. **Questionnaire.** Pour chaque étape : `enregistrerEtape(i, reponses)` → `valider(i)`. Si une valeur est hors limites, le message s'affiche sous le champ et l'étape n'est pas validée. Le safran « parlez-en à votre médecin » apparaît si l'objectif est GLYCEMIE. « Passer » à l'étape 4 applique les valeurs par défaut. « Créer mon profil » → `finaliserProfil()` → `calculerBesoin()` → `calculerMacros()` → enregistrement → écran 10 « Analyse IA » → écran 11.
3. **Générer le planning.** `composerMenus(profil)` renvoie 21 repas. Pour chaque repas, le code appelle `contientAllergene()` et `contientIngredient()` ; si la recette contient un aliment interdit, il demande une remplacante avec `proposerRecettes(repas, 1)`. Ensuite, `equipementsManquants()` est appelé ; s'il manque un appareil, `adapterRecette()` renvoie l'adaptation (« Sans mixeur »). S'il n'existe aucune méthode de remplacement, la recette est retirée et remplacée. Puis `PlanningSemaine` est créé, `coutEstime()` est calculé (55,830 DT pour Yasmine), et si le coût dépasse le budget, l'écart et les repas les plus chers sont signalés. L'enregistrement est fait ensuite. En cas d'erreur de l'agent : bouton « Réessayer », et l'ancien planning reste affiché.
4. **Remplacer un repas.** `proposerRecettes(repas, 5)` → `verifierRecette()` (privée) garde 3 recettes compatibles, avec l'écart de prix du panier → Remplacer (`remplacerRepas` → `changerRecette` → `coutEstime`, puis `generer(planning)` si la liste existe déjà) ou Annuler (rien ne change).
5. **Recette et mode cuisine.** Onglets, portions ajustables (`ajusterPortions`), une étape par écran en grands caractères, minuteur (`dureeMinuteur`), méthode adaptée rappelée à l'étape concernée.
6. **Liste de courses.** Quantités additionnées sur les 21 repas → `estAJour()` (plus de 7 jours : prix « indicatifs ») → `rechercherProduit()` pour chaque ingrédient (absent : « à acheter ailleurs », sans prix) → `calculerTotal()` → `resteBudget()` → `articlesParRayon()`. « Déjà à la maison » : l'article est barré et retiré du total, et un nouvel appui annule le choix.
7. **Faire ses courses.** MAGASIN ou LIVRAISON → `acheter()` → `calculerTotal()` → création d'un `Achat`. LIVRAISON : `copierListe()` dans le presse-papiers → `ouvrirPanier()` → dialogue 17D « Ouvrir carrefour.tn ? » (« Rester » / « Ouvrir carrefour.tn ») → `url_launcher`. MAGASIN : `ouvrirEnseigne()` renvoie un lien d'itinéraire vers la carte, et la liste reste dans l'onglet Courses.
8. **Mise à jour du catalogue.** `collecterCatalogue(enseigne)` → `mettreAJour(produits)` → nouvelle `dateMiseAJour`. Démonstration : la collecte de Carrefour réussit, celle de Monoprix échoue (« site inaccessible »), donc l'ancien catalogue de Monoprix est gardé et ses prix sont affichés « indicatifs ».
9. **Profil.** Chaque rubrique rouvre l'étape du questionnaire correspondante, puis le besoin est recalculé. Changer d'enseigne recalcule la liste. Se déconnecter. Supprimer le compte et ses données, avec confirmation. Rubrique « À propos » : plats, produits et prix inventés pour la démonstration, crédits des photos et des polices.

## 5. Critères de Bastien et Scapin (repris du livrable 3)

| Critère | Application dans le code |
|---|---|
| Guidage | « Étape i sur 6 » et thème, but de chaque question, articles par rayon, retour immédiat après chaque action |
| Charge de travail | Une question par écran, puces et sélecteurs plutôt que du texte, 3 informations par carte de repas |
| Contrôle explicite | Planning seulement sur « Générer ma semaine », remplacement validé par un bouton, analyse annulable, confirmation 17D |
| Adaptabilité | Étape Préférences facultative, profil modifiable, mode cuisine au choix |
| Gestion des erreurs | Unités et limites affichées, règle du mot de passe avant la saisie, message qui dit comment corriger, filtre strict |
| Homogénéité | Mêmes 3 onglets, bouton principal toujours en bas, même carte de repas, même code couleur |
| Signifiance des codes | Olive = validé ou adapté, safran = attention, icônes toujours nommées, boutons nommés par leur effet |
| Compatibilité | Français, dinars à 3 décimales (55,830 DT), enseignes tunisiennes, semaine du lundi au dimanche, conventions Android |

Cibles tactiles d'au moins 48 dp : ta règle, plus stricte que les 44 dp du prototype.

## 6. Données de démonstration (persona Yasmine)

- Profil saisi : femme, 21 ans, 165 cm, 58 kg, modérément active, objectif EQUILIBRE, allergique aux arachides, n'aime pas l'aubergine, cuisines italienne, indienne et mexicaine, 30 min au maximum, 1 personne, 60 DT par semaine, Carrefour, plaque, casserole, poêle et micro-ondes (ni four ni mixeur).
- `calculerBesoin()` = (10 × 58 + 6,25 × 165 − 5 × 21 − 161) × 1,55 = 2 088,6, arrondi à **2 090 kcal**. `calculerMacros()` : 94 g de protéines (18 %), 272 g de glucides (52 %), 70 g de lipides (30 %), comme à l'écran 11.
- Le lundi : Porridge aux dattes, Curry de pois chiches et riz (« Sans mixeur » et « Ingrédient local »), Penne au thon et tomates, soit 1 960 sur 2 090 kcal (94 %), comme à l'écran 12.
- Le planning et la liste sont construits pour donner exactement les 16 articles du prototype : **total 55,830 DT, reste 4,170 DT**. S'y ajoute 1 ingrédient absent du catalogue, « à acheter ailleurs », pour montrer ce cas.
- La base contient aussi, volontairement, des recettes qui doivent être écartées pour Yasmine : une avec des arachides (filtre des allergènes), une avec de l'aubergine (filtre des exclusions) et une qui demande un four sans méthode de remplacement (recette retirée).
- Enseignes : Carrefour et Monoprix (écran 08), avec des prix inventés et une `dateMiseAJour` par catalogue.
- Le pré-remplissage n'est pas utilisé : les valeurs de Yasmine apparaissent comme exemples grisés dans les champs.
- La mention « Plats, produits et prix inventés pour la démonstration » figure dans l'écran Profil, rubrique « À propos », et dans le README.

## 7. Tests

Tests unitaires (`flutter test`) :
- `calculerBesoin()` pour Yasmine = 2 090 ; limites du poids (29 et 251 refusés, 30 et 250 acceptés)
- Filtre des allergènes : aucun repas avec des arachides ; la recette proposée est bien remplacée
- Filtre des exclusions (aubergine)
- Adaptation « Sans mixeur » sur le curry ; recette au four sans méthode : retirée
- Planning = exactement 21 repas (7 × 3), et le constructeur refuse 20 ou 22
- Agrégation des quantités et article « à acheter ailleurs » (sans prix)
- Total 55,830 DT et reste 4,170 DT avec les données de démonstration
- « Déjà à la maison » : retiré du total, puis remis
- Catalogue de plus de 7 jours : `estAJour()` renvoie faux
- Mot de passe : jamais en clair, empreinte différente pour deux sels
- Agent en erreur : l'ancien planning est conservé

Test de widget : inscription → 6 étapes du questionnaire → analyse → profil (2 090 kcal) → « Générer ma semaine » → planning avec 3 repas.

Plus `flutter analyze` sans erreur ni avertissement.

## 8. Étapes de travail (un commit en français par étape)

1. Initialisation : `flutter create --org tn.dbarti --project-name dbarti --platforms android` dans `dbarti_app`, charte (`lib/theme`), polices, `.gitignore` (keystore, `key.properties`, `.env`, `release/`)
2. Modèles : 16 classes et 9 énumérations
3. Données de démonstration et persistance (JSON, BaseDeDonnees)
4. Services et systèmes externes
5. Écrans 01 à 18
6. Tests unitaires et test de widget
7. Build : icône, réglages Android, workflow CI, README et captures

## 9. APK, GitHub et intégration continue

- `flutter doctor` est vérifié : tout est vert pour Android (SDK 36.1.0, licences acceptées). Il ne manque que Visual Studio, qui sert seulement aux applications Windows : rien à installer.
- applicationId `tn.dbarti.app`, nom affiché « Dbarti », icône générée avec `flutter_launcher_icons` à partir du logo du dossier (redessinée en 1024 px, carré rouge avec la marmite, car `logo.png` ne fait que 176 px de haut).
- `flutter build apk --release`, signé avec la clé de debug. Aucun keystore n'est créé. Copie dans `release/Dbarti.apk`, non commitée.
- Le premier build en release va retélécharger les dépendances Gradle (environ 0,5 à 1 Go, puisque `~/.gradle/caches` a été vidé lors d'un nettoyage). Il reste 19 Go libres sur C:.
- Dépôt GitHub : il est **vide**, donc le code est poussé sur `main`, sans force push. Je n'y copie aucun fichier de cours ; seules les images des diagrammes vont dans `docs/` et les photos et polices dans `assets/`.
- `.github/workflows/build-apk.yml` : Flutter 3.47.9 et Java 17 → `pub get` → `analyze` → `test` → `build apk --release` → APK publié en artefact.
- Release `v1.0.0` avec `Dbarti.apk` (`gh release create`).
- README en français : présentation, captures, installation de l'APK, commandes, architecture avec liens vers `docs/diagrammes/`, mention des données de démonstration, crédits. Aucun nom de personne.

## 10. Points ambigus et choix retenus

| # | Point | Choix retenu (et pourquoi) |
|---|---|---|
| 1 | **minSdk 23 demandé** | Impossible avec Flutter 3.47.9 : son minimum est 24, et l'outil réécrit automatiquement toute valeur de 16 à 23 en 24 au build. **minSdk 24** (Android 7.0) |
| 2 | Bouton « Continuer avec Google » (écrans 02 et 02E) | Retiré : il n'est pas dans le diagramme (ServiceAuthentification n'a que `inscrire` et `connecter`) et demanderait un serveur et une clé |
| 3 | « Mot de passe oublié ? » (écran 03) | Retiré : sans serveur, aucun e-mail de récupération ne peut être envoyé, et le cas n'est pas dans le diagramme |
| 4 | Cloche (écran 12), icônes de partage (écrans 14 et 16), interrupteur « Cuisiner à l'avance » (écran 07) | Retirés : aucune opération ni aucun attribut ne les porte dans le diagramme, et un bouton sans effet nuirait à l'ergonomie |
| 5 | « Passer » apparaît aux étapes 4, 5 et 6 du prototype | Seulement à l'étape 4 (Préférences) : la description du cas d'utilisation et la diapo des relations disent que les autres étapes sont obligatoires (l'équipement est une « rubrique obligatoire ») |
| 6 | Le prototype barre « Huile d'olive » (17,500 DT) et affiche pourtant 55,830 DT | La séquence 5 (prioritaire) calcule 55,830 DT **avant** tout « déjà à la maison ». Dans les données de démonstration, l'huile d'olive n'est pas au catalogue Carrefour : elle sert d'exemple d'article « à acheter ailleurs » (sans prix). Le total reste 55,830 DT |
| 7 | Avertissement GLYCEMIE | Encadré safran visible dès que GLYCEMIE est choisi (séquence 2). La mention « Dbarti ne remplace pas un avis médical » reste toujours affichée à l'écran 11 |
| 8 | Objectifs autres qu'EQUILIBRE | PERTE_DE_POIDS : −400 kcal par jour (texte de l'écran 05), inclus dans `calculerBesoin()`, qui sert de cible au planning. Répartition des macros : EQUILIBRE 18/52/30 % (écran 11) ; PERTE_DE_POIDS 25/45/30 ; PRISE_DE_MUSCLE 25/50/25 ; GLYCEMIE 20/45/35. Seule la première vient des sources : les trois autres sont des valeurs de démonstration à valider |
| 9 | `Recette` n'a pas d'attribut « type de repas » | Les repas types (petit-déjeuner, déjeuner, dîner) sont rangés dans la base de connaissances de l'agent (`agent_ia.json`), pas dans `Recette` : le diagramme reste intact |
| 10 | Le mode cuisine doit afficher la consigne adaptée (« Écrasez les tomates à la fourchette… »), alors qu'`Adaptation` n'a que `type` et `description` | Ajout de 2 attributs privés facultatifs à `Adaptation` : `_ordreEtape` et `_instruction`. C'est le seul ajout à une classe du diagramme. Il est signalé dans le code et dans le README |
| 11 | `coutEstime()` et `generer(planning)` n'ont pas accès aux prix | `PlanningSemaine` et `ListeCourses` gardent une référence privée vers le catalogue de l'enseigne du profil, passée à leur création |
| 12 | TypeAdaptation.REGIME | L'énumération est gardée telle quelle. Aucun écran ni aucune séquence ne le décrit, et les recettes sont déjà marquées `regimesCompatibles` : l'agent local n'en produit pas |
| 13 | Distance du magasin (« Carrefour Lafayette · 1,2 km ») | Pas de géolocalisation, qui serait une fonctionnalité non demandée : le texte devient « Carrefour le plus proche » et le lien ouvre la recherche « Carrefour » dans l'application de cartes |
| 14 | Écarts de prix de l'écran 13 (+0,900 DT, etc.) | Ils sont calculés réellement, donc ils peuvent différer de la maquette |
| 15 | Unités des quantités | Les lignes de recette sont exprimées dans l'unité du produit (g, ml, pièce, pot) pour pouvoir chiffrer. L'écran 14 affichera donc « 250 g » de tomates au lieu de « 2 » |
| 16 | Limites des autres champs (le prototype ne donne que celles du poids) | Âge de 16 à 100 ans, taille de 100 à 250 cm, poids de 30 à 250 kg, de 1 à 10 personnes, budget de 10 à 1 000 DT, au moins un appareil de cuisson |
| 17 | Semaine affichée | `dateDebut` = lundi de la semaine en cours. Après la génération, l'écran s'ouvre sur le lundi (séquence 3, message 24) ; ensuite, sur le jour courant |
| 18 | Clé de l'agent IA dans l'APK | Une clé passée avec `--dart-define` peut être extraite de l'APK. L'APK publié et la CI sont donc construits **sans clé** ; l'option est réservée aux essais locaux |
| 19 | Onglet « Nutrition » | Le diagramme ne porte que les kcal (`kcalParPortion`, `kcalPour100g`) : l'onglet affiche les kcal par portion, la part de la cible du jour et l'apport de chaque ingrédient pesé. Pas de macros par recette, qui n'existent pas dans le modèle |
| 20 | Captures du README | Les deux options : captures dessinées par un test Flutter (vraies polices, 360 × 800 dp, `test/captures_test.dart`), et captures depuis un téléphone branché en USB quand il est disponible |
| 21 | Autres écarts techniques (ajoutés pendant le développement) | `ArticleCourse._nbRecettes` (le « 4 recettes » de l'écran 16) ; dans `ServiceAuthentification`, `seDeconnecter()` et `supprimerCompte()` relaient les opérations d'`Utilisateur`, car un écran ne parle qu'à son contrôleur ; `ServicePlanning.ecartDePrix()` (l'écart de prix de l'écran 13) ; `Recette.convientAuRegime()` (vérification du régime) |
| 22 | Moment où `adapterRecette()` est appelé | Il est appelé pour chaque repas, et pas seulement quand un appareil manque : c'est aussi lui qui renvoie l'adaptation « Ingrédient local ». S'il manque un appareil et qu'aucune méthode ne le remplace, la recette est retirée (règle de l'écran 09) |
| 23 | Cuisines préférées | L'agent local suit des semaines types par régime et respecte le temps maximal. Les cuisines préférées sont transmises à l'agent IA facultatif (Claude), mais elles ne changent pas les semaines types de l'agent local |
| 24 | Stockage | `hive_ce` (pur Dart) avec `path_provider`, et non `hive_ce_flutter` : la version 2.6 de ce dernier compile du code C sur l'ordinateur, ce qui demanderait Visual Studio pour lancer les tests sous Windows |

## 11. Version 1.1.0 — accès visiteur (compte facultatif)

Source : diagrammes mis à jour dans `obj 4/Dbarti_Presentation_Semaine4 v1.pptx` (classe `Utilisateur`, `ServiceAuthentification`, séquence 1 « Accéder à Dbarti : visiteur ou compte »).

| Exigence | Où dans le code |
|---|---|
| Écran 01 : « Continuer sans compte » (action principale), « Créer un compte », « Se connecter » | `ecran_01_bienvenue.dart` |
| Consentement santé seul, obligatoire, puis questionnaire (écran 04) | `ecran_01v_consentement.dart` → `ServiceAuthentification.demarrerVisiteur(consentement)` |
| `Utilisateur.estVisiteur` ; `nomComplet`, `email`, `motDePasseHache`, `dateInscription` facultatifs [0..1] | `modeles/utilisateur.dart` |
| Toutes les fonctions sans compte, aucun rappel ni pop-up | aucun écran ne teste `estVisiteur` sauf l'onglet Profil |
| Données seulement sur le téléphone, gardées après fermeture ; démarrage direct sur le planning ou le questionnaire | session dans `BaseDeDonnees` (Hive), `app.dart` |
| Profil : bandeau « Vous utilisez Dbarti sans compte » + « Créer un compte » facultatif | `ecran_18_profil.dart` |
| Conversion : `inscrire()` par un visiteur → `creerCompte()` sur le même objet (même id, aucune copie) | `ServiceAuthentification.inscrire`, `Utilisateur.creerCompte` |
| E-mail déjà utilisé : message clair, données du visiteur intactes | vérifié avant `creerCompte()` |
| « Effacer mes données » (avec confirmation) au lieu de « Supprimer le compte » ; pas de « Se déconnecter » pour un visiteur (il perdrait l'accès à ses données) | `ecran_18_profil.dart` |
| Migration des données existantes | `ServiceAuthentification.migrer()` au démarrage : réglage `versionSchema` = 2, comptes 1.0.0 → `estVisiteur = faux` |

Choix retenus : l'écran de consentement du visiteur est un nouvel écran (01V), car le prototype n'en avait pas ; « Créer un compte » depuis le profil réutilise l'écran 02 sans la case de consentement (déjà donné).
