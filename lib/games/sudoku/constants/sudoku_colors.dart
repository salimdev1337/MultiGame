import 'package:flutter/material.dart';

/// Centralized color constants for Sudoku game
///
/// All colors used across Sudoku screens, widgets, and components.
/// Organized by category for easy maintenance and consistency.
class SudokuColors {
  // Private constructor to prevent instantiation
  SudokuColors._();

  // ==================== BASE THEME COLORS ====================

  /// Very dark navy background
  static const backgroundDark = Color(0xFF0f1115);

  /// Dark gray surface color
  static const surfaceDark = Color(0xFF1a1d24);

  /// Slightly lighter surface color for elevated elements
  static const surfaceLighter = Color(0xFF2a2e36);

  // ==================== ACCENT COLORS ====================

  /// Primary cyan accent (Classic mode theme)
  static const primaryCyan = Color(0xFF00d4ff);

  /// Danger red (Rush mode theme, errors)
  static const dangerRed = Color(0xFFef4444);

  /// Warning orange
  static const warningOrange = Color(0xFFfb923c);

  /// Accent blue (Online mode theme)
  static const accentBlue = Color(0xFF3b82f6);

  // ==================== DIFFICULTY COLORS ====================

  /// Easy difficulty - Green
  static const easyColor = Color(0xFF4ade80);

  /// Medium difficulty - Yellow
  static const mediumColor = Color(0xFFfbbf24);

  /// Hard difficulty - Orange
  static const hardColor = Color(0xFFfb923c);

  /// Expert difficulty - Red
  static const expertColor = Color(0xFFef4444);

  // ==================== TEXT COLORS ====================

  /// Primary text color - White
  static const textWhite = Colors.white;

  /// Secondary text color - Gray
  static const textGray = Color(0xFF9ca3af);

  /// Tertiary text color - Darker gray
  static const textGrayDark = Color(0xFF64748b);

  /// Light gray text
  static const textGrayLight = Color(0xFF94a3b8);

  // ==================== MODE GRADIENTS ====================

  /// Classic mode gradient (Cyan)
  static const classicGradient = [Color(0xFF00d4ff), Color(0xFF0099cc)];

  /// Rush mode gradient (Orange to Red)
  static const rushGradient = [Color(0xFFfbbf24), Color(0xFFef4444)];

  /// Online mode gradient (Blue to Purple)
  static const onlineGradient = [Color(0xFF3b82f6), Color(0xFF8b5cf6)];

  // ==================== CELL COLORS (Game Grid) ====================

  /// Fixed cell background (pre-filled clues)
  static const cellFixed = Color(0xFF2a2e36);

  /// Selected cell background
  static const cellSelected = Color(0xFF00d4ff);

  /// Related cell background (same row/column/box)
  static const cellRelated = Color(0xFF1e2937);

  /// Error cell background
  static const cellError = Color(0xFFef4444);

  /// Cell border color
  static const cellBorder = Color(0xFF374151);

  /// Thick border color (3x3 boxes)
  static const cellBorderThick = Color(0xFF4b5563);

  // ==================== STATUS COLORS ====================

  /// Success/correct color
  static const success = Color(0xFF10b981);

  /// Info color
  static const info = Color(0xFF3b82f6);

  /// Warning color
  static const warning = Color(0xFFf59e0b);

  /// Error color
  static const error = Color(0xFFef4444);
}
