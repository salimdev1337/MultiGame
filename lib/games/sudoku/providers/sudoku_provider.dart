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

/// Main provider for Sudoku Classic Mode game state and logic.
///
/// This provider manages all game state following the MultiGame architecture:
/// - Uses GameStatsMixin for Firebase score saving
/// - Injects services via GetIt dependency injection
/// - Separates game logic from UI state (UI state in SudokuUIProvider)
///
/// State includes:
/// - Current board and game progress
/// - Player selections and input mode
/// - Mistakes, hints, timer
/// - Action history for undo
class SudokuProvider extends ChangeNotifier with GameStatsMixin {
  final FirebaseStatsService _statsService;
  final SudokuPersistenceService _persistenceService;
  final SudokuStatsService _sudokuStatsService;
  final SudokuSoundService _soundService;
  final SudokuHapticService _hapticService;

  @override
  FirebaseStatsService get statsService => _statsService;

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
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isGameOver = false;
  bool _isVictory = false;

  // Input mode
  bool _notesMode = false;

  // History for undo
  final List<SudokuAction> _actionHistory = [];

  // Settings
  bool _errorHighlightEnabled = true;

  // Generator
  late final SudokuGenerator _generator;

  SudokuProvider({
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
  int get elapsedSeconds => _elapsedSeconds;
  bool get isGameOver => _isGameOver;
  bool get isVictory => _isVictory;
  bool get notesMode => _notesMode;
  bool get errorHighlightEnabled => _errorHighlightEnabled;
  bool get canUndo => _actionHistory.isNotEmpty;
  bool get canErase =>
      _selectedRow != null &&
      _selectedCol != null &&
      _currentBoard != null &&
      !_currentBoard!.getCell(_selectedRow!, _selectedCol!).isFixed;

  int get score => _calculateScore();

  /// Formats elapsed time as MM:SS
  String get formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Initializes a new game with the specified difficulty
  Future<void> initializeGame(SudokuDifficulty difficulty) async {
    _difficulty = difficulty;
    _isGameOver = false;
    _isVictory = false;
    _mistakes = 0;
    _hintsUsed = 0;
    _hintsRemaining = 3;
    _elapsedSeconds = 0;
    _selectedRow = null;
    _selectedCol = null;
    _notesMode = false;
    _actionHistory.clear();
    _cancelTimer();

    // Generate puzzle (this may take a moment for Expert difficulty)
    await Future.delayed(const Duration(milliseconds: 100)); // Allow UI to show loading
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
    _elapsedSeconds = 0;
    _selectedRow = null;
    _selectedCol = null;
    _notesMode = false;
    _isGameOver = false;
    _isVictory = false;
    _actionHistory.clear();

    _cancelTimer();
    _startTimer();
    notifyListeners();
  }

  /// Starts the game timer
  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameOver) {
        _cancelTimer();
        return;
      }
      _elapsedSeconds++;
      notifyListeners();
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

    // Phase 6: Play feedback for cell selection
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

    // Phase 6: Play feedback for number entry
    _soundService.playNumberEntry();
    _hapticService.mediumTap();

    // Validate and highlight errors
    _validateAndHighlightErrors();

    // Check win condition
    if (_checkWinCondition()) {
      _handleVictory();
    }

    notifyListeners();
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

    // Phase 6: Play feedback for note toggle
    _soundService.playNotesToggle();
    _hapticService.lightTap();

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

    // Phase 6: Play feedback for erase
    _soundService.playErase();
    _hapticService.mediumTap();

    // Re-validate board
    _validateAndHighlightErrors();

    notifyListeners();
  }

  /// Toggles notes mode on/off
  void toggleNotesMode() {
    _notesMode = !_notesMode;

    // Phase 6: Play feedback for mode toggle
    _soundService.playNotesToggle();
    _hapticService.lightTap();

    notifyListeners();
  }

  /// Validates the board and highlights errors
  void _validateAndHighlightErrors() {
    if (!_errorHighlightEnabled || _currentBoard == null) return;

    // Clear all error flags first
    _currentBoard!.clearErrors();

    // Get positions with conflicts
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);

    // Mark conflicting cells as errors
    for (final position in conflicts) {
      final cell = _currentBoard!.getCell(position.row, position.col);
      cell.isError = true;

      // Increment mistakes only for user-entered cells (not fixed)
      if (!cell.isFixed) {
        // Note: This is simplistic. In production, you might want to track
        // mistakes more carefully to avoid double-counting
      }
    }

    // Phase 6: Play error feedback if there are conflicts
    if (conflicts.isNotEmpty) {
      _soundService.playError();
      _hapticService.errorShake();
    }
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
    _cancelTimer();

