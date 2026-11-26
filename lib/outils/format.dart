// Formats tunisiens et français : dinars à 3 décimales, milliers séparés par une espace.

const _espace = '\u00A0';

/// 55.83 → « 55,830 DT » ; avec [unite] à faux : « 55,830 ».
String formaterDT(double montant, {bool unite = true, bool signe = false}) {
  final millimes = (montant * 1000).round();
  final negatif = millimes < 0;
  final abs = millimes.abs();
  final dinars = _milliers(abs ~/ 1000);
  final reste = (abs % 1000).toString().padLeft(3, '0');
  final prefixe = negatif ? '−' : (signe ? '+' : '');
  return '$prefixe$dinars,$reste${unite ? '${_espace}DT' : ''}';
}

/// 2090 → « 2 090 ».
String formaterEntier(int n) => _milliers(n);

String _milliers(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '−' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(_espace);
    b.write(s[i]);
  }
  return b.toString();
}

/// Quantité lisible : 1000 g → « 1 kg », 250 g → « 250 g », 1.5 pièce → « 1,5 pièce ».
String formaterQuantite(double quantite, String unite) {
  String nombre(double v) {
    final arrondi = (v * 10).round() / 10;
    return arrondi == arrondi.roundToDouble()
        ? arrondi.toInt().toString()
        : arrondi.toString().replaceAll('.', ',');
  }

  if (unite == 'g' && quantite >= 1000) return '${nombre(quantite / 1000)} kg';
  if (unite == 'ml' && quantite >= 1000) return '${nombre(quantite / 1000)} L';
  if (unite == 'pièce' || unite == 'pot') {
    final pluriel = quantite > 1 ? 's' : '';
    return '${nombre(quantite)} $unite$pluriel';
  }
  return '${nombre(quantite)} $unite';
}

const joursCourts = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const joursLongs = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Semaine du 17 au 23 novembre → « 17 – 23 novembre » (ou « 29 décembre – 4 janvier »).
String formaterSemaine(DateTime lundi) {
  final dimanche = lundi.add(const Duration(days: 6));
  if (lundi.month == dimanche.month) {
    return '${lundi.day} – ${dimanche.day} ${mois[dimanche.month - 1]}';
  }
  return '${lundi.day} ${mois[lundi.month - 1]} – ${dimanche.day} ${mois[dimanche.month - 1]}';
}

/// « lundi 17 »
String formaterJour(DateTime d) => '${joursLongs[d.weekday - 1]} ${d.day}';

/// Minutes et secondes : 600 → « 10:00 ».
String formaterMinuteur(int secondes) =>
    '${(secondes ~/ 60).toString().padLeft(2, '0')}:${(secondes % 60).toString().padLeft(2, '0')}';
