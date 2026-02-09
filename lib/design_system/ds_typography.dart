/// Design System - Typography Tokens
/// Centralized text styles using Google Fonts
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ds_colors.dart';

/// Typography system with predefined text styles
class DSTypography {
  DSTypography._(); // Private constructor

  // ==========================================
  // Font Families
  // ==========================================

  /// Headers and display text - Poppins
  static String get displayFontFamily => 'Poppins';

  /// Body and UI text - Inter
  static String get bodyFontFamily => 'Inter';

  // ==========================================
  // Display Styles (Extra Large)
  // ==========================================

  /// Display Large - 57sp (Hero titles)
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
    height: 1.12,
    color: DSColors.textPrimary,
  );

  /// Display Medium - 45sp (Page titles)
  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.16,
    color: DSColors.textPrimary,
  );

  /// Display Small - 36sp (Section headers)
  static TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.22,
    color: DSColors.textPrimary,
  );

  // ==========================================
  // Headline Styles
  // ==========================================

  /// Headline Large - 32sp
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: DSColors.textPrimary,
  );

  /// Headline Medium - 28sp
  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    color: DSColors.textPrimary,
  );

  /// Headline Small - 24sp
  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: DSColors.textPrimary,
  );

  // ==========================================
  // Title Styles
  // ==========================================

  /// Title Large - 22sp (Card titles, dialog headers)
  static TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
    color: DSColors.textPrimary,
  );

  /// Title Medium - 16sp (List titles)
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    color: DSColors.textPrimary,
  );

  /// Title Small - 14sp (Small titles)
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: DSColors.textPrimary,
  );

  // ==========================================
  // Body Styles
  // ==========================================

  /// Body Large - 16sp (Regular content)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: DSColors.textPrimary,
  );

  /// Body Medium - 14sp (Default body text)
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: DSColors.textSecondary,
  );

  /// Body Small - 12sp (Captions, metadata)
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: DSColors.textTertiary,
  );

  // ==========================================
  // Label Styles (Buttons, Tags)
  // ==========================================

  /// Label Large - 14sp (Button text)
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: DSColors.textPrimary,
  );

  /// Label Medium - 12sp (Tabs, chips)
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: DSColors.textPrimary,
  );

  /// Label Small - 11sp (Overlines, timestamps)
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: DSColors.textTertiary,
  );

  // ==========================================
  // Specialized Styles
  // ==========================================

  /// Button Text - Bold, uppercase
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.25,
    color: DSColors.textPrimary,
  );

  /// Number Display (Scores, timers) - Monospace
  static TextStyle numberDisplay = GoogleFonts.robotoMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.0,
    color: DSColors.primary,
  );

  /// Code/Debug - Monospace
  static TextStyle code = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: DSColors.success,
  );

  /// Error Text
  static TextStyle error = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: DSColors.error,
  );

  // ==========================================
  // Game-Specific Styles
  // ==========================================

  /// Sudoku cell number
  static TextStyle sudokuNumber = GoogleFonts.robotoMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.0,
    color: DSColors.textPrimary,
  );

  /// 2048 tile number
  static TextStyle tile2048Number = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.0,
    color: DSColors.textPrimary,
  );

  // ==========================================
  // Utility Methods
  // ==========================================

  /// Create custom text style with specific color
  static TextStyle withColor(TextStyle base, Color color) {
    return base.copyWith(color: color);
  }

  /// Create bold variant
  static TextStyle bold(TextStyle base) {
    return base.copyWith(fontWeight: FontWeight.w700);
  }

  /// Create italic variant
  static TextStyle italic(TextStyle base) {
    return base.copyWith(fontStyle: FontStyle.italic);
  }

  /// Create underlined variant
  static TextStyle underlined(TextStyle base) {
    return base.copyWith(decoration: TextDecoration.underline);
  }

  /// Create gradient text style (requires ShaderMask)
  static TextStyle withGradient(TextStyle base, Gradient gradient) {
    return base.copyWith(
      foreground: Paint()
        ..shader = gradient.createShader(
          const Rect.fromLTWH(0, 0, 200, 70),
        ),
    );
  }

  /// Apply shadow to text
  static TextStyle withShadow(
    TextStyle base, {
    Color shadowColor = DSColors.primary,
    double blurRadius = 10.0,
  }) {
    return base.copyWith(
      shadows: [
        Shadow(
          color: shadowColor,
          blurRadius: blurRadius,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

/// Text theme for MaterialApp
TextTheme buildTextTheme() {
  return TextTheme(
    displayLarge: DSTypography.displayLarge,
    displayMedium: DSTypography.displayMedium,
    displaySmall: DSTypography.displaySmall,
    headlineLarge: DSTypography.headlineLarge,
    headlineMedium: DSTypography.headlineMedium,
    headlineSmall: DSTypography.headlineSmall,
    titleLarge: DSTypography.titleLarge,
    titleMedium: DSTypography.titleMedium,
    titleSmall: DSTypography.titleSmall,
    bodyLarge: DSTypography.bodyLarge,
    bodyMedium: DSTypography.bodyMedium,
    bodySmall: DSTypography.bodySmall,
    labelLarge: DSTypography.labelLarge,
    labelMedium: DSTypography.labelMedium,
    labelSmall: DSTypography.labelSmall,
  );
}
