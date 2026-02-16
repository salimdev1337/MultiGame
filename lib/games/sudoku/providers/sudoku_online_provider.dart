// Sudoku 1v1 Online provider - see docs/SUDOKU_ARCHITECTURE.md

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multigame/games/sudoku/models/match_room.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';
import 'package:multigame/games/sudoku/models/sudoku_action.dart';
import 'package:multigame/games/sudoku/models/connection_state.dart';
import 'package:multigame/games/sudoku/logic/sudoku_validator.dart';
import 'package:multigame/games/sudoku/logic/sudoku_solver.dart';
import 'package:multigame/games/sudoku/services/matchmaking_service.dart';
import 'package:multigame/utils/secure_logger.dart';
import 'package:multigame/utils/debouncer.dart';

class SudokuOnlineProvider with ChangeNotifier {
  final MatchmakingService _matchmakingService;
  final String userId;
  final String displayName;

  SudokuBoard? _board;
  SudokuBoard? _originalBoard;
  SudokuBoard? _solvedBoard;
  MatchRoom? _currentMatch;
  StreamSubscription<MatchRoom>? _matchSubscription;

  int? _selectedRow;
  int? _selectedCol;

  int _mistakes = 0;
  int _hintsUsed = 0;
  bool _notesMode = false;
  final List<SudokuAction> _history = [];
  int _historyIndex = -1;

  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  Timer? _timeoutCheckTimer;

