/// Horloge de l'application. Les tests la remplacent pour fixer « aujourd'hui ».
DateTime Function() maintenant = DateTime.now;

/// Date sans l'heure.
DateTime jourSeul(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lundi de la semaine qui contient [d] (semaine du lundi au dimanche).
DateTime lundiDe(DateTime d) => jourSeul(d).subtract(Duration(days: d.weekday - 1));

bool memeJour(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
