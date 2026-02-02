import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multigame/providers/mixins/game_stats_mixin.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import '../models/sudoku_board.dart';
import '../models/sudoku_action.dart';
import '../models/saved_game.dart';
import '../models/completed_game.dart';
import '../logic/sudoku_generator.dart';
import '../logic/sudoku_validator.dart';
import '../logic/sudoku_solver.dart';
import '../services/sudoku_persistence_service.dart';
import '../services/sudoku_stats_service.dart';
import '../services/sudoku_sound_service.dart';
import '../services/sudoku_haptic_service.dart';

/// Provider for Sudoku Rush Mode game state and logic.
///
/// Rush Mode features:
/// - Countdown timer (5 minutes)
/// - Penalty system (-10 seconds per wrong entry)
/// - Time-based scoring (base score + time bonus)
/// - Lose condition when timer reaches zero
///
/// This provider follows the MultiGame architecture:
/// - Uses GameStatsMixin for Firebase score saving
/// - Injects services via GetIt dependency injection
/// - Separates game logic from UI state (UI state in SudokuUIProvider)
class SudokuRushProvider extends ChangeNotifier with GameStatsMixin {
  final FirebaseStatsService _statsService;
  final SudokuPersistenceService _persistenceService;
  final SudokuStatsService _sudokuStatsService;
  final SudokuSoundService _soundService;
  final SudokuHapticService _hapticService;

  @override
  FirebaseStatsService get statsService => _statsService;

  // Constants
  static const int initialTimeSeconds = 300; // 5 minutes
  static const int penaltySeconds = 10; // 10 seconds penalty per wrong entry

  // Game state
  SudokuBoard? _currentBoard;
  SudokuBoard? _originalBoard; // For reset functionality
  SudokuBoard? _solvedBoard; // Cached solution for hints
  SudokuDifficulty _difficulty = SudokuDifficulty.medium;

  // Selection state
  int? _selectedRow;
  int? _selectedCol;

  // Game progress
  int _mistakes = 0;
  int _hintsUsed = 0;
  int _hintsRemaining = 3;
  int _remainingSeconds = initialTimeSeconds;
  int _penaltiesApplied = 0;
  Timer? _timer;
  bool _isGameOver = false;
  bool _isVictory = false;
  bool _isDefeat = false;

  // Input mode
  bool _notesMode = false;

  // History for undo
  final List<SudokuAction> _actionHistory = [];

  // Settings
  bool _errorHighlightEnabled = true;

  // Generator
  late final SudokuGenerator _generator;

  // Penalty animation trigger
  bool _showPenalty = false;

  SudokuRushProvider({
    required FirebaseStatsService statsService,
    required SudokuPersistenceService persistenceService,
    required SudokuStatsService sudokuStatsService,
    required SudokuSoundService soundService,
    required SudokuHapticService hapticService,
  })  : _statsService = statsService,
        _persistenceService = persistenceService,
        _sudokuStatsService = sudokuStatsService,
        _soundService = soundService,
        _hapticService = hapticService {
    _generator = SudokuGenerator();
  }

  // Getters
  SudokuBoard? get currentBoard => _currentBoard;
  SudokuBoard? get originalBoard => _originalBoard;
  SudokuDifficulty get difficulty => _difficulty;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;
  int get hintsRemaining => _hintsRemaining;
  int get remainingSeconds => _remainingSeconds;
  int get penaltiesApplied => _penaltiesApplied;
  bool get isGameOver => _isGameOver;
  bool get isVictory => _isVictory;
  bool get isDefeat => _isDefeat;
  bool get notesMode => _notesMode;
  bool get errorHighlightEnabled => _errorHighlightEnabled;
  bool get canUndo => _actionHistory.isNotEmpty;
  bool get showPenalty => _showPenalty;
  bool get canErase =>
      _selectedRow != null &&
      _selectedCol != null &&
      _currentBoard != null &&
      !_currentBoard!.getCell(_selectedRow!, _selectedCol!).isFixed;

