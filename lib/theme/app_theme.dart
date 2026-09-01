import 'package:flutter/material.dart';

/// LiveScreen's central theme file.
/// Every color, font, and spacing value used across the app
/// should come from here, so the whole app stays visually consistent.
class AppColors {
  // Core cinematic dark palette
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF16161D);
  static const Color surfaceElevated = Color(0xFF1E1E28);

  // Brand accent — a warm cinematic gold, used sparingly for emphasis
  static const Color accent = Color(0xFFE8B94A);
  static const Color accentSoft = Color(0xFF8C6D2F);

  // A cool secondary accent, used for "live/energy" highlights
  static const Color electricBlue = Color(0xFF4AC8E8);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA0A0AC);
  static const Color textMuted = Color(0xFF6B6B76);

  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);

  // Seat map states
  static const Color seatAvailable = Color(0xFF2A2A35);
  static const Color seatSelected = Color(0xFFE8B94A);
  static const Color seatBooked = Color(0xFF3A3A44);
  static const Color seatPremium = Color(0xFFB388FF);
  static const Color seatRecliner = Color(0xFF4AC8E8);
}

class AppTextStyles {
  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.electricBlue,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineSmall: AppTextStyles.heading,
        titleMedium: AppTextStyles.subheading,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      useMaterial3: true,
    );
  }
}
