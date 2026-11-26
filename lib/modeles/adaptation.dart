import 'enumerations.dart';

/// Adaptation — ce qu'on change dans la méthode d'une recette pour un repas
/// (« Sans mixeur »). La recette ne change pas : seule la méthode est adaptée.
///
/// Écart documenté avec le diagramme : deux attributs privés facultatifs,
/// [ordreEtape] et [instruction], pour que le mode cuisine (écran 15) affiche
/// la consigne adaptée à la bonne étape.
class Adaptation {
  Adaptation({
    required TypeAdaptation type,
    required String description,
    int? ordreEtape,
    String? instruction,
    String? conseil,
  })  : _type = type,
        _description = description,
        _ordreEtape = ordreEtape,
        _instruction = instruction,
        _conseil = conseil;

  final TypeAdaptation _type;
  final String _description;
  final int? _ordreEtape;
  final String? _instruction;
  final String? _conseil;

  TypeAdaptation get type => _type;
  String get description => _description;
  int? get ordreEtape => _ordreEtape;
  String? get instruction => _instruction;
  String? get conseil => _conseil;

  factory Adaptation.depuisJson(Map<String, dynamic> j) => Adaptation(
        type: enumDepuisNom(TypeAdaptation.values, j['type'] as String),
        description: j['description'] as String,
        ordreEtape: j['ordreEtape'] as int?,
        instruction: j['instruction'] as String?,
        conseil: j['conseil'] as String?,
      );

  Map<String, dynamic> versJson() => {
        'type': _type.name,
        'description': _description,
        'ordreEtape': _ordreEtape,
        'instruction': _instruction,
        'conseil': _conseil,
      };
}