  final Debouncer _boardSyncDebouncer = Debouncer(
    delay: const Duration(seconds: 2),
  );
  final Debouncer _statsSyncDebouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );

  ConnectionState _connectionState = ConnectionState.offline;
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 5);
  static const Duration _reconnectionGracePeriod = Duration(seconds: 60);

  bool _isDisposed = false;

  static const Duration _timeout = Duration(seconds: 8);

  SudokuOnlineProvider({
    required MatchmakingService matchmakingService,
    required this.userId,
    required this.displayName,
  }) : _matchmakingService = matchmakingService;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  SudokuBoard? get board => _board;
  MatchRoom? get currentMatch => _currentMatch;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;
  int get hintsRemaining => 3 - _hintsUsed;
  bool get canUseHint =>
      _hintsUsed < 3 && _selectedRow != null && _selectedCol != null;
  bool get notesMode => _notesMode;
  int get elapsedSeconds => _elapsedSeconds;
  bool get canUndo => _historyIndex >= 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  ConnectionState get connectionState => _connectionState;

  bool get isWaiting => _currentMatch?.isWaiting ?? false;
  bool get isPlaying => _currentMatch?.isInProgress ?? false;
  bool get isCompleted => _currentMatch?.isCompleted ?? false;
  bool get isWinner => _currentMatch?.winnerId == userId;
  bool get hasOpponent => _currentMatch?.isFull ?? false;

  String? get opponentName => _currentMatch?.getOpponent(userId)?.displayName;

  int? get opponentProgress => _currentMatch?.getOpponent(userId)?.filledCells;

  bool get opponentCompleted =>
      _currentMatch?.getOpponent(userId)?.isCompleted ?? false;

  int get opponentMistakes =>
      _currentMatch?.getOpponent(userId)?.mistakeCount ?? 0;

  int get opponentHintsUsed =>
      _currentMatch?.getOpponent(userId)?.hintsUsed ?? 0;

  bool get opponentIsConnected =>
      _currentMatch?.getOpponent(userId)?.isConnected ?? false;

  ConnectionState get opponentConnectionState =>
      opponentIsConnected ? ConnectionState.online : ConnectionState.offline;

  Future<void> createMatch(String difficulty) async {
    try {
      final matchId = await _matchmakingService
          .createMatch(
            userId: userId,
            displayName: displayName,
            difficulty: difficulty,
          )
          .timeout(_timeout);

      await _listenToMatch(matchId);
    } catch (e) {
      SecureLogger.error('Failed to create match', error: e);
      rethrow;
    }
  }

  Future<void> joinMatch(String difficulty) async {
    try {
      final matchId = await _matchmakingService
          .quickMatch(
            userId: userId,
            displayName: displayName,
            difficulty: difficulty,
          )
          .timeout(_timeout);

      await _listenToMatch(matchId);
    } catch (e) {
      SecureLogger.error('Failed to join match', error: e);
      rethrow;
    }
  }

  Future<void> joinByRoomCode(String roomCode) async {
    try {
      final matchId = await _matchmakingService
          .joinByRoomCode(
            roomCode: roomCode,
            userId: userId,
            displayName: displayName,
          )
          .timeout(_timeout);

      await _listenToMatch(matchId);
    } catch (e) {
      SecureLogger.error('Failed to join match by room code', error: e);
      rethrow;
    }
  }

  Future<void> _listenToMatch(String matchId) async {
    await _matchSubscription?.cancel();

    _matchSubscription = _matchmakingService
        .watchMatch(matchId)
        .listen(
          (matchRoom) {
            _currentMatch = matchRoom;

            if (_board == null && matchRoom.puzzleData.isNotEmpty) {
              _initializeBoard(matchRoom.puzzleData);
            }

            if (matchRoom.isFull &&
                _gameTimer == null &&
                !matchRoom.isCompleted) {
              _startTimer();
              _startTimeoutCheck();
              _startHeartbeat();
            }

            if (matchRoom.isCompleted) {
              _stopTimer();
              _stopTimeoutCheck();
              _stopHeartbeat();
            }

            notifyListeners();
          },
          onError: (error) {
            SecureLogger.error('Match stream error', error: error);
          },
        );
  }

  void _initializeBoard(List<List<int>> puzzleData) {
    _board = SudokuBoard.fromValues(puzzleData);
    _originalBoard = _board!.clone();

    _solvedBoard = SudokuSolver.getSolution(_board!);
    if (_solvedBoard == null) {
      SecureLogger.error('Failed to solve board for hints');
    }

    _mistakes = 0;
    _hintsUsed = 0;
    _elapsedSeconds = 0;
    _history.clear();
    _historyIndex = -1;
    notifyListeners();
  }

  void selectCell(int row, int col) {
    if (_board == null || _currentMatch?.isCompleted == true) return;

    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  void clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  void toggleNotesMode() {
    _notesMode = !_notesMode;
    notifyListeners();
  }

  Future<void> placeNumber(int number) async {
    if (_board == null ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentMatch?.isCompleted == true) {
      return;
    }

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);

    if (cell.isFixed) return;

    if (_notesMode) {
      final previousNotes = Set<int>.from(cell.notes);

      if (cell.notes.contains(number)) {
        cell.notes.remove(number);
        _saveState(
          SudokuAction.removeNote(
            row: _selectedRow!,
            col: _selectedCol!,
            value: number,
            previousNotes: previousNotes,
          ),
        );
      } else {
        cell.notes.add(number);
        _saveState(
          SudokuAction.addNote(
            row: _selectedRow!,
            col: _selectedCol!,
            value: number,
            previousNotes: previousNotes,
          ),
        );
      }
    } else {
      final previousValue = cell.value;
      final previousNotes = Set<int>.from(cell.notes);

      _saveState(
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

      _board!.clearErrors();
      final conflicts = SudokuValidator.getConflictPositions(_board!);
      for (final pos in conflicts) {
        _board!.getCell(pos.row, pos.col).isError = true;
      }

      if (conflicts.isNotEmpty && previousValue != number) {
        _mistakes++;
      }

      final isSolved = SudokuValidator.isSolved(_board!);

      _syncBoardStateDebounced(isCompleted: isSolved);
      _syncPlayerStatsDebounced();
    }

    notifyListeners();
  }

  Future<void> clearCell() async {
    if (_board == null ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentMatch?.isCompleted == true) {
      return;
    }

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);

    if (cell.isFixed) return;

    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    _saveState(
      SudokuAction.clearValue(
        row: _selectedRow!,
        col: _selectedCol!,
        previousValue: previousValue,
        previousNotes: previousNotes,
      ),
    );

    cell.value = null;
    cell.notes.clear();
    cell.isError = false;

    _syncBoardStateDebounced(isCompleted: false);

    notifyListeners();
  }

  Future<void> useHint() async {
    if (_board == null ||
        _solvedBoard == null ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentMatch?.isCompleted == true) {
      return;
    }

    if (_hintsUsed >= 3) {
      SecureLogger.log('Hint limit reached (3/3)', tag: 'Hints');
      return;
    }

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);

    if (cell.isFixed) return;

    if (cell.hasValue) {
      SecureLogger.log('Cell already has a value', tag: 'Hints');
      return;
    }

    final correctValue = _solvedBoard!
        .getCell(_selectedRow!, _selectedCol!)
        .value;
    if (correctValue == null) {
      SecureLogger.error('Solved board has no value for this cell');
      return;
    }

    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    _saveState(
      SudokuAction.setValue(
        row: _selectedRow!,
        col: _selectedCol!,
        value: correctValue,
        previousValue: previousValue,
        previousNotes: previousNotes,
      ),
    );

    cell.value = correctValue;
    cell.notes.clear();
    cell.isError = false;

    _hintsUsed++;

    _board!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_board!);
    for (final pos in conflicts) {
      _board!.getCell(pos.row, pos.col).isError = true;
    }

    final isSolved = SudokuValidator.isSolved(_board!);

    _syncBoardStateDebounced(isCompleted: isSolved);
    _syncPlayerStatsDebounced();

    SecureLogger.log('Hint used: $_hintsUsed/3', tag: 'Hints');

    notifyListeners();
  }

  Future<void> _syncBoardState({required bool isCompleted}) async {
    if (_board == null || _currentMatch == null) return;

    try {
      await _matchmakingService
          .updatePlayerBoard(
            matchId: _currentMatch!.matchId,
            userId: userId,
            board: _board!,
            isCompleted: isCompleted,
          )
          .timeout(_timeout);
    } catch (e) {
      SecureLogger.error('Failed to sync board state', error: e);
    }
  }

  void _syncBoardStateDebounced({required bool isCompleted}) {
    if (_board == null || _currentMatch == null) return;

    _boardSyncDebouncer.run(() async {
      await _syncBoardState(isCompleted: isCompleted);
    });
  }

  void _syncPlayerStatsDebounced() {
    if (_currentMatch == null) return;

    _statsSyncDebouncer.run(() async {
      try {
        await _matchmakingService
            .updatePlayerStats(
              matchId: _currentMatch!.matchId,
              userId: userId,
              mistakeCount: _mistakes,
              hintsUsed: _hintsUsed,
            )
            .timeout(_timeout);
      } catch (e) {
        SecureLogger.error('Failed to sync player stats', error: e);
      }
    });
  }

  void _saveState(SudokuAction action) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(action);
    _historyIndex = _history.length - 1;

    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  Future<void> undo() async {
    if (!canUndo || _board == null) return;

    final action = _history[_historyIndex];
    final cell = _board!.getCell(action.row, action.col);

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

    _syncBoardStateDebounced(isCompleted: false);

    notifyListeners();
  }

  Future<void> redo() async {
    if (!canRedo || _board == null) return;

    _historyIndex++;
    final action = _history[_historyIndex];
    final cell = _board!.getCell(action.row, action.col);

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

    _syncBoardStateDebounced(isCompleted: false);

    notifyListeners();
  }

  Future<void> resetBoard() async {
    if (_originalBoard == null) return;

    _board = _originalBoard!.clone();
    _mistakes = 0;
    _hintsUsed = 0;
    _history.clear();
    _historyIndex = -1;
    clearSelection();

    _syncBoardStateDebounced(isCompleted: false);
    _syncPlayerStatsDebounced();

    notifyListeners();
  }

  Future<void> leaveMatch() async {
    if (_currentMatch == null) return;

    try {
      await _matchmakingService
          .leaveMatch(_currentMatch!.matchId, userId)
          .timeout(_timeout);
      await _cleanup();
    } catch (e) {
      SecureLogger.error('Failed to leave match', error: e);
    }
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _startTimeoutCheck() {
    _timeoutCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_currentMatch != null && _currentMatch!.hasTimedOut) {
        await _matchmakingService.handleTimeout(_currentMatch!.matchId);
      }
    });
  }

  void _stopTimeoutCheck() {
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _updateConnectionState(ConnectionState.online);

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_currentMatch != null && !_currentMatch!.isCompleted) {
        await _sendHeartbeat();
      }
    });

    SecureLogger.log('Heartbeat started', tag: 'Connection');
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    if (_currentMatch == null) return;

    try {
      await _matchmakingService
          .updateConnectionState(
            matchId: _currentMatch!.matchId,
            userId: userId,
            isConnected: true,
          )
          .timeout(_timeout);

      if (_connectionState == ConnectionState.reconnecting) {
        _updateConnectionState(ConnectionState.online);
        SecureLogger.log('Reconnection successful', tag: 'Connection');
      }
    } catch (e) {
      SecureLogger.error('Heartbeat failed', error: e);

      if (_connectionState == ConnectionState.online) {
        _handleConnectionLoss();
      }
    }
  }

  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      SecureLogger.log('Connection state: $newState', tag: 'Connection');
      notifyListeners();
    }
  }

  void _handleConnectionLoss() {
    _updateConnectionState(ConnectionState.reconnecting);
    SecureLogger.log(
      'Connection lost, attempting to reconnect...',
      tag: 'Connection',
    );

    _attemptReconnection();
  }

  Future<void> _attemptReconnection() async {
    if (_currentMatch == null) return;

    final reconnectionStartTime = DateTime.now();

    try {
      await _sendHeartbeat();
    } catch (e) {
      final timeSinceStart = DateTime.now().difference(reconnectionStartTime);

      if (timeSinceStart > _reconnectionGracePeriod) {
        _updateConnectionState(ConnectionState.offline);
        SecureLogger.log(
          'Reconnection grace period expired',
          tag: 'Connection',
        );

        try {
          await _matchmakingService
              .updateConnectionState(
                matchId: _currentMatch!.matchId,
                userId: userId,
                isConnected: false,
              )
              .timeout(_timeout);
        } catch (firestoreError) {
          SecureLogger.error(
            'Failed to update disconnected state',
            error: firestoreError,
          );
        }
      }
    }
  }

  Future<void> _cleanup({bool isDisposing = false}) async {
    _stopTimer();
    _stopTimeoutCheck();
    _stopHeartbeat();

    _boardSyncDebouncer.dispose();
    _statsSyncDebouncer.dispose();

    if (_currentMatch != null && _connectionState != ConnectionState.offline) {
      try {
        await _matchmakingService
            .updateConnectionState(
              matchId: _currentMatch!.matchId,
              userId: userId,
              isConnected: false,
            )
            .timeout(_timeout);
      } catch (e) {
        SecureLogger.error(
          'Failed to update connection state on cleanup',
          error: e,
        );
      }
    }

    await _matchSubscription?.cancel();
    _matchSubscription = null;
    _currentMatch = null;
    _board = null;
    _originalBoard = null;
    _solvedBoard = null;
    _connectionState = ConnectionState.offline;

    // Only clear selection and notify listeners if not disposing
    if (!isDisposing) {
      clearSelection();
      notifyListeners();
    } else {
      // Just clear the selection state without notifying
      _selectedRow = null;
      _selectedCol = null;
    }
  }

  @override
  void dispose() {
    // Prevent double-dispose
    if (_isDisposed) return;

    // Mark as disposed to prevent any pending callbacks from calling notifyListeners
    _isDisposed = true;

    // Call cleanup synchronously without awaiting to avoid async operations after dispose
    _stopTimer();
    _stopTimeoutCheck();
    _stopHeartbeat();

    // Cancel subscription first before disposing debouncers
    _matchSubscription?.cancel();
    _matchSubscription = null;

    // Dispose debouncers
    _boardSyncDebouncer.dispose();
    _statsSyncDebouncer.dispose();

    // Clear state
    _currentMatch = null;
    _board = null;
    _originalBoard = null;
    _solvedBoard = null;
    _selectedRow = null;
    _selectedCol = null;

    super.dispose();
  }
}
