import '../outils/horloge.dart';
import '../outils/securite.dart';
import '../outils/validation.dart';
import 'planning_semaine.dart';
import 'profil_nutritionnel.dart';
import 'referentiel.dart';

/// Utilisateur — un visiteur (sans compte) ou un utilisateur inscrit.
/// Le compte est facultatif : un visiteur n'a ni e-mail ni mot de passe ([0..1]).
/// Le mot de passe n'est jamais stocké en clair : seule son empreinte salée (PBKDF2)
/// est gardée dans motDePasseHache.
/// Compositions : « possède » 1 ◆— 0..1 ProfilNutritionnel ; « génère » 1 ◆— 0..* PlanningSemaine.
class Utilisateur {
  Utilisateur({required bool consentementSante, String? id, bool estVisiteur = false})
      : _id = id ?? nouvelIdentifiant(),
        _consentementSante = consentementSante,
        _estVisiteur = estVisiteur;

  final String _id;
  bool _estVisiteur;
  String? _nomComplet;
  String? _email;
  String? _motDePasseHache;
  DateTime? _dateInscription;
  final bool _consentementSante;
  ProfilNutritionnel? _profil;
  final List<PlanningSemaine> _plannings = [];
  bool _connecte = false;

  String get id => _id;
  bool get estVisiteur => _estVisiteur;
  String? get nomComplet => _nomComplet;
  String? get email => _email;
  String? get motDePasseHache => _motDePasseHache;
  DateTime? get dateInscription => _dateInscription;
  bool get consentementSante => _consentementSante;
  ProfilNutritionnel? get profil => _profil;
  List<PlanningSemaine> get plannings => List.unmodifiable(_plannings);
  bool get connecte => _connecte;

  /// Le profil n'existe qu'à la fin du questionnaire (multiplicité 0..1).
  set profil(ProfilNutritionnel? p) => _profil = p;

  /// Le planning le plus récent, ou null.
  PlanningSemaine? get planningCourant => _plannings.isEmpty ? null : _plannings.last;

  /// Ajoute un planning généré. On garde les deux derniers : le nouveau et le précédent.
  void ajouterPlanning(PlanningSemaine p) {
    _plannings.add(p);
    while (_plannings.length > 2) {
      _plannings.removeAt(0);
    }
  }

  /// Remplit le compte. Faux si le nom, l'e-mail ou le mot de passe ne respecte pas les règles.
  /// Appelée sur un visiteur, elle le transforme en utilisateur inscrit : même objet, même id,
  /// profil, plannings et liste conservés.
  bool creerCompte(String nom, String email, String motDePasse) {
    if (erreurNom(nom) != null || erreurEmail(email) != null || erreurMotDePasse(motDePasse) != null) {
      return false;
    }
    if (!_consentementSante) return false;
    _nomComplet = nom.trim();
    _email = email.trim().toLowerCase();
    _motDePasseHache = hacherMotDePasse(motDePasse);
    _dateInscription = maintenant();
    _estVisiteur = false;
    return true;
  }

  /// Vrai si l'e-mail et le mot de passe correspondent au compte.
  bool seConnecter(String email, String motDePasse) {
    final empreinte = _motDePasseHache;
    _connecte = !_estVisiteur &&
        empreinte != null &&
        email.trim().toLowerCase() == _email &&
        verifierMotDePasse(motDePasse, empreinte);
    return _connecte;
  }

  void seDeconnecter() => _connecte = false;

  /// Supprime les données possédées par le compte (profil et plannings).
  /// Pour un visiteur : « Effacer mes données ».
  /// La suppression dans la base est faite par le service.
  void supprimerCompte() {
    _profil = null;
    _plannings.clear();
    _connecte = false;
  }

  factory Utilisateur.depuisJson(Map<String, dynamic> j, Referentiel r) {
    // Les comptes enregistrés avant l'accès visiteur n'ont pas « estVisiteur » : ce sont des inscrits.
    final u = Utilisateur(
      consentementSante: j['consentementSante'] as bool,
      id: j['id'] as String,
      estVisiteur: j['estVisiteur'] as bool? ?? false,
    )
      .._nomComplet = j['nomComplet'] as String?
      .._email = j['email'] as String?
      .._motDePasseHache = j['motDePasseHache'] as String?
      .._dateInscription = j['dateInscription'] == null ? null : DateTime.parse(j['dateInscription'] as String)
      .._profil = j['profil'] == null
          ? null
          : ProfilNutritionnel.depuisJson(j['profil'] as Map<String, dynamic>, r);
    return u;
  }

  /// Les plannings sont enregistrés à part (boîte « plannings »).
  Map<String, dynamic> versJson() => {
        'id': _id,
        'estVisiteur': _estVisiteur,
        'nomComplet': _nomComplet,
        'email': _email,
        'motDePasseHache': _motDePasseHache,
        'dateInscription': _dateInscription?.toIso8601String(),
        'consentementSante': _consentementSante,
        'profil': _profil?.versJson(),
      };

  /// Remet les plannings relus depuis la base.
  void restaurerPlannings(List<PlanningSemaine> plannings) {
    _plannings
      ..clear()
      ..addAll(plannings);
  }
}
