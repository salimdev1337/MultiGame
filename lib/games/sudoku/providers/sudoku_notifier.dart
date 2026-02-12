library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import '../models/sudoku_board.dart';
import '../models/sudoku_action.dart';
import '../logic/sudoku_generator.dart';
import '../logic/sudoku_validator.dart';
import '../logic/sudoku_solver.dart';
import '../services/sudoku_persistence_service.dart';
import '../services/sudoku_sound_service.dart';
import '../services/sudoku_haptic_service.dart';

class SudokuClassicState {
  final SudokuDifficulty difficulty;
  final int? selectedRow;
  final int? selectedCol;
  final int mistakes;
  final int hintsUsed;
  final int hintsRemaining;
  final int elapsedSeconds;
  final bool isGameOver;
  final bool isVictory;
  final bool notesMode;
  final bool errorHighlightEnabled;
  final bool hasBoard;
  final int revision;

  const SudokuClassicState({
    this.difficulty = SudokuDifficulty.medium,
    this.selectedRow,
    this.selectedCol,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.hintsRemaining = 3,
    this.elapsedSeconds = 0,
    this.isGameOver = false,
    this.isVictory = false,
    this.notesMode = false,
    this.errorHighlightEnabled = true,
    this.hasBoard = false,
    this.revision = 0,
  });

  bool get canUndo => false; // managed by notifier
  bool get canErase => selectedRow != null && selectedCol != null;

  int get score {
    const base = 10000;
    return (base - mistakes * 100 - hintsUsed * 200 - elapsedSeconds).clamp(
      0,
      10000,
    );
  }

  String get formattedTime {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  SudokuClassicState copyWith({
    SudokuDifficulty? difficulty,
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
    int? mistakes,
    int? hintsUsed,
    int? hintsRemaining,
    int? elapsedSeconds,
    bool? isGameOver,
    bool? isVictory,
    bool? notesMode,
    bool? errorHighlightEnabled,
    bool? hasBoard,
    bool bumpRevision = false,
  }) {
    return SudokuClassicState(
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isGameOver: isGameOver ?? this.isGameOver,
      isVictory: isVictory ?? this.isVictory,
      notesMode: notesMode ?? this.notesMode,
      errorHighlightEnabled:
          errorHighlightEnabled ?? this.errorHighlightEnabled,
      hasBoard: hasBoard ?? this.hasBoard,
      revision: bumpRevision ? revision + 1 : revision,
    );
  }
}

class SudokuClassicNotifier extends GameStatsNotifier<SudokuClassicState> {
  SudokuBoard? _currentBoard;
  SudokuBoard? _originalBoard;
  SudokuBoard? _solvedBoard;
  final List<SudokuAction> _actionHistory = [];
  final SudokuGenerator _generator = SudokuGenerator();
  Timer? _timer;

  late SudokuPersistenceService _persistence;
  late SudokuSoundService _sound;
  late SudokuHapticService _haptic;

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  // Expose board for UI reads (UI will read this through the notifier)
  SudokuBoard? get currentBoard => _currentBoard;
  SudokuBoard? get originalBoard => _originalBoard;
  bool get canUndo => _actionHistory.isNotEmpty;
  bool get canErase {
    final s = state;
    if (s.selectedRow == null ||
        s.selectedCol == null ||
        _currentBoard == null) {
      return false;
    }
    return !_currentBoard!.getCell(s.selectedRow!, s.selectedCol!).isFixed;
  }

  @override
  SudokuClassicState build() {
    _persistence = ref.read(sudokuPersistenceServiceProvider);
    _sound = ref.read(sudokuSoundServiceProvider);
    _haptic = ref.read(sudokuHapticServiceProvider);
    ref.onDispose(() => _timer?.cancel());
    return const SudokuClassicState();
  }

  Future<void> initializeGame(SudokuDifficulty difficulty) async {
    _timer?.cancel();
    _actionHistory.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _currentBoard = _generator.generate(difficulty);
    _originalBoard = _currentBoard!.clone();
    _solvedBoard = SudokuSolver.getSolution(_currentBoard!);
    state = SudokuClassicState(difficulty: difficulty, hasBoard: true);
    _startTimer();
  }

  void resetGame() {
    if (_originalBoard == null) return;
    _timer?.cancel();
    _currentBoard = _originalBoard!.clone();
    _actionHistory.clear();
    state = SudokuClassicState(
      difficulty: state.difficulty,
      hasBoard: true,
      errorHighlightEnabled: state.errorHighlightEnabled,
    );
    _startTimer();
  }

  void selectCell(int row, int col) {
    if (state.isGameOver) return;
    _sound.playSelectCell();
    _haptic.lightTap();
    state = state.copyWith(selectedRow: row, selectedCol: col);
  }

  void clearSelection() => state = state.copyWith(clearSelection: true);

  void placeNumber(int number) {
    final s = state;
    if (s.isGameOver ||
        s.selectedRow == null ||
        s.selectedCol == null ||
        _currentBoard == null) {
      return;
    }
    final cell = _currentBoard!.getCell(s.selectedRow!, s.selectedCol!);
    if (cell.isFixed) return;
    if (s.notesMode) {
      _toggleNote(number);
    } else {
      _placeValue(number);
    }
  }

  void _placeValue(int number) {
    final s = state;
    final cell = _currentBoard!.getCell(s.selectedRow!, s.selectedCol!);
    _actionHistory.add(
      SudokuAction.setValue(
        row: s.selectedRow!,
        col: s.selectedCol!,
        value: number,
        previousValue: cell.value,
        previousNotes: Set<int>.from(cell.notes),
      ),
    );
    cell.value = number;
    cell.notes.clear();
    _sound.playNumberEntry();
    _haptic.mediumTap();
    _validateAndHighlightErrors();
    if (_checkWin()) {
      _handleVictory();
    }
    state = state.copyWith(bumpRevision: true);
  }

