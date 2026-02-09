/// Design System - Shadow & Elevation Tokens
/// Consistent shadow definitions for depth perception
library;

import 'package:flutter/material.dart';
import 'ds_colors.dart';

/// Shadow and elevation system
class DSShadows {
  DSShadows._(); // Private constructor

  // ==========================================
  // Elevation Levels (Material Design)
  // ==========================================

  /// Level 0 - No elevation
  static const double elevationNone = 0.0;

  /// Level 1 - Slight elevation (cards at rest)
  static const double elevation1 = 1.0;

  /// Level 2 - Low elevation (raised buttons)
  static const double elevation2 = 2.0;

  /// Level 3 - Medium elevation (FABs, snackbars)
  static const double elevation3 = 3.0;

  /// Level 4 - High elevation (app bars)
  static const double elevation4 = 4.0;

  /// Level 6 - Very high elevation (dialogs)
  static const double elevation6 = 6.0;

  /// Level 8 - Extreme elevation (navigation drawer)
  static const double elevation8 = 8.0;

  /// Level 12 - Modal elevation
  static const double elevation12 = 12.0;

  /// Level 16 - Highest elevation (modals on modals)
  static const double elevation16 = 16.0;

  // ==========================================
  // BoxShadow Presets (Custom Shadows)
  // ==========================================

  /// Subtle shadow - Level 1
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Standard shadow - Level 2
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Pronounced shadow - Level 3
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Large shadow - Level 4
  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Huge shadow - Level 6
  static List<BoxShadow> get shadowXxl => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.25),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.15),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  /// Massive shadow - Level 8
  static List<BoxShadow> get shadowXxxl => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.3),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ==========================================
  // Colored Shadows (Brand Colors)
  // ==========================================

  /// Primary color glow
  static List<BoxShadow> get shadowPrimary => [
    BoxShadow(
      color: DSColors.withOpacity(DSColors.primary, 0.3),
      blurRadius: 20,
      offset: const Offset(0, 5),
    ),
    BoxShadow(
      color: DSColors.withOpacity(DSColors.primary, 0.1),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  /// Secondary color glow
  static List<BoxShadow> get shadowSecondary => [
    BoxShadow(
      color: DSColors.withOpacity(DSColors.secondary, 0.3),
      blurRadius: 20,
      offset: const Offset(0, 5),
    ),
    BoxShadow(
      color: DSColors.withOpacity(DSColors.secondary, 0.1),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  /// Success color glow
  static List<BoxShadow> get shadowSuccess => [
    BoxShadow(
      color: DSColors.withOpacity(DSColors.success, 0.3),
      blurRadius: 20,
      offset: const Offset(0, 5),
    ),
  ];

  /// Error color glow
  static List<BoxShadow> get shadowError => [
    BoxShadow(
      color: DSColors.withOpacity(DSColors.error, 0.3),
      blurRadius: 20,
      offset: const Offset(0, 5),
    ),
  ];

  /// Warning color glow
  static List<BoxShadow> get shadowWarning => [
    BoxShadow(
      color: DSColors.withOpacity(DSColors.warning, 0.3),
      blurRadius: 20,
      offset: const Offset(0, 5),
    ),
  ];

  // ==========================================
  // Inner Shadows (Inset Effects)
  // ==========================================

  /// Inner shadow for pressed states
  static List<BoxShadow> get shadowInner => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  // ==========================================
  // Glassmorphic Effects
  // ==========================================

  /// Glassmorphic border
  static BoxDecoration get glassBorder => BoxDecoration(
    border: Border.all(
      color: DSColors.withOpacity(Colors.white, 0.1),
      width: 1.5,
    ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        DSColors.withOpacity(Colors.white, 0.15),
        DSColors.withOpacity(Colors.white, 0.05),
      ],
    ),
  );

  /// Glassmorphic shadow
  static List<BoxShadow> get glassshadow => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.white, 0.1),
      blurRadius: 10,
      offset: const Offset(-5, -5),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.3),
      blurRadius: 15,
      offset: const Offset(5, 5),
    ),
  ];

  // ==========================================
  // Neumorphic Effects
  // ==========================================

  /// Neumorphic raised
  static List<BoxShadow> get neumorphicRaised => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.white, 0.05),
      blurRadius: 10,
      offset: const Offset(-5, -5),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.3),
      blurRadius: 10,
      offset: const Offset(5, 5),
    ),
  ];

  /// Neumorphic pressed (inset)
  static List<BoxShadow> get neumorphicPressed => [
    BoxShadow(
      color: DSColors.withOpacity(Colors.black, 0.3),
      blurRadius: 8,
      offset: const Offset(-3, -3),
    ),
    BoxShadow(
      color: DSColors.withOpacity(Colors.white, 0.05),
      blurRadius: 8,
      offset: const Offset(3, 3),
    ),
  ];

  // ==========================================
  // Text Shadows
  // ==========================================

  /// Subtle text shadow
  static List<Shadow> get textShadowSm => [
    Shadow(
      color: DSColors.withOpacity(Colors.black, 0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Standard text shadow
  static List<Shadow> get textShadowMd => [
    Shadow(
      color: DSColors.withOpacity(Colors.black, 0.5),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  /// Large text shadow
  static List<Shadow> get textShadowLg => [
    Shadow(
      color: DSColors.withOpacity(Colors.black, 0.6),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Glow text shadow (colored)
  static List<Shadow> textShadowGlow(Color color) => [
    Shadow(
      color: DSColors.withOpacity(color, 0.5),
      blurRadius: 20,
      offset: Offset.zero,
    ),
    Shadow(
      color: DSColors.withOpacity(color, 0.3),
      blurRadius: 10,
      offset: Offset.zero,
    ),
  ];

  // ==========================================
  // Utility Methods
  // ==========================================

  /// Create custom shadow with color
  static List<BoxShadow> custom({
    required Color color,
    double opacity = 0.3,
    double blurRadius = 20,
    Offset offset = const Offset(0, 5),
  }) {
    return [
      BoxShadow(
        color: DSColors.withOpacity(color, opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }

  /// Create layered shadows
  static List<BoxShadow> layered({
    required Color color,
    int layers = 2,
    double baseBlur = 10,
    double baseOpacity = 0.2,
  }) {
    return List.generate(layers, (index) {
      final multiplier = index + 1;
      return BoxShadow(
        color: DSColors.withOpacity(color, baseOpacity / multiplier),
        blurRadius: baseBlur * multiplier,
        offset: Offset(0, 2.0 * multiplier),
      );
    });
  }

  /// Get shadow by elevation level
  static List<BoxShadow> byElevation(double elevation) {
    if (elevation <= 1) return shadowSm;
    if (elevation <= 2) return shadowMd;
    if (elevation <= 4) return shadowLg;
    if (elevation <= 6) return shadowXl;
    if (elevation <= 8) return shadowXxl;
    return shadowXxxl;
  }

  /// Get game-specific shadow
  static List<BoxShadow> forGame(String gameId) {
    final color = DSColors.getGameColor(gameId);
    return custom(color: color, opacity: 0.3, blurRadius: 20);
  }
}
