import 'package:flutter/material.dart';

/// Centralized design tokens for the Smart Nutrition & Health app.
///
/// Values were chosen to reflect Ethiopian health-and-nutrition brand
/// colours while remaining easy to override per-theme.
class AppTheme {
  AppTheme._();

  // --- Brand colours ---
  /// Primary green used in the dashboard chrome and primary CTAs.
  static const Color primaryGreen = Color(0xFF2E7D32);

  /// Secondary green for hover/press states.
  static const Color primaryGreenDark = Color(0xFF1B5E20);

  /// Accent orange used for the food-log quick-nav card.
  static const Color accentOrange = Color(0xFFEF6C00);

  /// Light surface background for all screens.
  static const Color scaffoldBackground = Color(0xFFF5F7F5);

  /// Card surface (slightly off-white) used for elevated content.
  static const Color cardSurface = Colors.white;

  // --- Glycemic-load status palette (kept in sync with _glColor) ---
  static const Color glLow = Color(0xFF2E7D32);       // green
  static const Color glModerate = Color(0xFFEF6C00);   // orange
  static const Color glExceeded = Color(0xFFC62828);   // red

  // --- Macro colour palette ---
  static const Color macroProtein = Color(0xFF1976D2); // blue
  static const Color macroCarbs = Color(0xFFEF6C00);   // orange
  static const Color macroFat = Color(0xFFE57373);     // soft red

  /// Builds a [ThemeData] using the brand tokens above.
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: base.textTheme.apply(fontFamilyFallback: const ['Noto Sans Ethiopic']),
    );
  }
}
