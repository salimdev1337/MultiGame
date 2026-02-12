/// Design System - Accessibility Tokens
/// Accessibility constants and utilities for WCAG AA compliance
library;

import 'package:flutter/material.dart';
import 'ds_colors.dart';

/// Accessibility tokens and helper utilities
class DSAccessibility {
  DSAccessibility._(); // Private constructor

  // ==========================================
  // Touch Target Sizes
  // ==========================================

  /// Minimum touch target size (WCAG 2.5.5)
  static const double minTouchTarget = 48.0;

  /// Recommended touch target size for better accessibility
  static const double recommendedTouchTarget = 56.0;

  /// Minimum spacing between touch targets
  static const double minTouchTargetSpacing = 8.0;

  // ==========================================
  // High Contrast Mode
  // ==========================================

  /// Color contrast boost multiplier for high contrast mode
  static const double highContrastBoost = 1.3;

  /// Minimum contrast ratio for normal text (WCAG AA)
  static const double minContrastNormal = 4.5;

  /// Minimum contrast ratio for large text (WCAG AA)
  static const double minContrastLarge = 3.0;

  // ==========================================
  // Font Scaling
  // ==========================================

  /// Minimum font scale factor
  static const double minFontScale = 0.8;

  /// Maximum font scale factor
  static const double maxFontScale = 2.0;

  /// Default font scale
  static const double defaultFontScale = 1.0;

  // ==========================================
  // Reduced Motion
  // ==========================================

  /// Animation duration multiplier for reduced motion mode
  /// Animations are shortened to 30% of original duration
  static const double reducedMotionMultiplier = 0.3;

  /// Minimum animation duration (even with reduced motion)
  static const Duration minAnimationDuration = Duration(milliseconds: 50);

  // ==========================================
  // Focus Indicators
  // ==========================================

  /// Focus indicator border width
  static const double focusBorderWidth = 3.0;

  /// Focus indicator color
  static const Color focusColor = DSColors.primary;

  /// Focus indicator offset
  static const double focusOffset = 2.0;

  // ==========================================
  // Semantic Label Builders
  // ==========================================

  /// Build semantic label for game card
  /// Example: "Play Sudoku, played 25 times"
  static String gameCardLabel(String gameName, int playCount) {
    return 'Play $gameName, played $playCount ${playCount == 1 ? 'time' : 'times'}';
  }

  /// Build semantic label for achievement
  /// Example: "First Win achievement, unlocked" or "Speed Demon achievement, locked"
  static String achievementLabel(String name, bool unlocked) {
    return '$name achievement, ${unlocked ? 'unlocked' : 'locked'}';
  }

  /// Build semantic label for leaderboard rank
  /// Example: "Rank 3, John Doe, 5000 points"
  static String leaderboardRankLabel(int rank, String playerName, int score) {
    return 'Rank $rank, $playerName, $score ${score == 1 ? 'point' : 'points'}';
  }

  /// Build semantic label for score display
  /// Example: "Score: 5000 points"
  static String scoreLabel(int score) {
    return 'Score: $score ${score == 1 ? 'point' : 'points'}';
  }

