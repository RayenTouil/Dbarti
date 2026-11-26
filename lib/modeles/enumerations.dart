// Les 9 énumérations du diagramme de classes (semaine 4).
// Valeurs du diagramme en majuscules (ex. MICRO_ONDES) → camelCase en Dart (microOndes),
// comme dans l'extrait de code de la diapo 19. Chaque valeur a son libellé affiché.

/// «énumération» Sexe
enum Sexe {
  femme('Femme'),
  homme('Homme');

  const Sexe(this.libelle);
  final String libelle;
}

/// «énumération» NiveauActivite — avec le facteur de Mifflin-St Jeor.
enum NiveauActivite {
  peuActif('Peu actif', 'Travail assis, peu de marche', 1.2),
  moderementActif('Modérément actif', 'Sport 2 à 3 fois par semaine', 1.55),
  tresActif('Très actif', 'Sport 4 fois ou plus par semaine', 1.725);

  const NiveauActivite(this.libelle, this.description, this.facteur);
  final String libelle;
  final String description;
  final double facteur;
}

/// «énumération» Objectif
enum Objectif {
  equilibre('Manger équilibré', 'Couvrir mes besoins, sans régime'),
  perteDePoids('Perdre du poids', 'Déficit modéré, environ −400 kcal par jour'),
  priseDeMuscle('Prendre du muscle', 'Plus de protéines à chaque repas'),
  glycemie('Équilibrer ma glycémie', 'Repas pauvres en sucres rapides');

  const Objectif(this.libelle, this.description);
  final String libelle;
  final String description;
}

/// «énumération» Regime
enum Regime {
  aucun('Aucun'),
  vegetarien('Végétarien'),
  vegane('Végane'),
  sansGluten('Sans gluten');

  const Regime(this.libelle);
  final String libelle;
}

/// «énumération» Allergene
enum Allergene {
  arachides('Arachides'),
  gluten('Gluten'),
  lactose('Lactose'),
  fruitsDeMer('Fruits de mer'),
  oeufs('Œufs'),
  fruitsACoque('Fruits à coque'),
  soja('Soja'),
  sesame('Sésame');

  const Allergene(this.libelle);
  final String libelle;
}

/// «énumération» TypeEquipement — libellé de l'écran 09 et nom court.
enum TypeEquipement {
  plaque('Plaque de cuisson', 'plaque'),
  casserole('Casserole', 'casserole'),
  poele('Poêle', 'poêle'),
  four('Four', 'four'),
  microOndes('Micro-ondes', 'micro-ondes'),
  mixeur('Mixeur', 'mixeur'),
  robotCuiseur('Robot cuiseur', 'robot cuiseur'),
  friteuseAAir('Friteuse à air', 'friteuse à air'),
  cocotteMinute('Cocotte-minute', 'cocotte-minute');

  const TypeEquipement(this.libelle, this.nomCourt);
  final String libelle;
  final String nomCourt;
}

/// «énumération» TypeAdaptation
enum TypeAdaptation { equipement, ingredientLocal, regime }

/// «énumération» TypeRepas
enum TypeRepas {
  petitDejeuner('Petit-déjeuner'),
  dejeuner('Déjeuner'),
  diner('Dîner');

  const TypeRepas(this.libelle);
  final String libelle;
}

/// «énumération» ModeAchat
enum ModeAchat { magasin, livraison }

/// Lit une valeur d'énumération depuis son nom JSON.
T enumDepuisNom<T extends Enum>(List<T> valeurs, String nom) =>
    valeurs.firstWhere((v) => v.name == nom);
