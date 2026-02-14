// Sudoku Rush Mode — Riverpod port.
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

class SudokuRushState {
  static const int initialTimeSeconds = 300;
  static const int penaltySeconds = 10;

  final SudokuDifficulty difficulty;
  final int? selectedRow;
  final int? selectedCol;
  final int mistakes;
  final int hintsUsed;
  final int hintsRemaining;
  final int remainingSeconds;
  final int penaltiesApplied;
  final bool isGameOver;
  final bool isVictory;
  final bool isDefeat;
  final bool notesMode;
  final bool errorHighlightEnabled;
  final bool showPenalty;
  final bool hasBoard;
  final int revision;

  const SudokuRushState({
    this.difficulty = SudokuDifficulty.medium,
    this.selectedRow,
    this.selectedCol,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.hintsRemaining = 3,
    this.remainingSeconds = initialTimeSeconds,
    this.penaltiesApplied = 0,
    this.isGameOver = false,
    this.isVictory = false,
    this.isDefeat = false,
    this.notesMode = false,
    this.errorHighlightEnabled = true,
    this.showPenalty = false,
    this.hasBoard = false,
    this.revision = 0,
  });

  int get score {
    const base = 10000;
    final timeBonus = remainingSeconds * 10;
    return (base + timeBonus - mistakes * 100 - hintsUsed * 200).clamp(
      0,
      20000,
    );
  }

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  SudokuRushState copyWith({
    SudokuDifficulty? difficulty,
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
    int? mistakes,
    int? hintsUsed,
    int? hintsRemaining,
    int? remainingSeconds,
    int? penaltiesApplied,
    bool? isGameOver,
    bool? isVictory,
    bool? isDefeat,
    bool? notesMode,
    bool? errorHighlightEnabled,
    bool? showPenalty,
    bool? hasBoard,
    bool bumpRevision = false,
  }) {
    return SudokuRushState(
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      penaltiesApplied: penaltiesApplied ?? this.penaltiesApplied,
      isGameOver: isGameOver ?? this.isGameOver,
      isVictory: isVictory ?? this.isVictory,
      isDefeat: isDefeat ?? this.isDefeat,
      notesMode: notesMode ?? this.notesMode,
      errorHighlightEnabled:
          errorHighlightEnabled ?? this.errorHighlightEnabled,
      showPenalty: showPenalty ?? this.showPenalty,
      hasBoard: hasBoard ?? this.hasBoard,
      revision: bumpRevision ? revision + 1 : revision,
    );
  }
}

class SudokuRushNotifier extends GameStatsNotifier<SudokuRushState> {
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
  SudokuRushState build() {
    _persistence = ref.read(sudokuPersistenceServiceProvider);
    _sound = ref.read(sudokuSoundServiceProvider);
    _haptic = ref.read(sudokuHapticServiceProvider);
    ref.onDispose(() => _timer?.cancel());
    return const SudokuRushState();
  }

  Future<void> initializeGame(SudokuDifficulty difficulty) async {
    _timer?.cancel();
    _actionHistory.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _currentBoard = _generator.generate(difficulty);
    _originalBoard = _currentBoard!.clone();
    _solvedBoard = SudokuSolver.getSolution(_currentBoard!);
    state = SudokuRushState(difficulty: difficulty, hasBoard: true);
    _startTimer();
  }

  void resetGame() {
    if (_originalBoard == null) return;
    _timer?.cancel();
    _currentBoard = _originalBoard!.clone();
    _actionHistory.clear();
    state = SudokuRushState(
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
    if (cell.isFixed) {
      return;
    }
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

    final hadError = _validateAndApplyPenalty();
    if (!hadError) {
      _sound.playNumberEntry();
      _haptic.mediumTap();
      if (_checkWin()) {
        _handleVictory();
        return;
      }
    }
    state = state.copyWith(bumpRevision: true);
  }

  bool _validateAndApplyPenalty() {
    if (!state.errorHighlightEnabled || _currentBoard == null) {
      return false;
    }
    _currentBoard!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_currentBoard!);
    if (conflicts.isEmpty) {
      return false;
    }
    for (final p in conflicts) {
      _currentBoard!.getCell(p.row, p.col).isError = true;
    }
    final newRemaining =
        (state.remainingSeconds - SudokuRushState.penaltySeconds).clamp(
          0,
          SudokuRushState.initialTimeSeconds,
        );
    state = state.copyWith(
      mistakes: state.mistakes + conflicts.length,
      remainingSeconds: newRemaining,
      penaltiesApplied: state.penaltiesApplied + 1,
      showPenalty: true,
      bumpRevision: true,
    );
    _sound.playError();
    _haptic.errorShake();
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(showPenalty: false);
    });
    if (newRemaining <= 0) {
      _handleDefeat();
    }
    return true;
  }

  void _toggleNote(int number) {
    final s = state;
    final cell = _currentBoard!.getCell(s.selectedRow!, s.selectedCol!);
    if (cell.hasValue) {
      return;
    }
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
    if (cell.isFixed) {
      return;
    }
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
    _currentBoard!.clearErrors();
    for (final p in SudokuValidator.getConflictPositions(_currentBoard!)) {
      _currentBoard!.getCell(p.row, p.col).isError = true;
    }
    _sound.playErase();
    _haptic.mediumTap();
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
    if (empty.isEmpty) {
      return;
    }
    final pos = empty[_generator.hashCode % empty.length];
    final val = _solvedBoard!.getCell(pos.row, pos.col).value;
    if (val == null) {
      return;
    }
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
    if (_checkWin()) {
      _handleVictory();
      return;
    }
    state = state.copyWith(
      selectedRow: pos.row,
      selectedCol: pos.col,
      hintsUsed: s.hintsUsed + 1,
      hintsRemaining: s.hintsRemaining - 1,
      bumpRevision: true,
    );
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
    state = state.copyWith(bumpRevision: true);
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
      final next = state.remainingSeconds - 1;
      state = state.copyWith(remainingSeconds: next);
      if (next <= 0) {
        _handleDefeat();
      }
    });
  }

  bool _checkWin() {
    if (_currentBoard == null) {
      return false;
    }
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
    saveScore('sudoku_rush', score);
    _persistence.deleteSavedGame('rush');
  }

  void _handleDefeat() {
    _timer?.cancel();
    state = state.copyWith(
      isGameOver: true,
      isDefeat: true,
      remainingSeconds: 0,
      bumpRevision: true,
    );
    _persistence.deleteSavedGame('rush');
  }
}

final sudokuRushProvider =
    NotifierProvider.autoDispose<SudokuRushNotifier, SudokuRushState>(
      SudokuRushNotifier.new,
    );
