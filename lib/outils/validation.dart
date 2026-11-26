// Vérifications de format faites sur le téléphone, avant tout envoi (séquence 1, message 3).
// Chaque message dit ce qui ne va pas et comment corriger (critère « gestion des erreurs »).

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[A-Za-z]{2,}$');

/// Message d'erreur pour une adresse e-mail, ou null si elle est valide.
String? erreurEmail(String valeur) {
  final v = valeur.trim();
  if (v.isEmpty) return 'Saisissez votre adresse e-mail.';
  if (_email.hasMatch(v)) return null;
  if (v.contains('@') && !v.split('@').last.contains('.')) {
    return 'Adresse incomplète : il manque la fin, par exemple @gmail.com.';
  }
  return 'Adresse invalide : elle doit ressembler à yasmine@gmail.com.';
}

/// Règle affichée avant la saisie : 8 caractères minimum, dont un chiffre.
String? erreurMotDePasse(String valeur) {
  if (valeur.length < 8) return 'Mot de passe trop court : 8 caractères minimum, dont un chiffre.';
  if (!valeur.contains(RegExp(r'\d'))) return 'Ajoutez au moins un chiffre, par exemple « soleil24 ».';
  return null;
}

String? erreurNom(String valeur) =>
    valeur.trim().length < 2 ? 'Saisissez votre prénom et votre nom.' : null;
