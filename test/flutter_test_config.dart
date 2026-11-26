import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices (Poppins, Inter, icônes Lucide) avant les tests :
/// la mise en page testée est celle du téléphone, pas celle de la police de test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final poppins = FontLoader('Poppins');
  for (final g in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    poppins.addFont(rootBundle.load('assets/polices/Poppins-$g.ttf'));
  }
  await poppins.load();
  await (FontLoader('Inter')..addFont(rootBundle.load('assets/polices/Inter.ttf'))).load();
  await (FontLoader('packages/lucide_icons_flutter/Lucide')
        ..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf')))
      .load();
  await testMain();
}
