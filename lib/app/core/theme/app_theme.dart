import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.terracotta,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.terracotta,
        secondary: AppColors.quartzPink,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textDark, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textLight, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.terracotta,
        unselectedLabelColor: AppColors.textLight,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.terracotta, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      useMaterial3: true,
    );
  }
}
