import 'enumerations.dart';

/// Equipement — un appareil de cuisine (diagramme : compte et profil).
class Equipement {
  Equipement({required TypeEquipement type, String? libelle})
      : _type = type,
        _libelle = libelle ?? type.libelle;

  final TypeEquipement _type;
  final String _libelle;

  TypeEquipement get type => _type;
  String get libelle => _libelle;

  @override
  bool operator ==(Object other) => other is Equipement && other._type == _type;

  @override
  int get hashCode => _type.hashCode;
}