    // Phase 6: Play victory feedback
    _soundService.playVictory();
    _hapticService.successPattern();

    // Save score via GameStatsMixin
    _saveScore();

    // Record achievement
    _recordAchievement();

    // Save completed game and update stats
    _saveCompletedGame();

    // Delete saved game (no longer needed)
    _persistenceService.deleteSavedGame('classic');
  }

  /// Calculates the final score
  int _calculateScore() {
    const baseScore = 10000;
    final mistakePenalty = _mistakes * 100;
    final hintPenalty = _hintsUsed * 200;
    final timePenalty = _elapsedSeconds;

    final score = (baseScore - mistakePenalty - hintPenalty - timePenalty).clamp(0, 10000);
    return score;
  }

  /// Saves score to Firebase
  void _saveScore() {
    final finalScore = _calculateScore();
    saveScore('sudoku', finalScore);
  }

  /// Records achievement
  Future<void> _recordAchievement() async {
    // TODO: Implement Sudoku-specific achievements
    // Examples:
    // - First Sudoku completed
    // - Complete without hints (_hintsUsed == 0)
    // - Complete without mistakes (_mistakes == 0)
    // - Speed completion (under X minutes)
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
    final randomIndex = _generator.hashCode % emptyCells.length; // Simple randomization
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

    // Phase 6: Play feedback for hint
    _soundService.playHint();
    _hapticService.doubleTap();

    // Re-validate
    _validateAndHighlightErrors();

    // Check win condition
    if (_checkWinCondition()) {
      _handleVictory();
    }

    notifyListeners();
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

    // Phase 6: Play feedback for undo
    _soundService.playUndo();
    _hapticService.mediumTap();

    // Re-validate
    _validateAndHighlightErrors();

    notifyListeners();
  }

  /// Toggles error highlighting on/off
  void toggleErrorHighlighting(bool enabled) {
    _errorHighlightEnabled = enabled;
    if (enabled) {
      _validateAndHighlightErrors();
    } else {
      _currentBoard?.clearErrors();
    }
    notifyListeners();
  }

  // ========== PERSISTENCE METHODS (Phase 4) ==========

  /// Saves the completed game to history and updates statistics
  Future<void> _saveCompletedGame() async {
    if (_currentBoard == null) return;

    final completedGame = CompletedGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: 'classic',
      difficulty: _difficulty,
      score: _calculateScore(),
      timeSeconds: _elapsedSeconds,
      mistakes: _mistakes,
      hintsUsed: _hintsUsed,
      victory: true,
      completedAt: DateTime.now(),
    );

    // Save to history
    await _persistenceService.saveCompletedGame(completedGame);

    // Update statistics
    await _sudokuStatsService.recordGameCompletion(completedGame);

    // Update best score if applicable
    await _persistenceService.saveBestScore('classic', _difficulty, _calculateScore());
  }

  /// Saves the current game state (auto-save)
  Future<void> saveGameState() async {
    if (_currentBoard == null || _originalBoard == null || _isGameOver) {
      return; // Don't save if no game in progress or game is over
    }

    final savedGame = SavedGame(
      id: 'classic_${_difficulty.name}',
      mode: 'classic',
      difficulty: _difficulty,
      currentBoard: _currentBoard!,
      originalBoard: _originalBoard!,
      solvedBoard: _solvedBoard,
      elapsedSeconds: _elapsedSeconds,
      mistakes: _mistakes,
      hintsUsed: _hintsUsed,
      hintsRemaining: _hintsRemaining,
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
    final savedGame = await _persistenceService.loadSavedGame('classic');

    if (savedGame == null) {
      return false;
    }

    // Restore game state
    _difficulty = savedGame.difficulty;
    _currentBoard = savedGame.currentBoard;
    _originalBoard = savedGame.originalBoard;
    _solvedBoard = savedGame.solvedBoard;
    _elapsedSeconds = savedGame.elapsedSeconds;
    _mistakes = savedGame.mistakes;
    _hintsUsed = savedGame.hintsUsed;
    _hintsRemaining = savedGame.hintsRemaining;
    _selectedRow = savedGame.selectedRow;
    _selectedCol = savedGame.selectedCol;
    _notesMode = savedGame.notesMode;
    _actionHistory.clear();
    _actionHistory.addAll(savedGame.actionHistory);
    _isGameOver = false;
    _isVictory = false;

    // Restart timer
    _startTimer();

    notifyListeners();
    return true;
  }

  /// Checks if a saved game exists
  Future<bool> hasSavedGame() async {
    return await _persistenceService.hasSavedGame('classic');
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
