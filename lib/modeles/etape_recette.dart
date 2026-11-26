/// EtapeRecette — une consigne du mode cuisine, dans l'ordre {ordonnées}.
class EtapeRecette {
  EtapeRecette({required int ordre, required String instruction, int? dureeMinuteur})
      : _ordre = ordre,
        _instruction = instruction,
        _dureeMinuteur = dureeMinuteur;

  final int _ordre;
  final String _instruction;
  final int? _dureeMinuteur; // [0..1], en minutes

  int get ordre => _ordre;
  String get instruction => _instruction;
  int? get dureeMinuteur => _dureeMinuteur;

  factory EtapeRecette.depuisJson(Map<String, dynamic> j) => EtapeRecette(
        ordre: j['ordre'] as int,
        instruction: j['instruction'] as String,
        dureeMinuteur: j['dureeMinuteur'] as int?,
      );

  Map<String, dynamic> versJson() =>
      {'ordre': _ordre, 'instruction': _instruction, 'dureeMinuteur': _dureeMinuteur};
}
