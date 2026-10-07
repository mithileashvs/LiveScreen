import 'package:flutter/material.dart';

/// Central Design System for LiveScreen's Customer-Facing Experience.
///
/// Implements the premium, dark cinematic aesthetic specified in the design guide:
/// - PRIMARY: Deep pure black / near-black surfaces
/// - ACCENTS: Metallic warm gold (#D4AF37 / #E5A93C) and deep burgundy (#9E102F / #8B0D23)
/// - TEXT: Off-white / crisp white primary (#F7F5F0) and muted grey secondary (#9CA3AF)
/// - STYLE: Sophisticated, clean, immersive, entertainment-focused
class CustomerColors {
  // Deep Cinematic Dark Surfaces
  static const Color background = Color(0xFF08080A);
  static const Color surface = Color(0xFF101116);
  static const Color surfaceCard = Color(0xFF16171E);
  static const Color surfaceElevated = Color(0xFF1C1E27);
  static const Color surfaceHighlight = Color(0xFF232532);

  // Metallic Warm Gold Accents
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE5B869);
  static const Color goldDark = Color(0xFFB8893C);
  static const Color goldMuted = Color(0x33D4AF37);
  static const Color goldSubtle = Color(0x1AD4AF37);

  // Deep Rich Burgundy Accents (Active states, primary CTAs)
  static const Color burgundy = Color(0xFF9E102F);
  static const Color burgundyDark = Color(0xFF700914);
  static const Color burgundyLight = Color(0xFFB91C1C);
  static const Color burgundyMuted = Color(0x339E102F);

  // Typography & Text
  static const Color textPrimary = Color(0xFFF7F5F0);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Borders & Dividers (Warm Metallic Gold & Burgundy Accents)
  static const Color borderSubtle = Color(0x2BD4AF37); // Subtle metallic dark gold (~17% opacity)
  static const Color borderMedium = Color(0x4DD4AF37); // Medium gold tint (~30% opacity)
  static const Color borderGold = Color(0x80D4AF37);   // Pronounced metallic gold (~50% opacity)
  static const Color borderGoldSubtle = Color(0x33D4AF37); // Light gold border (~20% opacity)
  static const Color borderBurgundy = Color(0x999E102F); // Rich burgundy border (~60% opacity)
  static const Color borderBurgundySubtle = Color(0x449E102F); // Subtle burgundy border (~27% opacity)

  // Seat Selection Map States (Pure Cinema Palette)
  static const Color seatAvailable = Color(0xFF6B7280); // Neutral Grey
  static const Color seatSelected = Color(0xFFD4AF37);  // Metallic Warm Gold (strictly NOT red)
  static const Color seatBooked = Color(0xFF1E212B);    // Black / very dark

  // Status & Utility
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

class CustomerTextStyles {
  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: CustomerColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: CustomerColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: CustomerColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CustomerColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CustomerColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CustomerColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}

final ThemeData customerDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: CustomerColors.background,
  canvasColor: CustomerColors.surface,
  cardColor: CustomerColors.surfaceCard,
  primaryColor: CustomerColors.burgundy,
  colorScheme: const ColorScheme.dark(
    primary: CustomerColors.burgundy,
    secondary: CustomerColors.gold,
    surface: CustomerColors.surfaceCard,
  ),
  dividerColor: CustomerColors.borderSubtle,
  fontFamily: CustomerTextStyles.fontFamily,
);
