import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'demarrage.dart';
import 'ecrans/coquille_onglets.dart';
import 'ecrans/ecran_01_bienvenue.dart';
import 'ecrans/ecran_questionnaire.dart';
import 'theme/theme.dart';

/// L'application : les écrans n'accèdent qu'aux 4 contrôleurs (et aux données de référence).
class AppDbarti extends StatelessWidget {
  const AppDbarti({super.key, required this.dependances});
  final Dependances dependances;

  @override
  Widget build(BuildContext context) {
    final d = dependances;
    return MultiProvider(
      providers: [
        Provider.value(value: d.depot),
        ChangeNotifierProvider.value(value: d.auth),
        ChangeNotifierProvider.value(value: d.profil),
        ChangeNotifierProvider.value(value: d.planning),
        ChangeNotifierProvider.value(value: d.courses),
      ],
      child: MaterialApp(
        title: 'Dbarti',
        debugShowCheckedModeBanner: false,
        theme: themeDbarti(),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: _ecranDeDepart(d),
      ),
    );
  }

  /// Au lancement : bienvenue (01), questionnaire (04) si le profil est incomplet, sinon le planning (12).
  static Widget _ecranDeDepart(Dependances d) {
    final u = d.auth.utilisateurCourant;
    if (u == null) return const EcranBienvenue();
    if (!(u.profil?.estComplet() ?? false)) {
      d.profil.demarrer();
      return const EcranQuestionnaire();
    }
    return const CoquilleOnglets();
  }
}
