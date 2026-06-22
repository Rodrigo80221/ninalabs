import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'app/core/theme/app_theme.dart';
import 'app/modules/dashboard/dashboard_page.dart';

void main() {
  runApp(const NinaLabsApp());
}

class NinaLabsApp extends StatelessWidget {
  const NinaLabsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nina Labs',
      theme: AppTheme.lightTheme,
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
    );
  }
}