  int get score => _calculateScore();

  /// Formats remaining time as MM:SS
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Initializes a new Rush Mode game with the specified difficulty
  Future<void> initializeGame(SudokuDifficulty difficulty) async {
    _difficulty = difficulty;
    _isGameOver = false;
    _isVictory = false;
    _isDefeat = false;
    _mistakes = 0;
    _hintsUsed = 0;
    _hintsRemaining = 3;
    _remainingSeconds = initialTimeSeconds;
    _penaltiesApplied = 0;
    _selectedRow = null;
    _selectedCol = null;
    _notesMode = false;
    _showPenalty = false;
    _actionHistory.clear();
    _cancelTimer();

    // Generate puzzle
    await Future.delayed(const Duration(milliseconds: 100));
    _currentBoard = _generator.generate(difficulty);
    _originalBoard = _currentBoard!.clone();

    // Pre-solve for hint system
    _solvedBoard = SudokuSolver.getSolution(_currentBoard!);

    _startTimer();
    notifyListeners();
  }

  /// Resets the game to the original puzzle state
  void resetGame() {
    if (_originalBoard == null) return;

    _currentBoard = _originalBoard!.clone();
    _mistakes = 0;
    _hintsUsed = 0;
    _hintsRemaining = 3;
    _remainingSeconds = initialTimeSeconds;
    _penaltiesApplied = 0;
    _selectedRow = null;
    _selectedCol = null;
    _notesMode = false;
    _isGameOver = false;
    _isVictory = false;
    _isDefeat = false;
    _showPenalty = false;
    _actionHistory.clear();

    _cancelTimer();
    _startTimer();
    notifyListeners();
  }

