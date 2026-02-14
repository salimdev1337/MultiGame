// Sudoku Rush Mode provider - see docs/SUDOKU_ARCHITECTURE.md

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

class SudokuRushProvider extends ChangeNotifier with GameStatsMixin {
  final FirebaseStatsService _statsService;
  final SudokuPersistenceService _persistenceService;
  final SudokuStatsService _sudokuStatsService;
  final SudokuSoundService _soundService;
  final SudokuHapticService _hapticService;

  @override
  FirebaseStatsService get statsService => _statsService;

  static const int initialTimeSeconds = 300;
  static const int penaltySeconds = 10;

  SudokuBoard? _currentBoard;
  SudokuBoard? _originalBoard;
  SudokuBoard? _solvedBoard;
  SudokuDifficulty _difficulty = SudokuDifficulty.medium;

  int? _selectedRow;
  int? _selectedCol;

  int _mistakes = 0;
  int _hintsUsed = 0;
  int _hintsRemaining = 3;
  int _remainingSeconds = initialTimeSeconds;
  int _penaltiesApplied = 0;
  Timer? _timer;
  bool _isGameOver = false;
  bool _isVictory = false;
  bool _isDefeat = false;

  bool _notesMode = false;
  bool _isDisposed = false;

  final List<SudokuAction> _actionHistory = [];

  bool _errorHighlightEnabled = true;

  late final SudokuGenerator _generator;

  bool _showPenalty = false;

