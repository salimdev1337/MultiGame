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

/// Provider for online 1v1 Sudoku game state
class SudokuOnlineProvider with ChangeNotifier {
  final MatchmakingService _matchmakingService;
  final String userId;
  final String displayName;

  // Game state
  SudokuBoard? _board;
  SudokuBoard? _originalBoard;
  SudokuBoard? _solvedBoard; // Pre-solved board for hints
  MatchRoom? _currentMatch;
  StreamSubscription<MatchRoom>? _matchSubscription;

  // Selection state
  int? _selectedRow;
  int? _selectedCol;

  // Game tracking
  int _mistakes = 0;
  int _hintsUsed = 0;
  bool _notesMode = false;
  final List<SudokuAction> _history = [];
  int _historyIndex = -1;

  // Timer
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  Timer? _timeoutCheckTimer;

  // Debounced sync (Phase 3)
  final Debouncer _boardSyncDebouncer = Debouncer(delay: const Duration(seconds: 2));
  final Debouncer _statsSyncDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  // Connection handling (Phase 4)
  ConnectionState _connectionState = ConnectionState.offline;
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 5);
  static const Duration _reconnectionGracePeriod = Duration(seconds: 60);

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
  int get hintsUsed => _hintsUsed;
  int get hintsRemaining => 3 - _hintsUsed;
  bool get canUseHint => _hintsUsed < 3 && _selectedRow != null && _selectedCol != null;
  bool get notesMode => _notesMode;
  int get elapsedSeconds => _elapsedSeconds;
  bool get canUndo => _historyIndex >= 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  ConnectionState get connectionState => _connectionState;

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

  /// Get opponent's mistake count (Phase 3)
  int get opponentMistakes => _currentMatch?.getOpponent(userId)?.mistakeCount ?? 0;

  /// Get opponent's hints used (Phase 3)
  int get opponentHintsUsed => _currentMatch?.getOpponent(userId)?.hintsUsed ?? 0;

  /// Get opponent's connection state (Phase 3)
  bool get opponentIsConnected => _currentMatch?.getOpponent(userId)?.isConnected ?? false;

  /// Get opponent's connection state as ConnectionState enum (Phase 6)
  ConnectionState get opponentConnectionState =>
      opponentIsConnected ? ConnectionState.online : ConnectionState.offline;

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

  /// Join a match using a room code (Phase 5)
  Future<void> joinByRoomCode(String roomCode) async {
    try {
      final matchId = await _matchmakingService.joinByRoomCode(
        roomCode: roomCode,
        userId: userId,
        displayName: displayName,
      );

      // Start listening to match updates
      await _listenToMatch(matchId);
    } catch (e) {
      SecureLogger.error('Failed to join match by room code', error: e);
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
          _startHeartbeat(); // Phase 4: Start connection monitoring
        }

        // Handle match completion
        if (matchRoom.isCompleted) {
          _stopTimer();
          _stopTimeoutCheck();
          _stopHeartbeat(); // Phase 4: Stop heartbeat on completion
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

    // Pre-solve board for hints (Phase 3)
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

      // Sync with debouncing (Phase 3)
      // Board sync: 2s delay to batch multiple moves
      // Stats sync: 500ms delay for responsive opponent stats
      _syncBoardStateDebounced(isCompleted: isSolved);
      _syncPlayerStatsDebounced();
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

    // Sync with debouncing (Phase 3)
    _syncBoardStateDebounced(isCompleted: false);

    notifyListeners();
  }

  /// Use a hint to reveal the correct value for the selected cell (Phase 3)
  ///
  /// Limits: 3 hints per game
  /// Only works on empty, non-fixed cells
  Future<void> useHint() async {
    if (_board == null ||
        _solvedBoard == null ||
        _selectedRow == null ||
        _selectedCol == null ||
        _currentMatch?.isCompleted == true) {
      return;
    }

    // Check hint limit
    if (_hintsUsed >= 3) {
      SecureLogger.log('Hint limit reached (3/3)', tag: 'Hints');
      return;
    }

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);

    // Can't use hint on fixed cells
    if (cell.isFixed) return;

    // Can't use hint if cell is already filled
    if (cell.hasValue) {
      SecureLogger.log('Cell already has a value', tag: 'Hints');
      return;
    }

    // Get correct value from solved board
    final correctValue = _solvedBoard!.getCell(_selectedRow!, _selectedCol!).value;
    if (correctValue == null) {
      SecureLogger.error('Solved board has no value for this cell');
      return;
    }

    // Save state for undo
    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    _saveState(SudokuAction.setValue(
      row: _selectedRow!,
      col: _selectedCol!,
      value: correctValue,
      previousValue: previousValue,
      previousNotes: previousNotes,
    ));

    // Place the correct value
    cell.value = correctValue;
    cell.notes.clear();
    cell.isError = false; // Hints are always correct

    // Increment hints used
    _hintsUsed++;

    // Clear any errors (hints might resolve conflicts)
    _board!.clearErrors();
    final conflicts = SudokuValidator.getConflictPositions(_board!);
    for (final pos in conflicts) {
      _board!.getCell(pos.row, pos.col).isError = true;
    }

    // Check if puzzle is solved
    final isSolved = SudokuValidator.isSolved(_board!);

    // Sync with debouncing
    _syncBoardStateDebounced(isCompleted: isSolved);
    _syncPlayerStatsDebounced();

    SecureLogger.log('Hint used: $_hintsUsed/3', tag: 'Hints');

    notifyListeners();
  }

  /// Sync board state to Firestore (immediate)
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

  /// Sync board state with debouncing (Phase 3)
  ///
  /// Reduces Firestore writes by waiting 2 seconds before syncing
  /// If multiple moves are made, only the final state is synced
  void _syncBoardStateDebounced({required bool isCompleted}) {
    if (_board == null || _currentMatch == null) return;

    _boardSyncDebouncer.run(() async {
      await _syncBoardState(isCompleted: isCompleted);
    });
  }

  /// Sync player stats (mistakes and hints) separately (Phase 3)
  ///
  /// Lightweight update that syncs stats without full board state
  /// Uses shorter debounce (500ms) for more responsive opponent stats
  void _syncPlayerStatsDebounced() {
    if (_currentMatch == null) return;

    _statsSyncDebouncer.run(() async {
      try {
        await _matchmakingService.updatePlayerStats(
          matchId: _currentMatch!.matchId,
          userId: userId,
          mistakeCount: _mistakes,
          hintsUsed: _hintsUsed,
        );
      } catch (e) {
        SecureLogger.error('Failed to sync player stats', error: e);
      }
    });
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

    // Sync with debouncing (Phase 3)
    _syncBoardStateDebounced(isCompleted: false);

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

    // Sync with debouncing (Phase 3)
    _syncBoardStateDebounced(isCompleted: false);

    notifyListeners();
  }

  /// Reset board to original state
  Future<void> resetBoard() async {
    if (_originalBoard == null) return;

    _board = _originalBoard!.clone();
    _mistakes = 0;
    _hintsUsed = 0;
    _history.clear();
    _historyIndex = -1;
    clearSelection();

    // Sync with debouncing (Phase 3)
    _syncBoardStateDebounced(isCompleted: false);
    _syncPlayerStatsDebounced();

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

  /// Start heartbeat to maintain connection (Phase 4)
  ///
  /// Sends periodic updates to Firestore to indicate the player is online
  /// Heartbeat runs every 5 seconds while the match is active
  void _startHeartbeat() {
    _stopHeartbeat();

    // Set initial connection state to online
    _updateConnectionState(ConnectionState.online);

    // Start periodic heartbeat
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_currentMatch != null && !_currentMatch!.isCompleted) {
        await _sendHeartbeat();
      }
    });

    SecureLogger.log('Heartbeat started', tag: 'Connection');
  }

  /// Stop heartbeat timer (Phase 4)
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send heartbeat to Firestore (Phase 4)
  ///
  /// Updates connection state and lastSeenAt timestamp
  Future<void> _sendHeartbeat() async {
    if (_currentMatch == null) return;

    try {
      await _matchmakingService.updateConnectionState(
        matchId: _currentMatch!.matchId,
        userId: userId,
        isConnected: true,
      );

      // If we were reconnecting, mark as online
      if (_connectionState == ConnectionState.reconnecting) {
        _updateConnectionState(ConnectionState.online);
        SecureLogger.log('Reconnection successful', tag: 'Connection');
      }
    } catch (e) {
      SecureLogger.error('Heartbeat failed', error: e);

      // If heartbeat fails, attempt reconnection
      if (_connectionState == ConnectionState.online) {
        _handleConnectionLoss();
      }
    }
  }

  /// Update connection state (Phase 4)
  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      SecureLogger.log('Connection state: $newState', tag: 'Connection');
      notifyListeners();
    }
  }

  /// Handle connection loss (Phase 4)
  ///
  /// Initiates reconnection attempts with 60-second grace period
  void _handleConnectionLoss() {
    _updateConnectionState(ConnectionState.reconnecting);
    SecureLogger.log('Connection lost, attempting to reconnect...', tag: 'Connection');

    // Start reconnection attempts
    _attemptReconnection();
  }

  /// Attempt to reconnect (Phase 4)
  ///
  /// Tries to restore connection by sending heartbeats
  /// If grace period expires without success, marks as offline
  Future<void> _attemptReconnection() async {
    if (_currentMatch == null) return;

    final reconnectionStartTime = DateTime.now();

    // Try to reconnect by sending heartbeat
    try {
      await _sendHeartbeat();
      // Success handled in _sendHeartbeat
    } catch (e) {
      // Check if grace period has expired
      final timeSinceStart = DateTime.now().difference(reconnectionStartTime);

      if (timeSinceStart > _reconnectionGracePeriod) {
        // Grace period expired, mark as offline
        _updateConnectionState(ConnectionState.offline);
        SecureLogger.log('Reconnection grace period expired', tag: 'Connection');

        // Update Firestore to mark as disconnected
        try {
          await _matchmakingService.updateConnectionState(
            matchId: _currentMatch!.matchId,
            userId: userId,
            isConnected: false,
          );
        } catch (firestoreError) {
          SecureLogger.error('Failed to update disconnected state', error: firestoreError);
        }
      }
    }
  }

  /// Clean up resources
  Future<void> _cleanup() async {
    // Stop all timers
    _stopTimer();
    _stopTimeoutCheck();
    _stopHeartbeat(); // Phase 4: Stop heartbeat timer

    // Dispose debouncers
    _boardSyncDebouncer.dispose();
    _statsSyncDebouncer.dispose();

    // Update connection state to offline before leaving
    if (_currentMatch != null && _connectionState != ConnectionState.offline) {
      try {
        await _matchmakingService.updateConnectionState(
          matchId: _currentMatch!.matchId,
          userId: userId,
          isConnected: false,
        );
      } catch (e) {
        SecureLogger.error('Failed to update connection state on cleanup', error: e);
      }
    }

    // Cancel subscriptions and clear state
    await _matchSubscription?.cancel();
    _matchSubscription = null;
    _currentMatch = null;
    _board = null;
    _originalBoard = null;
    _solvedBoard = null;
    _connectionState = ConnectionState.offline;
    clearSelection();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