  /// Starts the countdown timer
  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameOver) {
        _cancelTimer();
        return;
      }

      _remainingSeconds--;
      notifyListeners();

      // Check lose condition
      if (_remainingSeconds <= 0) {
        _handleDefeat();
      }
    });
  }

  /// Cancels the game timer
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Pauses the game timer
  void pauseTimer() {
    _cancelTimer();
    notifyListeners();
  }

  /// Resumes the game timer
  void resumeTimer() {
    if (!_isGameOver) {
      _startTimer();
    }
    notifyListeners();
  }

  /// Selects a cell at the specified position
  void selectCell(int row, int col) {
    if (_isGameOver) return;

    _selectedRow = row;
    _selectedCol = col;
    _soundService.playSelectCell();
    _hapticService.lightTap();
    notifyListeners();
  }

  /// Clears the current cell selection
  void clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  /// Places a number in the selected cell (or toggles note in notes mode)
  void placeNumber(int number) {
    if (_isGameOver ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentBoard == null) {
      return;
    }

    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);

    // Can't edit fixed cells
    if (cell.isFixed) {
      return;
    }

    if (_notesMode) {
      // Notes mode: toggle note
      _toggleNote(number);
    } else {
      // Value mode: place number
      _placeValue(number);
    }
  }

  /// Places a value in the selected cell
  void _placeValue(int number) {
    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);
    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    // Record action for undo
    _actionHistory.add(SudokuAction.setValue(
      row: _selectedRow!,
      col: _selectedCol!,
      value: number,
      previousValue: previousValue,
      previousNotes: previousNotes,
    ));

    // Set the value
    cell.value = number;
    cell.notes.clear(); // Clear notes when placing value

    // Validate and check for errors
    final hadErrors = _validateAndApplyPenalty();

    if (!hadErrors) {
      _soundService.playNumberEntry();
      _hapticService.mediumTap();
    }

    // Check win condition (only if no errors)
    if (!hadErrors && _checkWinCondition()) {
      _handleVictory();
    }

    notifyListeners();
  }

  /// Validates the board and applies penalty if there are errors
  /// Returns true if errors were found
  bool _validateAndApplyPenalty() {
    if (!_errorHighlightEnabled || _currentBoard == null) return false;

    // Clear all error flags first
    _currentBoard!.clearErrors();

    // Get positions with conflicts
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);

    if (conflicts.isNotEmpty) {
      // Mark conflicting cells as errors
      for (final position in conflicts) {
        final cell = _currentBoard!.getCell(position.row, position.col);
        cell.isError = true;

        // Increment mistakes for user-entered cells
        if (!cell.isFixed) {
          _mistakes++;
        }
      }

      // Apply time penalty in Rush Mode
      _applyTimePenalty();
      return true;
    }

    return false;
  }

  /// Applies a time penalty (-10 seconds) and triggers visual feedback
  void _applyTimePenalty() {
    _remainingSeconds = (_remainingSeconds - penaltySeconds).clamp(0, initialTimeSeconds);
    _penaltiesApplied++;

    _soundService.playError();
    _hapticService.errorShake();

    // Trigger penalty animation
    _showPenalty = true;
    notifyListeners();

    // Reset penalty flag after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      _showPenalty = false;
      notifyListeners();
    });

    // Check if time ran out due to penalty
    if (_remainingSeconds <= 0) {
      _handleDefeat();
    }
  }

  /// Toggles a note in the selected cell
  void _toggleNote(int number) {
    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);

    // Can't add notes to cells with values
    if (cell.hasValue) {
      return;
    }

    final previousNotes = Set<int>.from(cell.notes);

    if (cell.notes.contains(number)) {
      // Remove note
      _actionHistory.add(SudokuAction.removeNote(
        row: _selectedRow!,
        col: _selectedCol!,
        value: number,
        previousNotes: previousNotes,
      ));
      cell.notes.remove(number);
    } else {
      // Add note
      _actionHistory.add(SudokuAction.addNote(
        row: _selectedRow!,
        col: _selectedCol!,
        value: number,
        previousNotes: previousNotes,
      ));
      cell.notes.add(number);
    }

    notifyListeners();
  }

  /// Erases the selected cell
  void eraseCell() {
    if (_isGameOver ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentBoard == null) {
      return;
    }

    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);

    // Can't erase fixed cells
    if (cell.isFixed) {
      return;
    }

    // Record action for undo
    _actionHistory.add(SudokuAction.clearValue(
      row: _selectedRow!,
      col: _selectedCol!,
      previousValue: cell.value,
      previousNotes: Set<int>.from(cell.notes),
    ));

    // Clear cell
    cell.value = null;
    cell.notes.clear();
    cell.isError = false;

    // Re-validate board (no penalty for erasing)
    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    for (final position in conflicts) {
      _currentBoard!.getCell(position.row, position.col).isError = true;
    }

    _soundService.playErase();
    _hapticService.mediumTap();
    notifyListeners();
  }

  /// Toggles notes mode on/off
  void toggleNotesMode() {
    _notesMode = !_notesMode;
    _soundService.playNotesToggle();
    _hapticService.lightTap();
    notifyListeners();
  }

  /// Checks if the puzzle is solved correctly
  bool _checkWinCondition() {
    if (_currentBoard == null) return false;
    return SudokuValidator.isSolved(_currentBoard!);
  }

  /// Handles victory state
  void _handleVictory() {
    _isVictory = true;
    _isGameOver = true;
    _soundService.playVictory();
    _hapticService.successPattern();
    _cancelTimer();

    // Save score via GameStatsMixin
    _saveScore();

    // Record achievement
    _recordAchievement();

    // Save completed game and update stats
    _saveCompletedGame(victory: true);

    // Delete saved game (no longer needed)
    _persistenceService.deleteSavedGame('rush');
  }

  /// Handles defeat state (time ran out)
  void _handleDefeat() {
    _isDefeat = true;
    _isGameOver = true;
    _remainingSeconds = 0;
    _cancelTimer();

    // Save completed game as a loss
    _saveCompletedGame(victory: false);

    // Delete saved game (no longer needed)
    _persistenceService.deleteSavedGame('rush');

    notifyListeners();
  }

  /// Calculates the final Rush Mode score
  /// Base score + time bonus - penalties
  int _calculateScore() {
    const baseScore = 10000;

    // Time bonus: remaining seconds × 10 points
    final timeBonus = _remainingSeconds * 10;

    // Penalties
    final mistakePenalty = _mistakes * 100;
    final hintPenalty = _hintsUsed * 200;

    final score = (baseScore + timeBonus - mistakePenalty - hintPenalty).clamp(0, 20000);
    return score;
  }

  /// Saves score to Firebase
  void _saveScore() {
    final finalScore = _calculateScore();
    saveScore('sudoku_rush', finalScore);
  }

  /// Records achievement
  Future<void> _recordAchievement() async {
    // TODO: Implement Rush Mode specific achievements
    // Examples:
    // - First Rush Mode completion
    // - Complete with 4+ minutes remaining
    // - Complete without penalties
    // - Speed demon (under 3 minutes)
  }

  /// Uses a hint to reveal one cell
  void useHint() {
    if (_isGameOver ||
        _hintsRemaining <= 0 ||
        _currentBoard == null ||
        _solvedBoard == null) {
      return;
    }

    // Find all empty cells
    final emptyCells = <Position>[];
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cell = _currentBoard!.getCell(row, col);
        if (cell.isEmpty && !cell.isFixed) {
          emptyCells.add(Position(row, col));
        }
      }
    }

    if (emptyCells.isEmpty) {
      return; // No empty cells to hint
    }

    // Pick a random empty cell
    final randomIndex = _generator.hashCode % emptyCells.length;
    final hintPosition = emptyCells[randomIndex];

    // Get the correct value from solved board
    final correctValue = _solvedBoard!.getCell(hintPosition.row, hintPosition.col).value;

    if (correctValue == null) {
      return; // Safety check
    }

    // Record action for undo
    final cell = _currentBoard!.getCell(hintPosition.row, hintPosition.col);
    _actionHistory.add(SudokuAction.setValue(
      row: hintPosition.row,
      col: hintPosition.col,
      value: correctValue,
      previousValue: cell.value,
      previousNotes: Set<int>.from(cell.notes),
    ));

    // Place the hint value
    cell.value = correctValue;
    cell.notes.clear();
    cell.isError = false;

    // Decrement hints
    _hintsUsed++;
    _hintsRemaining--;

    // Select the hinted cell to show the player
    _selectedRow = hintPosition.row;
    _selectedCol = hintPosition.col;

    // Re-validate (no penalty for hints)
    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    for (final position in conflicts) {
      _currentBoard!.getCell(position.row, position.col).isError = true;
    }

    // Check win condition
    if (_checkWinCondition()) {
      _handleVictory();
    }

    notifyListeners();
    _soundService.playHint();
    _hapticService.doubleTap();
  }

  /// Undoes the last action
  void undo() {
    if (_actionHistory.isEmpty || _isGameOver || _currentBoard == null) {
      return;
    }

    final lastAction = _actionHistory.removeLast();
    final cell = _currentBoard!.getCell(lastAction.row, lastAction.col);

    switch (lastAction.type) {
      case SudokuActionType.setValue:
        // Restore previous value and notes
        cell.value = lastAction.previousValue;
        cell.notes.clear();
        if (lastAction.previousNotes != null) {
          cell.notes.addAll(lastAction.previousNotes!);
        }
        break;

      case SudokuActionType.clearValue:
        // Restore previous value and notes
        cell.value = lastAction.previousValue;
        cell.notes.clear();
        if (lastAction.previousNotes != null) {
          cell.notes.addAll(lastAction.previousNotes!);
        }
        break;

      case SudokuActionType.addNote:
        // Remove the note that was added
        if (lastAction.value != null) {
          cell.notes.remove(lastAction.value!);
        }
        break;

      case SudokuActionType.removeNote:
        // Re-add the note that was removed
        if (lastAction.value != null) {
          cell.notes.add(lastAction.value!);
        }
        break;
    }

    // Re-validate (no penalty for undo)
    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    for (final position in conflicts) {
      _currentBoard!.getCell(position.row, position.col).isError = true;
    }

    notifyListeners();
    _soundService.playUndo();
    _hapticService.mediumTap();
  }

  /// Toggles error highlighting on/off
  void toggleErrorHighlighting(bool enabled) {
    _errorHighlightEnabled = enabled;
    if (enabled) {
      _currentBoard!.clearErrors();
      final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
      for (final position in conflicts) {
        _currentBoard!.getCell(position.row, position.col).isError = true;
      }
    } else {
      _currentBoard?.clearErrors();
    }
    notifyListeners();
  }

  // ========== PERSISTENCE METHODS (Phase 4) ==========

  /// Saves the completed game to history and updates statistics
  Future<void> _saveCompletedGame({required bool victory}) async {
    if (_currentBoard == null) return;

    final completedGame = CompletedGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: 'rush',
      difficulty: _difficulty,
      score: victory ? _calculateScore() : 0,
      timeSeconds: _remainingSeconds,
      mistakes: _mistakes,
      hintsUsed: _hintsUsed,
      victory: victory,
      penaltiesApplied: _penaltiesApplied,
      completedAt: DateTime.now(),
    );

    // Save to history
    await _persistenceService.saveCompletedGame(completedGame);

    // Update statistics
    await _sudokuStatsService.recordGameCompletion(completedGame);

    // Update best score if applicable (only for victories)
    if (victory) {
      await _persistenceService.saveBestScore('rush', _difficulty, _calculateScore());
    }
  }

  /// Saves the current game state (auto-save)
  Future<void> saveGameState() async {
    if (_currentBoard == null || _originalBoard == null || _isGameOver) {
      return; // Don't save if no game in progress or game is over
    }

    final savedGame = SavedGame(
      id: 'rush_${_difficulty.name}',
      mode: 'rush',
      difficulty: _difficulty,
      currentBoard: _currentBoard!,
      originalBoard: _originalBoard!,
      solvedBoard: _solvedBoard,
      elapsedSeconds: initialTimeSeconds - _remainingSeconds, // Convert to elapsed
      mistakes: _mistakes,
      hintsUsed: _hintsUsed,
      hintsRemaining: _hintsRemaining,
      remainingSeconds: _remainingSeconds,
      penaltiesApplied: _penaltiesApplied,
      selectedRow: _selectedRow,
      selectedCol: _selectedCol,
      notesMode: _notesMode,
      actionHistory: List.from(_actionHistory),
      savedAt: DateTime.now(),
    );

    await _persistenceService.saveSavedGame(savedGame);
  }

  /// Loads a saved game state
  Future<bool> loadGameState() async {
    final savedGame = await _persistenceService.loadSavedGame('rush');

    if (savedGame == null) {
      return false;
    }

    // Restore game state
    _difficulty = savedGame.difficulty;
    _currentBoard = savedGame.currentBoard;
    _originalBoard = savedGame.originalBoard;
    _solvedBoard = savedGame.solvedBoard;
    _mistakes = savedGame.mistakes;
    _hintsUsed = savedGame.hintsUsed;
    _hintsRemaining = savedGame.hintsRemaining;
    _remainingSeconds = savedGame.remainingSeconds ?? initialTimeSeconds;
    _penaltiesApplied = savedGame.penaltiesApplied ?? 0;
    _selectedRow = savedGame.selectedRow;
    _selectedCol = savedGame.selectedCol;
    _notesMode = savedGame.notesMode;
    _actionHistory.clear();
    _actionHistory.addAll(savedGame.actionHistory);
    _isGameOver = false;
    _isVictory = false;
    _isDefeat = false;
    _showPenalty = false;

    // Restart timer
    _startTimer();

    notifyListeners();
    return true;
  }

  /// Checks if a saved game exists
  Future<bool> hasSavedGame() async {
    return await _persistenceService.hasSavedGame('rush');
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