  void _toggleNote(int number) {
    final s = state;
    final cell = _currentBoard!.getCell(s.selectedRow!, s.selectedCol!);
    if (cell.hasValue) return;
    final prev = Set<int>.from(cell.notes);
    if (cell.notes.contains(number)) {
      _actionHistory.add(
        SudokuAction.removeNote(
          row: s.selectedRow!,
          col: s.selectedCol!,
          value: number,
          previousNotes: prev,
        ),
      );
      cell.notes.remove(number);
    } else {
      _actionHistory.add(
        SudokuAction.addNote(
          row: s.selectedRow!,
          col: s.selectedCol!,
          value: number,
          previousNotes: prev,
        ),
      );
      cell.notes.add(number);
    }
    _sound.playNotesToggle();
    _haptic.lightTap();
    state = state.copyWith(bumpRevision: true);
  }

  void eraseCell() {
    final s = state;
    if (s.isGameOver ||
        s.selectedRow == null ||
        s.selectedCol == null ||
        _currentBoard == null) {
      return;
    }
    final cell = _currentBoard!.getCell(s.selectedRow!, s.selectedCol!);
    if (cell.isFixed) return;
    _actionHistory.add(
      SudokuAction.clearValue(
        row: s.selectedRow!,
        col: s.selectedCol!,
        previousValue: cell.value,
        previousNotes: Set<int>.from(cell.notes),
      ),
    );
    cell.value = null;
    cell.notes.clear();
    cell.isError = false;
    _sound.playErase();
    _haptic.mediumTap();
    _validateAndHighlightErrors();
    state = state.copyWith(bumpRevision: true);
  }

  void toggleNotesMode() {
    _sound.playNotesToggle();
    _haptic.lightTap();
    state = state.copyWith(notesMode: !state.notesMode);
  }

  void useHint() {
    final s = state;
    if (s.isGameOver ||
        s.hintsRemaining <= 0 ||
        _currentBoard == null ||
        _solvedBoard == null) {
      return;
    }
    final empty = <Position>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _currentBoard!.getCell(r, c);
        if (cell.isEmpty && !cell.isFixed) {
          empty.add(Position(r, c));
        }
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[_generator.hashCode % empty.length];
    final val = _solvedBoard!.getCell(pos.row, pos.col).value;
    if (val == null) return;
    final cell = _currentBoard!.getCell(pos.row, pos.col);
    _actionHistory.add(
      SudokuAction.setValue(
        row: pos.row,
        col: pos.col,
        value: val,
        previousValue: cell.value,
        previousNotes: Set<int>.from(cell.notes),
      ),
    );
    cell.value = val;
    cell.notes.clear();
    cell.isError = false;
    _sound.playHint();
    _haptic.doubleTap();
    _validateAndHighlightErrors();
    final newHintsUsed = s.hintsUsed + 1;
    if (_checkWin()) {
      _handleVictory();
    } else {
      state = state.copyWith(
        selectedRow: pos.row,
        selectedCol: pos.col,
        hintsUsed: newHintsUsed,
        hintsRemaining: s.hintsRemaining - 1,
        bumpRevision: true,
      );
    }
  }

  void undo() {
    if (_actionHistory.isEmpty || state.isGameOver || _currentBoard == null) {
      return;
    }
    final action = _actionHistory.removeLast();
    final cell = _currentBoard!.getCell(action.row, action.col);
    switch (action.type) {
      case SudokuActionType.setValue:
      case SudokuActionType.clearValue:
        cell.value = action.previousValue;
        cell.notes.clear();
        if (action.previousNotes != null) {
          cell.notes.addAll(action.previousNotes!);
        }
      case SudokuActionType.addNote:
        if (action.value != null) {
          cell.notes.remove(action.value!);
        }
      case SudokuActionType.removeNote:
        if (action.value != null) {
          cell.notes.add(action.value!);
        }
    }
    _sound.playUndo();
    _haptic.mediumTap();
    _validateAndHighlightErrors();
    state = state.copyWith(bumpRevision: true);
  }

  void toggleErrorHighlighting(bool enabled) {
    if (enabled && _currentBoard != null) {
      _validateAndHighlightErrors();
    }
    state = state.copyWith(errorHighlightEnabled: enabled, bumpRevision: true);
  }

  void pauseTimer() => _timer?.cancel();

  void resumeTimer() {
    if (!state.isGameOver) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isGameOver) {
        _timer?.cancel();
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _validateAndHighlightErrors() {
    if (!state.errorHighlightEnabled || _currentBoard == null) return;
    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    for (final p in conflicts) {
      _currentBoard!.getCell(p.row, p.col).isError = true;
    }
    if (conflicts.isNotEmpty) {
      _sound.playError();
      _haptic.errorShake();
      state = state.copyWith(mistakes: state.mistakes + conflicts.length);
    }
  }

  bool _checkWin() {
    if (_currentBoard == null) return false;
    return SudokuValidator.isSolved(_currentBoard!);
  }

  void _handleVictory() {
    _timer?.cancel();
    _sound.playVictory();
    _haptic.successPattern();
    final score = state.score;
    state = state.copyWith(
      isGameOver: true,
      isVictory: true,
      bumpRevision: true,
    );
    saveScore('sudoku', score);
    _persistence.deleteSavedGame('classic');
  }
}

final sudokuClassicProvider =
    NotifierProvider.autoDispose<SudokuClassicNotifier, SudokuClassicState>(
      SudokuClassicNotifier.new,
    );
