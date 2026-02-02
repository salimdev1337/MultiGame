import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multigame/games/sudoku/models/match_room.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';
import 'package:multigame/games/sudoku/models/sudoku_action.dart';
import 'package:multigame/games/sudoku/logic/sudoku_validator.dart';
import 'package:multigame/games/sudoku/services/matchmaking_service.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Provider for online 1v1 Sudoku game state
class SudokuOnlineProvider with ChangeNotifier {
  final MatchmakingService _matchmakingService;
  final String userId;
  final String displayName;

  // Game state
  SudokuBoard? _board;
  SudokuBoard? _originalBoard;
  MatchRoom? _currentMatch;
  StreamSubscription<MatchRoom>? _matchSubscription;

  // Selection state
  int? _selectedRow;
  int? _selectedCol;

  // Game tracking
  int _mistakes = 0;
  bool _notesMode = false;
  final List<SudokuAction> _history = [];
  int _historyIndex = -1;

  // Timer
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  Timer? _timeoutCheckTimer;

  SudokuOnlineProvider({
    required MatchmakingService matchmakingService,
    required this.userId,
    required this.displayName,
  }) : _matchmakingService = matchmakingService;

  // Getters
  SudokuBoard? get board => _board;
  MatchRoom? get currentMatch => _currentMatch;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  int get mistakes => _mistakes;
  bool get notesMode => _notesMode;
  int get elapsedSeconds => _elapsedSeconds;
  bool get canUndo => _historyIndex >= 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  // Match state getters
  bool get isWaiting => _currentMatch?.isWaiting ?? false;
  bool get isPlaying => _currentMatch?.isInProgress ?? false;
  bool get isCompleted => _currentMatch?.isCompleted ?? false;
  bool get isWinner => _currentMatch?.winnerId == userId;
  bool get hasOpponent => _currentMatch?.isFull ?? false;

  /// Get opponent's display name
  String? get opponentName => _currentMatch?.getOpponent(userId)?.displayName;

  /// Get opponent's progress (filled cells)
  int? get opponentProgress => _currentMatch?.getOpponent(userId)?.filledCells;

  /// Get opponent's completion status
  bool get opponentCompleted => _currentMatch?.getOpponent(userId)?.isCompleted ?? false;

  /// Create a new match and wait for opponent
  Future<void> createMatch(String difficulty) async {
    try {
      final matchId = await _matchmakingService.createMatch(
        userId: userId,
        displayName: displayName,
        difficulty: difficulty,
      );

      // Start listening to match updates
      await _listenToMatch(matchId);
    } catch (e) {
      SecureLogger.error('Failed to create match', error: e);
      rethrow;
    }
  }

  /// Join an available match
  Future<void> joinMatch(String difficulty) async {
    try {
      final matchId = await _matchmakingService.quickMatch(
        userId: userId,
        displayName: displayName,
        difficulty: difficulty,
      );

      // Start listening to match updates
      await _listenToMatch(matchId);
    } catch (e) {
      SecureLogger.error('Failed to join match', error: e);
      rethrow;
    }
  }

  /// Listen to match updates in real-time
  Future<void> _listenToMatch(String matchId) async {
    _matchSubscription?.cancel();

    _matchSubscription = _matchmakingService.watchMatch(matchId).listen(
      (matchRoom) {
        _currentMatch = matchRoom;

        // Initialize board when match starts
        if (_board == null && matchRoom.puzzleData.isNotEmpty) {
          _initializeBoard(matchRoom.puzzleData);
        }

        // Start game timer when both players join
        if (matchRoom.isFull && _gameTimer == null && !matchRoom.isCompleted) {
          _startTimer();
          _startTimeoutCheck();
        }

        // Handle match completion
        if (matchRoom.isCompleted) {
          _stopTimer();
          _stopTimeoutCheck();
        }

        notifyListeners();
      },
      onError: (error) {
        SecureLogger.error('Match stream error', error: error);
      },
    );
  }

  /// Initialize board from puzzle data
  void _initializeBoard(List<List<int>> puzzleData) {
    _board = SudokuBoard.fromValues(puzzleData);
    _originalBoard = _board!.clone();
    _mistakes = 0;
    _elapsedSeconds = 0;
    _history.clear();
    _historyIndex = -1;
    notifyListeners();
  }

  /// Select a cell
  void selectCell(int row, int col) {
    if (_board == null || _currentMatch?.isCompleted == true) return;

    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  /// Clear cell selection
  void clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  /// Toggle notes mode
  void toggleNotesMode() {
    _notesMode = !_notesMode;
    notifyListeners();
  }

  /// Place a number in the selected cell
  Future<void> placeNumber(int number) async {
    if (_board == null ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentMatch?.isCompleted == true) {
      return;
    }

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);

    // Can't modify fixed cells
    if (cell.isFixed) return;

    if (_notesMode) {
      // Save state for undo
      final previousNotes = Set<int>.from(cell.notes);

      // Toggle note
      if (cell.notes.contains(number)) {
        cell.notes.remove(number);
        _saveState(SudokuAction.removeNote(
          row: _selectedRow!,
          col: _selectedCol!,
          value: number,
          previousNotes: previousNotes,
        ));
      } else {
        cell.notes.add(number);
        _saveState(SudokuAction.addNote(
          row: _selectedRow!,
          col: _selectedCol!,
          value: number,
          previousNotes: previousNotes,
        ));
      }
    } else {
      // Place number
      final previousValue = cell.value;
      final previousNotes = Set<int>.from(cell.notes);

      // Save state for undo
      _saveState(SudokuAction.setValue(
        row: _selectedRow!,
        col: _selectedCol!,
        value: number,
        previousValue: previousValue,
        previousNotes: previousNotes,
      ));

      cell.value = number;

      // Clear notes when placing number
      cell.notes.clear();

      // Validate and mark errors
      _board!.clearErrors();
      final conflicts = SudokuValidator.getConflictPositions(_board!);
      for (final pos in conflicts) {
        _board!.getCell(pos.row, pos.col).isError = true;
      }

      // Track mistakes
      if (conflicts.isNotEmpty && previousValue != number) {
        _mistakes++;
      }

      // Check if puzzle is solved
      final isSolved = SudokuValidator.isSolved(_board!);

      // Sync board state to Firestore
      await _syncBoardState(isCompleted: isSolved);
    }

    notifyListeners();
  }

