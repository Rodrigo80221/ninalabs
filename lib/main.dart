import 'package:flutter/material.dart';
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
    );
  }
}
