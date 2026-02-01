import 'package:flutter/material.dart';

/// Interface for game metadata
/// Each game should implement this to register itself with the GameRegistry
abstract class GameDefinition {
  /// Unique identifier for the game (e.g., 'puzzle', '2048', 'snake')
  String get id;

  /// Display name shown in UI
  String get displayName;

  /// Short description of the game
  String get description;

  /// Icon representing the game
  IconData get icon;

  /// Route name for navigation
  String get route;

  /// Whether the game is currently available/implemented
  bool get isAvailable;

  /// Color theme for the game (optional)
  Color? get color;

  /// Category for grouping games (e.g., 'puzzle', 'arcade', 'strategy')
  String get category;

  /// Minimum score/moves for statistics (optional)
  int? get minScore;

  /// Maximum score/moves for statistics (optional)
  int? get maxScore;

  /// Create a widget for the game screen
  Widget createScreen();
}

/// Base implementation with sensible defaults
abstract class BaseGameDefinition implements GameDefinition {
  @override
  bool get isAvailable => true;

  @override
  Color? get color => null;

  @override
  String get category => 'general';

  @override
  int? get minScore => null;

  @override
  int? get maxScore => null;
}
