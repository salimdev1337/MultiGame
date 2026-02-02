import 'dart:convert';
import 'sudoku_board.dart';
import 'sudoku_action.dart';
import '../logic/sudoku_generator.dart';

/// Model representing a saved (unfinished) Sudoku game.
///
/// This model captures the complete state of a game in progress,
/// allowing players to pause and resume their games later.
///
/// Supports both Classic and Rush modes.
class SavedGame {
  final String id; // Unique identifier for the saved game
  final String mode; // 'classic' or 'rush'
  final SudokuDifficulty difficulty;

  // Board state
  final SudokuBoard currentBoard;
  final SudokuBoard originalBoard;
  final SudokuBoard? solvedBoard;

  // Game progress
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;
  final int hintsRemaining;

  // Rush mode specific (null for classic mode)
  final int? remainingSeconds;
  final int? penaltiesApplied;

  // Selection state
  final int? selectedRow;
  final int? selectedCol;
  final bool notesMode;

  // Action history for undo
  final List<SudokuAction> actionHistory;

  // Metadata
  final DateTime savedAt;

  SavedGame({
    required this.id,
    required this.mode,
    required this.difficulty,
    required this.currentBoard,
    required this.originalBoard,
    this.solvedBoard,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.hintsRemaining,
    this.remainingSeconds,
    this.penaltiesApplied,
    this.selectedRow,
    this.selectedCol,
    required this.notesMode,
    required this.actionHistory,
    required this.savedAt,
  });

  /// Converts the saved game to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode,
      'difficulty': difficulty.name,
      'currentBoard': currentBoard.toJson(),
      'originalBoard': originalBoard.toJson(),
      'solvedBoard': solvedBoard?.toJson(),
      'elapsedSeconds': elapsedSeconds,
      'mistakes': mistakes,
      'hintsUsed': hintsUsed,
      'hintsRemaining': hintsRemaining,
      'remainingSeconds': remainingSeconds,
      'penaltiesApplied': penaltiesApplied,
      'selectedRow': selectedRow,
      'selectedCol': selectedCol,
      'notesMode': notesMode,
      'actionHistory': actionHistory.map((action) => action.toJson()).toList(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  /// Creates a saved game from JSON
  factory SavedGame.fromJson(Map<String, dynamic> json) {
    return SavedGame(
      id: json['id'] as String,
      mode: json['mode'] as String,
      difficulty: SudokuDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => SudokuDifficulty.medium,
      ),
      currentBoard: SudokuBoard.fromJson(json['currentBoard'] as Map<String, dynamic>),
      originalBoard: SudokuBoard.fromJson(json['originalBoard'] as Map<String, dynamic>),
      solvedBoard: json['solvedBoard'] != null
          ? SudokuBoard.fromJson(json['solvedBoard'] as Map<String, dynamic>)
          : null,
      elapsedSeconds: json['elapsedSeconds'] as int,
      mistakes: json['mistakes'] as int,
      hintsUsed: json['hintsUsed'] as int,
      hintsRemaining: json['hintsRemaining'] as int,
      remainingSeconds: json['remainingSeconds'] as int?,
      penaltiesApplied: json['penaltiesApplied'] as int?,
      selectedRow: json['selectedRow'] as int?,
      selectedCol: json['selectedCol'] as int?,
      notesMode: json['notesMode'] as bool,
      actionHistory: (json['actionHistory'] as List<dynamic>)
          .map((actionJson) => SudokuAction.fromJson(actionJson as Map<String, dynamic>))
          .toList(),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  /// Converts the saved game to a JSON string for storage
  String toJsonString() => jsonEncode(toJson());

  /// Creates a saved game from a JSON string
  factory SavedGame.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SavedGame.fromJson(json);
  }

  /// Creates a copy with updated fields
  SavedGame copyWith({
    String? id,
    String? mode,
    SudokuDifficulty? difficulty,
    SudokuBoard? currentBoard,
    SudokuBoard? originalBoard,
    SudokuBoard? solvedBoard,
    int? elapsedSeconds,
    int? mistakes,
    int? hintsUsed,
    int? hintsRemaining,
    int? remainingSeconds,
    int? penaltiesApplied,
    int? selectedRow,
    int? selectedCol,
    bool? notesMode,
    List<SudokuAction>? actionHistory,
    DateTime? savedAt,
  }) {
    return SavedGame(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      currentBoard: currentBoard ?? this.currentBoard,
      originalBoard: originalBoard ?? this.originalBoard,
      solvedBoard: solvedBoard ?? this.solvedBoard,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      penaltiesApplied: penaltiesApplied ?? this.penaltiesApplied,
      selectedRow: selectedRow ?? this.selectedRow,
      selectedCol: selectedCol ?? this.selectedCol,
      notesMode: notesMode ?? this.notesMode,
      actionHistory: actionHistory ?? this.actionHistory,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}
