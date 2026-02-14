// Statistics model - see docs/SUDOKU_ARCHITECTURE.md

import 'dart:convert';
import '../logic/sudoku_generator.dart';

class SudokuStats {
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalTimePlayed;
  final int classicGamesPlayed;
  final int classicGamesWon;
  final int classicTotalTime;
  final Map<SudokuDifficulty, int> classicBestScores;
  final int rushGamesPlayed;
  final int rushGamesWon;
  final int rushGamesLost;
  final Map<SudokuDifficulty, int> rushBestScores;
  final int totalHintsUsed;
  final int totalMistakes;
  final DateTime? lastPlayedAt;

  SudokuStats({
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalTimePlayed = 0,
    this.classicGamesPlayed = 0,
    this.classicGamesWon = 0,
    this.classicTotalTime = 0,
    Map<SudokuDifficulty, int>? classicBestScores,
    this.rushGamesPlayed = 0,
    this.rushGamesWon = 0,
    this.rushGamesLost = 0,
    Map<SudokuDifficulty, int>? rushBestScores,
    this.totalHintsUsed = 0,
    this.totalMistakes = 0,
    this.lastPlayedAt,
  }) : classicBestScores = classicBestScores ?? {},
       rushBestScores = rushBestScores ?? {};

  double get winRate {
    if (totalGamesPlayed == 0) return 0.0;
    return totalGamesWon / totalGamesPlayed;
  }

  double get classicWinRate {
    if (classicGamesPlayed == 0) return 0.0;
    return classicGamesWon / classicGamesPlayed;
  }

  double get rushWinRate {
    if (rushGamesPlayed == 0) return 0.0;
    return rushGamesWon / rushGamesPlayed;
  }

  double get averageSolveTime {
    if (classicGamesWon == 0) return 0.0;
    return classicTotalTime / classicGamesWon;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesWon': totalGamesWon,
      'totalTimePlayed': totalTimePlayed,
      'classicGamesPlayed': classicGamesPlayed,
      'classicGamesWon': classicGamesWon,
      'classicTotalTime': classicTotalTime,
      'classicBestScores': classicBestScores.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'rushGamesPlayed': rushGamesPlayed,
      'rushGamesWon': rushGamesWon,
      'rushGamesLost': rushGamesLost,
      'rushBestScores': rushBestScores.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'totalHintsUsed': totalHintsUsed,
      'totalMistakes': totalMistakes,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }

  factory SudokuStats.fromJson(Map<String, dynamic> json) {
    return SudokuStats(
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalGamesWon: json['totalGamesWon'] as int? ?? 0,
      totalTimePlayed: json['totalTimePlayed'] as int? ?? 0,
      classicGamesPlayed: json['classicGamesPlayed'] as int? ?? 0,
      classicGamesWon: json['classicGamesWon'] as int? ?? 0,
      classicTotalTime: json['classicTotalTime'] as int? ?? 0,
      classicBestScores: _parseScoreMap(json['classicBestScores']),
      rushGamesPlayed: json['rushGamesPlayed'] as int? ?? 0,
      rushGamesWon: json['rushGamesWon'] as int? ?? 0,
      rushGamesLost: json['rushGamesLost'] as int? ?? 0,
      rushBestScores: _parseScoreMap(json['rushBestScores']),
      totalHintsUsed: json['totalHintsUsed'] as int? ?? 0,
      totalMistakes: json['totalMistakes'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
    );
  }

  static Map<SudokuDifficulty, int> _parseScoreMap(dynamic json) {
    if (json == null) return {};
    final map = json as Map<String, dynamic>;
    return Map.fromEntries(
      map.entries.map((e) {
        final difficulty = SudokuDifficulty.values.firstWhere(
          (d) => d.name == e.key,
          orElse: () => SudokuDifficulty.easy,
        );
        return MapEntry(difficulty, e.value as int);
      }),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SudokuStats.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SudokuStats.fromJson(json);
  }

  SudokuStats copyWith({
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? totalTimePlayed,
    int? classicGamesPlayed,
    int? classicGamesWon,
    int? classicTotalTime,
    Map<SudokuDifficulty, int>? classicBestScores,
    int? rushGamesPlayed,
    int? rushGamesWon,
    int? rushGamesLost,
    Map<SudokuDifficulty, int>? rushBestScores,
    int? totalHintsUsed,
    int? totalMistakes,
    DateTime? lastPlayedAt,
  }) {
    return SudokuStats(
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      totalTimePlayed: totalTimePlayed ?? this.totalTimePlayed,
      classicGamesPlayed: classicGamesPlayed ?? this.classicGamesPlayed,
      classicGamesWon: classicGamesWon ?? this.classicGamesWon,
      classicTotalTime: classicTotalTime ?? this.classicTotalTime,
      classicBestScores: classicBestScores ?? Map.from(this.classicBestScores),
      rushGamesPlayed: rushGamesPlayed ?? this.rushGamesPlayed,
      rushGamesWon: rushGamesWon ?? this.rushGamesWon,
      rushGamesLost: rushGamesLost ?? this.rushGamesLost,
      rushBestScores: rushBestScores ?? Map.from(this.rushBestScores),
      totalHintsUsed: totalHintsUsed ?? this.totalHintsUsed,
      totalMistakes: totalMistakes ?? this.totalMistakes,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return 'SudokuStats(played: $totalGamesPlayed, won: $totalGamesWon, '
        'winRate: ${(winRate * 100).toStringAsFixed(1)}%)';
  }
}
