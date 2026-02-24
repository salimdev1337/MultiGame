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

  /// Memory Game colors
  static const Color memoryPrimary = Color(0xFF7c4dff);
  static const Color memoryAccent = Color(0xFFea80fc);

  /// Wordle game colors
  static const Color wordlePrimary = Color(0xFF538D4E);
  static const Color wordleAccent = Color(0xFFB59F3B);

  /// Connect Four colors
  static const Color connectFourPrimary = Color(0xFF1565C0); // board blue
  static const Color connectFourAccent = Color(0xFFFFD700);  // player 1 yellow
  static const Color connectFourPlayer1 = Color(0xFFFFD700); // yellow
  static const Color connectFourPlayer2 = Color(0xFFE53935); // red

  /// Ludo colors
  static const Color ludoPrimary      = Color(0xFFE91E63);
  static const Color ludoAccent       = Color(0xFFFFEB3B);
  static const Color ludoPlayerRed    = Color(0xFFE53935);
  static const Color ludoPlayerBlue   = Color(0xFF2196F3);
  static const Color ludoPlayerGreen  = Color(0xFF43A047);
  static const Color ludoPlayerYellow = Color(0xFFFFD700);
  static const Color ludoBgTop        = Color(0xFF090912); // scaffold & gradient start
  static const Color ludoBgBottom     = Color(0xFF14142A); // gradient end (dark blue)

  /// RPG — Shadowfall Chronicles colors
  static const Color rpgPrimary = Color(0xFFCC2200); // blood red
  static const Color rpgAccent  = Color(0xFFFFD700);  // gold

  /// Rummy game colors
  static const Color rummyPrimary  = Color(0xFF00897B); // teal-green (felt)
  static const Color rummyAccent   = Color(0xFFFFD700); // gold
  static const Color rummyFelt     = Color(0xFF1B5E20); // dark green table
  static const Color rummyCardFace = Color(0xFFFFF8E7); // cream
  static const Color rummyCardBack = Color(0xFF1A237E); // deep navy back
  static const Color rummySuitRed  = Color(0xFFD32F2F); // hearts/diamonds

  /// Bomberman game colors
  // Floor — near-black stone tiles
  static const Color bombermanBg        = Color(0xFF08090d); // overall canvas fill
  static const Color bombermanFloorA    = Color(0xFF0d1018); // tile shade A
  static const Color bombermanFloorB    = Color(0xFF0a0d14); // tile shade B (checker)
  static const Color bombermanGrout     = Color(0xFF050608); // grout line between tiles
  // Walls — concrete/stone blocks, clearly lighter than floor
  static const Color bombermanWall      = Color(0xFF52606e); // wall face (mid stone-gray)
  static const Color bombermanWallTop   = Color(0xFF8fa0b0); // top-left bevel (lit face)
  static const Color bombermanWallBevel = Color(0xFF38454f); // bottom-right shadow edge
  // Destructible blocks — wood/brick (unchanged hue, slightly warmer)
  static const Color bombermanBlock          = Color(0xFF7a3e28);
  static const Color bombermanBlockHighlight = Color(0xFF9c5235);
  static const Color bombermanFuse = Color(0xFFff8c00);
  static const Color bombermanExplosionCenter = Color(0xFFff4500);
  static const Color bombermanExplosionOuter = Color(0xFFffd700);
  // Player colours — P1/P3 reuse DSColors.primary/memoryPrimary; P2/P4 are unique
  static const Color bombermanP2 = Color(0xFFffd700);
  static const Color bombermanP4 = Color(0xFFff6b35);

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
    colors: [Color(0x33FFFFFF), Color(0x1AFFFFFF)],
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
    return color.withValues(alpha: opacity);
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
      case 'memory_game':
        return memoryPrimary;
      case 'wordle':
        return wordlePrimary;
      case 'connect_four':
        return connectFourPrimary;
      case 'ludo':
        return ludoPrimary;
      case 'rpg':
        return rpgPrimary;
      case 'rummy':
        return rummyPrimary;
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

  // ==========================================
  // High Contrast Mode Colors (WCAG AAA)
  // ==========================================

  /// High contrast background - Pure black
  static const Color highContrastBackground = Color(0xFF000000);

  /// High contrast surface - Very dark gray
  static const Color highContrastSurface = Color(0xFF1a1a1a);

  /// High contrast surface elevated
  static const Color highContrastSurfaceElevated = Color(0xFF2a2a2a);

  /// High contrast text - Pure white
  static const Color highContrastText = Color(0xFFFFFFFF);

  /// High contrast text secondary
  static const Color highContrastTextSecondary = Color(0xFFE0E0E0);

  /// High contrast primary - Brighter cyan
  static const Color highContrastPrimary = Color(0xFF00E5FF);

  /// High contrast secondary - Brighter orange
  static const Color highContrastSecondary = Color(0xFFFF7020);

  /// High contrast success - Brighter green
  static const Color highContrastSuccess = Color(0xFF00FF88);

  /// High contrast error - Brighter red
  static const Color highContrastError = Color(0xFFFF5566);

  /// High contrast warning - Brighter yellow
  static const Color highContrastWarning = Color(0xFFFFBB00);

  /// High contrast info - Brighter blue
  static const Color highContrastInfo = Color(0xFF6666FF);

  // ==========================================
  // Accessibility Methods
  // ==========================================

  /// Get color for accessibility mode
  /// If high contrast is enabled, returns the high contrast variant
  /// Otherwise returns the standard color
  static Color getAccessibleColor(
    Color standardColor,
    bool highContrast, {
    Color? highContrastVariant,
  }) {
    if (!highContrast) return standardColor;

    // Return provided high contrast variant if available
    if (highContrastVariant != null) return highContrastVariant;

    // Map standard colors to high contrast equivalents
    if (standardColor == primary) return highContrastPrimary;
    if (standardColor == secondary) return highContrastSecondary;
    if (standardColor == success) return highContrastSuccess;
    if (standardColor == error) return highContrastError;
    if (standardColor == warning) return highContrastWarning;
    if (standardColor == info) return highContrastInfo;
    if (standardColor == backgroundPrimary) return highContrastBackground;
    if (standardColor == surface) return highContrastSurface;
    if (standardColor == surfaceElevated) return highContrastSurfaceElevated;
    if (standardColor == textPrimary) return highContrastText;
    if (standardColor == textSecondary) return highContrastTextSecondary;

    // Default: boost color brightness
    return _boostColorBrightness(standardColor, 1.3);
  }

  /// Get background color based on accessibility settings
  static Color getBackgroundColor(bool highContrast) {
    return highContrast ? highContrastBackground : backgroundPrimary;
  }

  /// Get surface color based on accessibility settings
  static Color getSurfaceColor(bool highContrast) {
    return highContrast ? highContrastSurface : surface;
  }

  /// Get text color based on accessibility settings
  static Color getTextColor(bool highContrast) {
    return highContrast ? highContrastText : textPrimary;
  }

  /// Get primary color based on accessibility settings
  static Color getPrimaryColor(bool highContrast) {
    return highContrast ? highContrastPrimary : primary;
  }

  /// Boost color brightness for high contrast mode
  static Color _boostColorBrightness(Color color, double factor) {
    final hslColor = HSLColor.fromColor(color);
    final boostedLightness = (hslColor.lightness * factor).clamp(0.0, 1.0);
    return hslColor.withLightness(boostedLightness).toColor();
  }

  /// Create high contrast gradient
  static LinearGradient getAccessibleGradient(
    LinearGradient standardGradient,
    bool highContrast,
  ) {
    if (!highContrast) return standardGradient;

    return LinearGradient(
      colors: standardGradient.colors
          .map((c) => getAccessibleColor(c, true))
          .toList(),
      begin: standardGradient.begin,
      end: standardGradient.end,
      stops: standardGradient.stops,
    );
  }
}