  SudokuRushProvider({
    required FirebaseStatsService statsService,
    required SudokuPersistenceService persistenceService,
    required SudokuStatsService sudokuStatsService,
    required SudokuSoundService soundService,
    required SudokuHapticService hapticService,
  }) : _statsService = statsService,
       _persistenceService = persistenceService,
       _sudokuStatsService = sudokuStatsService,
       _soundService = soundService,
       _hapticService = hapticService {
    _generator = SudokuGenerator();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

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

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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

    await Future.delayed(const Duration(milliseconds: 100));
    _currentBoard = _generator.generate(difficulty);
    _originalBoard = _currentBoard!.clone();

    _solvedBoard = SudokuSolver.getSolution(_currentBoard!);

    _startTimer();
    notifyListeners();
  }

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

  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameOver) {
        _cancelTimer();
        return;
      }

      _remainingSeconds--;
      notifyListeners();

      if (_remainingSeconds <= 0) {
        _handleDefeat();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void pauseTimer() {
    _cancelTimer();
    notifyListeners();
  }

  void resumeTimer() {
    if (!_isGameOver) {
      _startTimer();
    }
    notifyListeners();
  }

  void selectCell(int row, int col) {
    if (_isGameOver) return;

    _selectedRow = row;
    _selectedCol = col;
    _soundService.playSelectCell();
    _hapticService.lightTap();
    notifyListeners();
  }

  void clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  void placeNumber(int number) {
    if (_isGameOver ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentBoard == null) {
      return;
    }

    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);

    if (cell.isFixed) {
      return;
    }

    if (_notesMode) {
      _toggleNote(number);
    } else {
      _placeValue(number);
    }
  }

  void _placeValue(int number) {
    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);
    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    _actionHistory.add(
      SudokuAction.setValue(
        row: _selectedRow!,
        col: _selectedCol!,
        value: number,
        previousValue: previousValue,
        previousNotes: previousNotes,
      ),
    );

    cell.value = number;
    cell.notes.clear();

    final hadErrors = _validateAndApplyPenalty();

    if (!hadErrors) {
      _soundService.playNumberEntry();
      _hapticService.mediumTap();
    }

    if (!hadErrors && _checkWinCondition()) {
      _handleVictory();
    }

    notifyListeners();
  }

  bool _validateAndApplyPenalty() {
    if (!_errorHighlightEnabled || _currentBoard == null) return false;

    _currentBoard!.clearErrors();

    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);

    if (conflicts.isNotEmpty) {
      for (final position in conflicts) {
        final cell = _currentBoard!.getCell(position.row, position.col);
        cell.isError = true;

        if (!cell.isFixed) {
          _mistakes++;
        }
      }

      _applyTimePenalty();
      return true;
    }

    return false;
  }

  void _applyTimePenalty() {
    _remainingSeconds = (_remainingSeconds - penaltySeconds).clamp(
      0,
      initialTimeSeconds,
    );
    _penaltiesApplied++;

    _soundService.playError();
    _hapticService.errorShake();

    _showPenalty = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _showPenalty = false;
      notifyListeners();
    });

    if (_remainingSeconds <= 0) {
      _handleDefeat();
    }
  }

  void _toggleNote(int number) {
    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);

    if (cell.hasValue) {
      return;
    }

    final previousNotes = Set<int>.from(cell.notes);

    if (cell.notes.contains(number)) {
      _actionHistory.add(
        SudokuAction.removeNote(
          row: _selectedRow!,
          col: _selectedCol!,
          value: number,
          previousNotes: previousNotes,
        ),
      );
      cell.notes.remove(number);
    } else {
      _actionHistory.add(
        SudokuAction.addNote(
          row: _selectedRow!,
          col: _selectedCol!,
          value: number,
          previousNotes: previousNotes,
        ),
      );
      cell.notes.add(number);
    }

    notifyListeners();
  }

  void eraseCell() {
    if (_isGameOver ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentBoard == null) {
      return;
    }

    final cell = _currentBoard!.getCell(_selectedRow!, _selectedCol!);

    if (cell.isFixed) {
      return;
    }

    _actionHistory.add(
      SudokuAction.clearValue(
        row: _selectedRow!,
        col: _selectedCol!,
        previousValue: cell.value,
        previousNotes: Set<int>.from(cell.notes),
      ),
    );

    cell.value = null;
    cell.notes.clear();
    cell.isError = false;

    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    for (final position in conflicts) {
      _currentBoard!.getCell(position.row, position.col).isError = true;
    }

    _soundService.playErase();
    _hapticService.mediumTap();
    notifyListeners();
  }

  void toggleNotesMode() {
    _notesMode = !_notesMode;
    _soundService.playNotesToggle();
    _hapticService.lightTap();
    notifyListeners();
  }

  bool _checkWinCondition() {
    if (_currentBoard == null) return false;
    return SudokuValidator.isSolved(_currentBoard!);
  }

  void _handleVictory() {
    _isVictory = true;
    _isGameOver = true;
    _soundService.playVictory();
    _hapticService.successPattern();
    _cancelTimer();

    _saveScore();

    _recordAchievement();

    _saveCompletedGame(victory: true);

    _persistenceService.deleteSavedGame('rush');
  }

  void _handleDefeat() {
    _isDefeat = true;
    _isGameOver = true;
    _remainingSeconds = 0;
    _cancelTimer();

    _saveCompletedGame(victory: false);

    _persistenceService.deleteSavedGame('rush');

    notifyListeners();
  }

  int _calculateScore() {
    const baseScore = 10000;

    final timeBonus = _remainingSeconds * 10;

    final mistakePenalty = _mistakes * 100;
    final hintPenalty = _hintsUsed * 200;

    final score = (baseScore + timeBonus - mistakePenalty - hintPenalty).clamp(
      0,
      20000,
    );
    return score;
  }

  void _saveScore() {
    final finalScore = _calculateScore();
    saveScore('sudoku_rush', finalScore);
  }

  Future<void> _recordAchievement() async {}

  void useHint() {
    if (_isGameOver ||
        _hintsRemaining <= 0 ||
        _currentBoard == null ||
        _solvedBoard == null) {
      return;
    }

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
      return;
    }

    final randomIndex = _generator.hashCode % emptyCells.length;
    final hintPosition = emptyCells[randomIndex];

    final correctValue = _solvedBoard!
        .getCell(hintPosition.row, hintPosition.col)
        .value;

    if (correctValue == null) {
      return;
    }

    final cell = _currentBoard!.getCell(hintPosition.row, hintPosition.col);
    _actionHistory.add(
      SudokuAction.setValue(
        row: hintPosition.row,
        col: hintPosition.col,
        value: correctValue,
        previousValue: cell.value,
        previousNotes: Set<int>.from(cell.notes),
      ),
    );

    cell.value = correctValue;
    cell.notes.clear();
    cell.isError = false;

    _hintsUsed++;
    _hintsRemaining--;

    _selectedRow = hintPosition.row;
    _selectedCol = hintPosition.col;

    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    for (final position in conflicts) {
      _currentBoard!.getCell(position.row, position.col).isError = true;
    }

    if (_checkWinCondition()) {
      _handleVictory();
    }

    notifyListeners();
    _soundService.playHint();
    _hapticService.doubleTap();
  }

  void undo() {
    if (_actionHistory.isEmpty || _isGameOver || _currentBoard == null) {
      return;
    }

    final lastAction = _actionHistory.removeLast();
    final cell = _currentBoard!.getCell(lastAction.row, lastAction.col);

    switch (lastAction.type) {
      case SudokuActionType.setValue:
        cell.value = lastAction.previousValue;
        cell.notes.clear();
        if (lastAction.previousNotes != null) {
          cell.notes.addAll(lastAction.previousNotes!);
        }
        break;

      case SudokuActionType.clearValue:
        cell.value = lastAction.previousValue;
        cell.notes.clear();
        if (lastAction.previousNotes != null) {
          cell.notes.addAll(lastAction.previousNotes!);
        }
        break;

      case SudokuActionType.addNote:
        if (lastAction.value != null) {
          cell.notes.remove(lastAction.value!);
        }
        break;

      case SudokuActionType.removeNote:
        if (lastAction.value != null) {
          cell.notes.add(lastAction.value!);
        }
        break;
    }

    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    for (final position in conflicts) {
      _currentBoard!.getCell(position.row, position.col).isError = true;
    }

    notifyListeners();
    _soundService.playUndo();
    _hapticService.mediumTap();
  }

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

    await _persistenceService.saveCompletedGame(completedGame);

    await _sudokuStatsService.recordGameCompletion(completedGame);

    if (victory) {
      await _persistenceService.saveBestScore(
        'rush',
        _difficulty,
        _calculateScore(),
      );
    }
  }

  Future<void> saveGameState() async {
    if (_currentBoard == null || _originalBoard == null || _isGameOver) {
      return;
    }

    final savedGame = SavedGame(
      id: 'rush_${_difficulty.name}',
      mode: 'rush',
      difficulty: _difficulty,
      currentBoard: _currentBoard!,
      originalBoard: _originalBoard!,
      solvedBoard: _solvedBoard,
      elapsedSeconds: initialTimeSeconds - _remainingSeconds,
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

  Future<bool> loadGameState() async {
    final savedGame = await _persistenceService.loadSavedGame('rush');

    if (savedGame == null) {
      return false;
    }

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

    _startTimer();

    notifyListeners();
    return true;
  }

  Future<bool> hasSavedGame() async {
    return await _persistenceService.hasSavedGame('rush');
  }

  @override
  void dispose() {
    // Prevent double-dispose
    if (_isDisposed) return;

    // Mark as disposed to prevent any pending callbacks from calling notifyListeners
    _isDisposed = true;

    _cancelTimer();
    super.dispose();
  }
}