  /// Clear the selected cell
  Future<void> clearCell() async {
    if (_board == null ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentMatch?.isCompleted == true) {
      return;
    }

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);

    // Can't modify fixed cells
    if (cell.isFixed) return;

    // Save state for undo
    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    _saveState(SudokuAction.clearValue(
      row: _selectedRow!,
      col: _selectedCol!,
      previousValue: previousValue,
      previousNotes: previousNotes,
    ));

    cell.value = null;
    cell.notes.clear();
    cell.isError = false;

    // Sync board state to Firestore
    await _syncBoardState(isCompleted: false);

    notifyListeners();
  }

  /// Sync board state to Firestore
  Future<void> _syncBoardState({required bool isCompleted}) async {
    if (_board == null || _currentMatch == null) return;

    try {
      await _matchmakingService.updatePlayerBoard(
        matchId: _currentMatch!.matchId,
        userId: userId,
        board: _board!,
        isCompleted: isCompleted,
      );
    } catch (e) {
      SecureLogger.error('Failed to sync board state', error: e);
    }
  }

  /// Save current state for undo/redo
  void _saveState(SudokuAction action) {
    // Remove all actions after current position
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(action);
    _historyIndex = _history.length - 1;

    // Limit history size
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  /// Undo last action
  Future<void> undo() async {
    if (!canUndo || _board == null) return;

    final action = _history[_historyIndex];
    final cell = _board!.getCell(action.row, action.col);

    // Restore previous state based on action type
    switch (action.type) {
      case SudokuActionType.setValue:
      case SudokuActionType.clearValue:
        cell.value = action.previousValue;
        if (action.previousNotes != null) {
          cell.notes.clear();
          cell.notes.addAll(action.previousNotes!);
        }
        break;
      case SudokuActionType.addNote:
      case SudokuActionType.removeNote:
        if (action.previousNotes != null) {
          cell.notes.clear();
          cell.notes.addAll(action.previousNotes!);
        }
        break;
    }

    _historyIndex--;

    // Sync board state
    await _syncBoardState(isCompleted: false);

    notifyListeners();
  }

  /// Redo last undone action
  Future<void> redo() async {
    if (!canRedo || _board == null) return;

    _historyIndex++;
    final action = _history[_historyIndex];
    final cell = _board!.getCell(action.row, action.col);

    // Reapply action
    switch (action.type) {
      case SudokuActionType.setValue:
        cell.value = action.value;
        cell.notes.clear();
        break;
      case SudokuActionType.clearValue:
        cell.value = null;
        cell.notes.clear();
        break;
      case SudokuActionType.addNote:
        if (action.value != null) {
          cell.notes.add(action.value!);
        }
        break;
      case SudokuActionType.removeNote:
        if (action.value != null) {
          cell.notes.remove(action.value!);
        }
        break;
    }

    // Sync board state
    await _syncBoardState(isCompleted: false);

    notifyListeners();
  }

  /// Reset board to original state
  Future<void> resetBoard() async {
    if (_originalBoard == null) return;

    _board = _originalBoard!.clone();
    _mistakes = 0;
    _history.clear();
    _historyIndex = -1;
    clearSelection();

    // Sync board state
    await _syncBoardState(isCompleted: false);

    notifyListeners();
  }

  /// Leave the current match
  Future<void> leaveMatch() async {
    if (_currentMatch == null) return;

    try {
      await _matchmakingService.leaveMatch(_currentMatch!.matchId, userId);
      await _cleanup();
    } catch (e) {
      SecureLogger.error('Failed to leave match', error: e);
    }
  }

  /// Start game timer
  void _startTimer() {
    _elapsedSeconds = 0;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  /// Stop game timer
  void _stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  /// Start timeout check timer
  void _startTimeoutCheck() {
    _timeoutCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_currentMatch != null && _currentMatch!.hasTimedOut) {
        await _matchmakingService.handleTimeout(_currentMatch!.matchId);
      }
    });
  }

  /// Stop timeout check timer
  void _stopTimeoutCheck() {
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
  }

  /// Clean up resources
  Future<void> _cleanup() async {
    _stopTimer();
    _stopTimeoutCheck();
    await _matchSubscription?.cancel();
    _matchSubscription = null;
    _currentMatch = null;
    _board = null;
    _originalBoard = null;
    clearSelection();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
