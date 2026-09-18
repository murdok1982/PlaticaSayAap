import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ads/ad_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  runApp(const ProviderScope(child: PlaticaSayApp()));
}

class PlaticaSayApp extends StatelessWidget {
  const PlaticaSayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platica-Say',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      supportedLocales: const [
        Locale('es'), Locale('en'), Locale('zh'), Locale('ar'),
        Locale('pt'), Locale('fr'), Locale('de'), Locale('ru'),
        Locale('hi'), Locale('ja'), Locale('it'), Locale('ko'),
        Locale('tr'), Locale('vi'), Locale('id'),
      ],
      home: const HomeScreen(),
    );
  }
}
