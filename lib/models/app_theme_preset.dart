import 'package:flutter/material.dart';

/// Available theme presets for the app
enum ThemePreset {
  defaultTheme,
  ocean,
  sunset,
  forest,
  neon,
}

/// A complete colour theme preset with gradients and palette.
class AppThemePreset {
  const AppThemePreset({
    required this.preset,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.gradient,
    required this.background,
    required this.surface,
  });

  final ThemePreset preset;
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final LinearGradient gradient;
  final Color background;
  final Color surface;

  // ── Predefined presets ───────────────────────────────────────────────────

  static const AppThemePreset defaultTheme = AppThemePreset(
    preset: ThemePreset.defaultTheme,
    name: 'Default',
    description: 'Cyan & orange — the classic MultiGame look',
    primary: Color(0xFF00d4ff),
    secondary: Color(0xFFff6b35),
    gradient: LinearGradient(
      colors: [Color(0xFF00d4ff), Color(0xFF0077ff)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    background: Color(0xFF16181d),
    surface: Color(0xFF21242b),
  );

  static const AppThemePreset ocean = AppThemePreset(
    preset: ThemePreset.ocean,
    name: 'Ocean',
    description: 'Deep blue & teal — calming ocean vibes',
    primary: Color(0xFF00b4d8),
    secondary: Color(0xFF0096c7),
    gradient: LinearGradient(
      colors: [Color(0xFF00b4d8), Color(0xFF023e8a)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    background: Color(0xFF03045e),
    surface: Color(0xFF0a0e2e),
  );

  static const AppThemePreset sunset = AppThemePreset(
    preset: ThemePreset.sunset,
    name: 'Sunset',
    description: 'Orange & pink — warm sunset energy',
    primary: Color(0xFFff6b35),
    secondary: Color(0xFFf72585),
    gradient: LinearGradient(
      colors: [Color(0xFFff6b35), Color(0xFFf72585)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    background: Color(0xFF1a0a0a),
    surface: Color(0xFF2d1015),
  );

  static const AppThemePreset forest = AppThemePreset(
    preset: ThemePreset.forest,
    name: 'Forest',
    description: 'Green & brown — earthy natural tones',
    primary: Color(0xFF52b788),
    secondary: Color(0xFF95d5b2),
    gradient: LinearGradient(
      colors: [Color(0xFF52b788), Color(0xFF1b4332)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    background: Color(0xFF081c15),
    surface: Color(0xFF1b4332),
  );

  static const AppThemePreset neon = AppThemePreset(
    preset: ThemePreset.neon,
    name: 'Neon',
    description: 'Purple & magenta — electric cyberpunk glow',
    primary: Color(0xFFb14aed),
    secondary: Color(0xFFff00ff),
    gradient: LinearGradient(
      colors: [Color(0xFFb14aed), Color(0xFF6600cc)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    background: Color(0xFF0d001a),
    surface: Color(0xFF1a0033),
  );

  static List<AppThemePreset> get allThemes => const [
        defaultTheme,
        ocean,
        sunset,
        forest,
        neon,
      ];

  static AppThemePreset fromPreset(ThemePreset preset) =>
      allThemes.firstWhere((t) => t.preset == preset);
}
