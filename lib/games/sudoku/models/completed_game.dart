import 'dart:convert';
import '../logic/sudoku_generator.dart';

/// Model representing a completed Sudoku game.
///
/// This model stores summary information about a finished game
/// for historical tracking and statistics.
///
/// Supports both Classic and Rush modes.
class CompletedGame {
  final String id; // Unique identifier
  final String mode; // 'classic' or 'rush'
  final SudokuDifficulty difficulty;

  // Game results
  final int score;
  final int timeSeconds; // Time taken or remaining time (for rush)
  final int mistakes;
  final int hintsUsed;
  final bool victory; // true if won, false if lost (rush mode timeout)

  // Rush mode specific (null for classic mode)
  final int? penaltiesApplied;

  // Metadata
  final DateTime completedAt;

  CompletedGame({
    required this.id,
    required this.mode,
    required this.difficulty,
    required this.score,
    required this.timeSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.victory,
    this.penaltiesApplied,
    required this.completedAt,
  });

  /// Converts the completed game to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode,
      'difficulty': difficulty.name,
      'score': score,
      'timeSeconds': timeSeconds,
      'mistakes': mistakes,
      'hintsUsed': hintsUsed,
      'victory': victory,
      'penaltiesApplied': penaltiesApplied,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  /// Creates a completed game from JSON
  factory CompletedGame.fromJson(Map<String, dynamic> json) {
    return CompletedGame(
      id: json['id'] as String,
      mode: json['mode'] as String,
      difficulty: SudokuDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => SudokuDifficulty.medium,
      ),
      score: json['score'] as int,
      timeSeconds: json['timeSeconds'] as int,
      mistakes: json['mistakes'] as int,
      hintsUsed: json['hintsUsed'] as int,
      victory: json['victory'] as bool,
      penaltiesApplied: json['penaltiesApplied'] as int?,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  /// Converts the completed game to a JSON string for storage
  String toJsonString() => jsonEncode(toJson());

  /// Creates a completed game from a JSON string
  factory CompletedGame.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CompletedGame.fromJson(json);
  }

  /// Creates a copy with updated fields
  CompletedGame copyWith({
    String? id,
    String? mode,
    SudokuDifficulty? difficulty,
    int? score,
    int? timeSeconds,
    int? mistakes,
    int? hintsUsed,
    bool? victory,
    int? penaltiesApplied,
    DateTime? completedAt,
  }) {
    return CompletedGame(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      score: score ?? this.score,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      victory: victory ?? this.victory,
      penaltiesApplied: penaltiesApplied ?? this.penaltiesApplied,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'CompletedGame(mode: $mode, difficulty: $difficulty, score: $score, '
        'time: $timeSeconds, victory: $victory)';
  }
}
