import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hachage des mots de passe : PBKDF2-HMAC-SHA256, sel aléatoire de 16 octets.
/// On ne stocke que « pbkdf2-sha256$itérations$sel$empreinte », jamais le mot de passe.
const iterationsPbkdf2 = 10000;

String hacherMotDePasse(String motDePasse, {List<int>? sel, int iterations = iterationsPbkdf2}) {
  final s = sel ?? List<int>.generate(16, (_) => Random.secure().nextInt(256));
  final empreinte = _pbkdf2(utf8.encode(motDePasse), s, iterations, 32);
  return ['pbkdf2-sha256', '$iterations', base64.encode(s), base64.encode(empreinte)].join(r'$');
}

bool verifierMotDePasse(String motDePasse, String stocke) {
  final parties = stocke.split(r'$');
  if (parties.length != 4 || parties[0] != 'pbkdf2-sha256') return false;
  final iterations = int.parse(parties[1]);
  final sel = base64.decode(parties[2]);
  final attendu = base64.decode(parties[3]);
  final calcule = _pbkdf2(utf8.encode(motDePasse), sel, iterations, attendu.length);
  // Comparaison en temps constant.
  var difference = 0;
  for (var i = 0; i < attendu.length; i++) {
    difference |= attendu[i] ^ calcule[i];
  }
  return difference == 0;
}

List<int> _pbkdf2(List<int> motDePasse, List<int> sel, int iterations, int longueur) {
  final hmac = Hmac(sha256, motDePasse);
  final resultat = <int>[];
  for (var bloc = 1; resultat.length < longueur; bloc++) {
    var u = hmac.convert([...sel, bloc >> 24 & 0xff, bloc >> 16 & 0xff, bloc >> 8 & 0xff, bloc & 0xff]).bytes;
    final t = List<int>.of(u);
    for (var k = 1; k < iterations; k++) {
      u = hmac.convert(u).bytes;
      for (var b = 0; b < t.length; b++) {
        t[b] ^= u[b];
      }
    }
    resultat.addAll(t);
  }
  return resultat.sublist(0, longueur);
}

/// Identifiant unique simple (horodatage + aléa).
String nouvelIdentifiant() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 30).toRadixString(36)}';
