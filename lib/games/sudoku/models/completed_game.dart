// Completed game model - see docs/SUDOKU_ARCHITECTURE.md

import 'dart:convert';
import '../logic/sudoku_generator.dart';

class CompletedGame {
  final String id;
  final String mode;
  final SudokuDifficulty difficulty;
  final int score;
  final int timeSeconds;
  final int mistakes;
  final int hintsUsed;
  final bool victory;
  final int? penaltiesApplied;
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

  String toJsonString() => jsonEncode(toJson());

  factory CompletedGame.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CompletedGame.fromJson(json);
  }

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
