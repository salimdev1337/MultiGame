/// Design System - Color Tokens
/// Centralized color definitions for consistent theming
library;

import 'package:flutter/material.dart';

/// Primary color palette
class DSColors {
  DSColors._(); // Private constructor to prevent instantiation

  // ==========================================
  // Primary Brand Colors
  // ==========================================

  /// Primary cyan - Main brand color
  static const Color primary = Color(0xFF00d4ff);
  static const Color primaryLight = Color(0xFF33ddff);
  static const Color primaryDark = Color(0xFF00a3cc);

  /// Secondary orange - Accent color
  static const Color secondary = Color(0xFFff5c00);
  static const Color secondaryLight = Color(0xFFff8533);
  static const Color secondaryDark = Color(0xFFcc4a00);

  // ==========================================
  // Neutral Colors (Dark Theme)
  // ==========================================

  /// Background colors
  static const Color backgroundPrimary = Color(0xFF16181d);
  static const Color backgroundSecondary = Color(0xFF0f1115);
  static const Color backgroundTertiary = Color(0xFF050505);

  /// Surface colors
  static const Color surface = Color(0xFF21242b);
  static const Color surfaceElevated = Color(0xFF2a2d35);
  static const Color surfaceHighlight = Color(0xFF33363f);

  /// Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textDisabled = Color(0xFF4D4D4D);

  // ==========================================
  // Semantic Colors
  // ==========================================

  /// Success states
  static const Color success = Color(0xFF19e6a2);
  static const Color successLight = Color(0xFF4dedb8);
  static const Color successDark = Color(0xFF14b882);

  /// Error states
  static const Color error = Color(0xFFff4757);
  static const Color errorLight = Color(0xFFff6b79);
  static const Color errorDark = Color(0xFFcc3946);

  /// Warning states
  static const Color warning = Color(0xFFffa502);
  static const Color warningLight = Color(0xFFffb735);
  static const Color warningDark = Color(0xFFcc8402);

  /// Info states
  static const Color info = Color(0xFF5352ed);
  static const Color infoLight = Color(0xFF7574f1);
  static const Color infoDark = Color(0xFF4241be);

  // ==========================================
  // Game-Specific Colors
  // ==========================================

  /// Sudoku game colors
  static const Color sudokuPrimary = primary;
  static const Color sudokuAccent = Color(0xFF8b5cf6);

  /// 2048 game colors
  static const Color game2048Primary = success;
  static const Color game2048Accent = Color(0xFFf59e0b);

  /// Snake game colors
  static const Color snakePrimary = Color(0xFF34d399);
  static const Color snakeAccent = Color(0xFFfbbf24);

  /// Puzzle game colors
  static const Color puzzlePrimary = Color(0xFFec4899);
  static const Color puzzleAccent = Color(0xFFa78bfa);

  /// Infinite Runner colors
  static const Color runnerPrimary = Color(0xFFf97316);
  static const Color runnerAccent = Color(0xFFeab308);

  // ==========================================
  // Gradient Definitions
  // ==========================================

  /// Primary gradient (Cyan → Secondary)
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [successDark, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error gradient
  static const LinearGradient gradientError = LinearGradient(
    colors: [errorDark, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium gold gradient (for VIP/achievements)
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFffd700), Color(0xFFffa500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glassmorphic overlay gradient
  static const LinearGradient gradientGlass = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x1AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================
  // Overlay Colors
  // ==========================================

  /// Scrim overlays for modals
  static const Color scrimLight = Color(0x66000000);
  static const Color scrimDark = Color(0x99000000);

  /// Shimmer effect colors
  static const Color shimmerBase = Color(0xFF1a1d24);
  static const Color shimmerHighlight = Color(0xFF2a2d35);

  // ==========================================
  // Rarity Colors (for achievements)
  // ==========================================

  static const Color rarityCommon = Color(0xFF9ca3af);
  static const Color rarityRare = Color(0xFF60a5fa);
  static const Color rarityEpic = Color(0xFFa78bfa);
  static const Color rarityLegendary = Color(0xFFfbbf24);

  // ==========================================
  // Utility Methods
  // ==========================================

  /// Get color with custom opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity * 255);
  }

  /// Get game-specific color
  static Color getGameColor(String gameId) {
    switch (gameId) {
      case 'sudoku':
        return sudokuPrimary;
      case '2048':
        return game2048Primary;
      case 'snake_game':
        return snakePrimary;
      case 'image_puzzle':
        return puzzlePrimary;
      case 'infinite_runner':
        return runnerPrimary;
      default:
        return primary;
    }
  }

  /// Get achievement rarity color
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return rarityCommon;
      case 'rare':
        return rarityRare;
      case 'epic':
        return rarityEpic;
      case 'legendary':
        return rarityLegendary;
      default:
        return rarityCommon;
    }
  }
}
