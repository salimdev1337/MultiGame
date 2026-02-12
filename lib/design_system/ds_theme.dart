/// Design System - Master Theme
/// Combines all design tokens into a cohesive ThemeData
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ds_colors.dart';
import 'ds_typography.dart';
import 'ds_spacing.dart';
import 'ds_shadows.dart';

/// Main theme builder
class DSTheme {
  DSTheme._(); // Private constructor

  /// Build dark theme (primary theme for MultiGame)
  static ThemeData buildDarkTheme() {
    return ThemeData.dark().copyWith(
      // ==========================================
      // Colors
      // ==========================================
      scaffoldBackgroundColor: DSColors.backgroundPrimary,
      primaryColor: DSColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: DSColors.primary,
        secondary: DSColors.secondary,
        surface: DSColors.surface,
        error: DSColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DSColors.textPrimary,
        onError: Colors.white,
      ),

      // ==========================================
      // Typography
      // ==========================================
      textTheme: buildTextTheme(),

      // ==========================================
      // App Bar
      // ==========================================
      appBarTheme: AppBarTheme(
        backgroundColor: DSColors.surface,
        elevation: DSShadows.elevation2,
        centerTitle: true,
        titleTextStyle: DSTypography.titleLarge,
        iconTheme: const IconThemeData(
          color: DSColors.textPrimary,
          size: DSSpacing.iconMedium,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: DSColors.backgroundPrimary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // ==========================================
      // Cards
      // ==========================================
      cardTheme: const CardThemeData(
        color: DSColors.surface,
        elevation: DSShadows.elevation2,
        shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusLG),
        margin: DSSpacing.paddingMD,
      ),

      // ==========================================
      // Buttons
      // ==========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.primary,
          foregroundColor: Colors.white,
          elevation: DSShadows.elevation2,
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.buttonHorizontal,
            vertical: DSSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusMD),
          textStyle: DSTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DSColors.primary,
          side: const BorderSide(
            color: DSColors.primary,
            width: DSSpacing.borderMedium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.buttonHorizontal,
            vertical: DSSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusMD),
          textStyle: DSTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DSColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.buttonHorizontal,
            vertical: DSSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusMD),
          textStyle: DSTypography.labelLarge,
        ),
      ),

      // ==========================================
      // Floating Action Button
      // ==========================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DSColors.primary,
        foregroundColor: Colors.white,
        elevation: DSShadows.elevation6,
        shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusLG),
      ),

      // ==========================================
      // Input Decoration
      // ==========================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DSColors.surface,
        border: OutlineInputBorder(
          borderRadius: DSSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: DSColors.textTertiary,
            width: DSSpacing.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DSSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: DSColors.textTertiary,
            width: DSSpacing.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DSSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: DSColors.primary,
            width: DSSpacing.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DSSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: DSColors.error,
            width: DSSpacing.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: DSSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: DSColors.error,
            width: DSSpacing.borderMedium,
          ),
        ),
        labelStyle: DSTypography.bodyMedium,
        hintStyle: DSTypography.bodySmall,
        contentPadding: DSSpacing.paddingMD,
      ),

      // ==========================================
      // Dialogs
      // ==========================================
      dialogTheme: DialogThemeData(
        backgroundColor: DSColors.surface,
        elevation: DSShadows.elevation16,
        shape: const RoundedRectangleBorder(
          borderRadius: DSSpacing.borderRadiusXL,
        ),
        titleTextStyle: DSTypography.titleLarge,
        contentTextStyle: DSTypography.bodyMedium,
      ),

      // ==========================================
      // Bottom Sheet
      // ==========================================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DSColors.surface,
        elevation: DSShadows.elevation8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DSSpacing.radiusXXL),
          ),
        ),
      ),

      // ==========================================
      // Snackbar
      // ==========================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DSColors.surfaceElevated,
        contentTextStyle: DSTypography.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusMD),
        behavior: SnackBarBehavior.floating,
        elevation: DSShadows.elevation4,
      ),

      // ==========================================
      // Progress Indicators
      // ==========================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DSColors.primary,
        linearTrackColor: DSColors.surfaceElevated,
        circularTrackColor: DSColors.surfaceElevated,
      ),

      // ==========================================
      // Divider
      // ==========================================
      dividerTheme: DividerThemeData(
        color: DSColors.withOpacity(DSColors.textTertiary, 0.2),
        thickness: DSSpacing.borderThin,
        space: DSSpacing.md,
      ),

      // ==========================================
      // Chips
      // ==========================================
      chipTheme: ChipThemeData(
        backgroundColor: DSColors.surfaceElevated,
        selectedColor: DSColors.primary,
        labelStyle: DSTypography.labelMedium,
        padding: DSSpacing.paddingXS,
        shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusSM),
      ),

      // ==========================================
      // Icon Theme
      // ==========================================
      iconTheme: const IconThemeData(
        color: DSColors.textPrimary,
        size: DSSpacing.iconMedium,
      ),

      // ==========================================
      // List Tiles
      // ==========================================
      listTileTheme: ListTileThemeData(
        tileColor: DSColors.surface,
        selectedTileColor: DSColors.withOpacity(DSColors.primary, 0.1),
        iconColor: DSColors.textSecondary,
        textColor: DSColors.textPrimary,
        contentPadding: DSSpacing.paddingMD,
        shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusMD),
      ),

      // ==========================================
      // Switches & Checkboxes
      // ==========================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return DSColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DSColors.primary;
          }
          return DSColors.surfaceElevated;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DSColors.primary;
          }
          return DSColors.surfaceElevated;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: DSSpacing.borderRadiusXS),
      ),

      // ==========================================
      // Tooltip
      // ==========================================
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: DSColors.surfaceHighlight,
          borderRadius: DSSpacing.borderRadiusSM,
          boxShadow: DSShadows.shadowMd,
        ),
        textStyle: DSTypography.bodySmall,
        padding: DSSpacing.paddingXS,
      ),

      // ==========================================
      // Tab Bar
      // ==========================================
      tabBarTheme: TabBarThemeData(
        labelColor: DSColors.primary,
        unselectedLabelColor: DSColors.textSecondary,
        labelStyle: DSTypography.labelLarge,
        unselectedLabelStyle: DSTypography.labelMedium,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: DSColors.primary,
            width: DSSpacing.borderThick,
          ),
        ),
      ),
    );
  }

  /// Build light theme (optional - not primary theme)
  static ThemeData buildLightTheme() {
    return buildDarkTheme();
  }

  /// System UI overlay style for dark theme
  static SystemUiOverlayStyle get darkSystemUiStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: DSColors.backgroundPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }

  /// System UI overlay style for light surfaces
  static SystemUiOverlayStyle get lightSystemUiStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  /// Build a theme with custom primary / secondary colours.
  ///
  /// Used by [ThemeProvider] to apply user-selected theme presets at runtime.
  /// Falls back to high-contrast palette when [highContrast] is true.
  static ThemeData buildDynamicTheme({
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    bool highContrast = false,
  }) {
    final effectivePrimary =
        highContrast ? DSColors.highContrastPrimary : primary;
    final effectiveSecondary =
        highContrast ? DSColors.highContrastSecondary : secondary;
    final effectiveBackground =
        highContrast ? DSColors.highContrastBackground : background;
    final effectiveSurface =
        highContrast ? DSColors.highContrastSurface : surface;
    final onSurface = highContrast ? DSColors.highContrastText : DSColors.textPrimary;

    return buildDarkTheme().copyWith(
      scaffoldBackgroundColor: effectiveBackground,
      primaryColor: effectivePrimary,
      colorScheme: ColorScheme.dark(
        primary: effectivePrimary,
        secondary: effectiveSecondary,
        surface: effectiveSurface,
        error: DSColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: effectiveSurface,
        elevation: DSShadows.elevation2,
        shape: const RoundedRectangleBorder(
          borderRadius: DSSpacing.borderRadiusLG,
        ),
        margin: DSSpacing.paddingMD,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectivePrimary,
          foregroundColor: Colors.white,
          elevation: DSShadows.elevation2,
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.buttonHorizontal,
            vertical: DSSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DSSpacing.borderRadiusMD,
          ),
          textStyle: DSTypography.labelLarge,
        ),
      ),
    );
  }
}