  /// Build semantic label for timer
  /// Example: "Time remaining: 2 minutes 30 seconds"
  static String timerLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0 && remainingSeconds > 0) {
      return 'Time: $minutes ${minutes == 1 ? 'minute' : 'minutes'} $remainingSeconds ${remainingSeconds == 1 ? 'second' : 'seconds'}';
    } else if (minutes > 0) {
      return 'Time: $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'Time: $seconds ${seconds == 1 ? 'second' : 'seconds'}';
    }
  }

  /// Build semantic label for streak counter
  /// Example: "Current streak: 5 days"
  static String streakLabel(int days) {
    return 'Current streak: $days ${days == 1 ? 'day' : 'days'}';
  }

  /// Build semantic label for progress indicator
  /// Example: "Progress: 75 percent complete"
  static String progressLabel(double progress) {
    final percent = (progress * 100).round();
    return 'Progress: $percent percent complete';
  }

  /// Build semantic label for level/XP
  /// Example: "Level 5, 750 out of 1000 experience points to next level"
  static String levelLabel(int level, int currentXP, int xpToNext) {
    return 'Level $level, $currentXP out of $xpToNext experience points to next level';
  }

  /// Build semantic label for online status
  /// Example: "Player John is online" or "Player Jane was last seen 2 hours ago"
  static String onlineStatusLabel(String playerName, bool isOnline, {String? lastSeen}) {
    if (isOnline) {
      return '$playerName is online';
    } else if (lastSeen != null) {
      return '$playerName was last seen $lastSeen';
    } else {
      return '$playerName is offline';
    }
  }

  // ==========================================
  // Utility Methods
  // ==========================================

  /// Calculate contrast ratio between two colors
  /// Returns a value between 1 (no contrast) and 21 (maximum contrast)
  static double calculateContrastRatio(Color foreground, Color background) {
    final luminance1 = _relativeLuminance(foreground);
    final luminance2 = _relativeLuminance(background);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if color combination meets WCAG AA standards
  /// textSize: 'normal' (14-18pt) or 'large' (>=18pt or >=14pt bold)
  static bool meetsWCAGAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = calculateContrastRatio(foreground, background);
    final minimumRatio = isLargeText ? minContrastLarge : minContrastNormal;
    return ratio >= minimumRatio;
  }

  /// Get relative luminance of a color (WCAG formula)
  static double _relativeLuminance(Color color) {
    final r = _sRGBtoLinear(color.r);
    final g = _sRGBtoLinear(color.g);
    final b = _sRGBtoLinear(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Convert sRGB color component to linear RGB
  static double _sRGBtoLinear(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return ((value + 0.055) / 1.055).pow(2.4);
    }
  }

  /// Apply font scale to text style
  static TextStyle applyFontScale(TextStyle style, double scale) {
    return style.copyWith(
      fontSize: (style.fontSize ?? 14.0) * scale.clamp(minFontScale, maxFontScale),
    );
  }

  /// Calculate animation duration with reduced motion support
  static Duration calculateDuration(Duration standard, bool reducedMotion) {
    if (!reducedMotion) return standard;

    final reducedDuration = Duration(
      milliseconds: (standard.inMilliseconds * reducedMotionMultiplier).round(),
    );

    // Ensure minimum duration
    return reducedDuration.inMilliseconds < minAnimationDuration.inMilliseconds
        ? minAnimationDuration
        : reducedDuration;
  }

  /// Ensure minimum touch target size
  static double ensureMinTouchTarget(double size) {
    return size < minTouchTarget ? minTouchTarget : size;
  }

  /// Build focus indicator decoration
  static BoxDecoration buildFocusIndicator({
    Color color = focusColor,
    double borderWidth = focusBorderWidth,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      border: Border.all(
        color: color,
        width: borderWidth,
      ),
      borderRadius: borderRadius,
    );
  }

  /// Announce to screen reader (via Semantics with live region)
  static void announce(BuildContext context, String message) {
    // This will be picked up by screen readers
    Semantics(
      liveRegion: true,
      label: message,
      child: const SizedBox.shrink(),
    );
  }
}

/// Extension on Duration for reduced motion support
extension DurationAccessibility on Duration {
  /// Get duration with reduced motion applied
  Duration withReducedMotion(bool reducedMotion) {
    return DSAccessibility.calculateDuration(this, reducedMotion);
  }
}

/// Extension on double for exponentiation (pow)
extension DoubleExtension on double {
  double pow(double exponent) {
    return this < 0
        ? -1 * ((-this).abs().pow(exponent))
        : this == 0
            ? 0
            : exponent == 0
                ? 1
                : this * pow(exponent - 1);
  }
}
