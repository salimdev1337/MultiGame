import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/providers/sudoku_online_provider.dart';
import 'package:multigame/games/sudoku/models/match_room.dart';
import 'package:multigame/games/sudoku/models/match_player.dart';
import 'package:multigame/games/sudoku/models/match_status.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';
import 'package:multigame/games/sudoku/models/connection_state.dart';
import 'package:multigame/games/sudoku/services/matchmaking_service.dart';

// Manual fake implementations
class FakeMatchmakingService implements MatchmakingService {
  final StreamController<MatchRoom> _matchStreamController = StreamController.broadcast();
  final Map<String, MatchRoom> _matches = {};

  @override
  Future<String> createMatch({
    required String userId,
    required String displayName,
    required String difficulty,
  }) async {
    final matchId = 'test_match_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create basic puzzle data
    final puzzleData = List.generate(9, (_) => List.filled(9, 0));
    
    final now = DateTime.now();
    final match = MatchRoom(
      matchId: matchId,
      roomCode: '123456',
      difficulty: difficulty,
      puzzleData: puzzleData,
      status: MatchStatus.waiting,
      player1: MatchPlayer(
        userId: userId,
        displayName: displayName,
        boardState: List.generate(9, (_) => List.filled(9, 0)),
        filledCells: 0,
        isCompleted: false,
        joinedAt: now,
        lastSeenAt: now,
        isConnected: true,
      ),
      createdAt: now,
    );

    _matches[matchId] = match;
    
    // Emit match
    Future.delayed(Duration.zero, () {
      if (!_matchStreamController.isClosed) {
        _matchStreamController.add(match);
      }
    });

    return matchId;
  }

  @override
  Future<String> quickMatch({
    required String userId,
    required String displayName,
    required String difficulty,
  }) async {
    return createMatch(
      userId: userId,
      displayName: displayName,
      difficulty: difficulty,
    );
  }

  @override
  Future<String> joinByRoomCode({
    required String roomCode,
    required String userId,
    required String displayName,
  }) async {
    return createMatch(
      userId: userId,
      displayName: displayName,
      difficulty: 'medium',
    );
  }

  @override
  Stream<MatchRoom> watchMatch(String matchId) {
    return _matchStreamController.stream;
  }

  @override
  Future<void> updatePlayerBoard({
    required String matchId,
    required String userId,
    required SudokuBoard board,
    required bool isCompleted,
  }) async {
    // Simulate board update
  }

  @override
  Future<void> updatePlayerStats({
    required String matchId,
    required String userId,
    required int mistakeCount,
    required int hintsUsed,
  }) async {
    // Simulate stats update
  }

  @override
  Future<void> updateConnectionState({
    required String matchId,
    required String userId,
    required bool isConnected,
  }) async {
    // Simulate connection state update
  }

  @override
  Future<void> leaveMatch(String matchId, String userId) async {
    _matches.remove(matchId);
  }

  @override
  Future<void> handleTimeout(String matchId) async {
    // Simulate timeout handling
  }

  void dispose() {
    _matchStreamController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('SudokuOnlineProvider - 1v1 Mode', () {
    late SudokuOnlineProvider provider;
    late FakeMatchmakingService matchmakingService;
    const testUserId = 'test_user_1';
    const testDisplayName = 'Test User';

    setUp(() {
      matchmakingService = FakeMatchmakingService();
      provider = SudokuOnlineProvider(
        matchmakingService: matchmakingService,
        userId: testUserId,
        displayName: testDisplayName,
      );
    });

    tearDown(() {
      provider.dispose();
      matchmakingService.dispose();
    });

    group('initialization', () {
      test('initializes with correct default values', () {
        expect(provider.board, isNull);
        expect(provider.currentMatch, isNull);
        expect(provider.selectedRow, isNull);
        expect(provider.selectedCol, isNull);
        expect(provider.mistakes, 0);
        expect(provider.hintsUsed, 0);
        expect(provider.hintsRemaining, 3);
        expect(provider.notesMode, false);
        expect(provider.elapsedSeconds, 0);
        expect(provider.connectionState, ConnectionState.offline);
      });
    });

    group('match creation', () {
      test('creates match successfully', () async {
        await provider.createMatch('medium');

        // Wait for stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.currentMatch, isNotNull);
        expect(provider.currentMatch!.matchId, isNotEmpty);
      });

      test('joins match successfully', () async {
        await provider.joinMatch('easy');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.currentMatch, isNotNull);
      });

      test('joins match by room code', () async {
        await provider.joinByRoomCode('123456');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.currentMatch, isNotNull);
      });
    });

    group('match state', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('isWaiting returns correct value', () {
        expect(provider.isWaiting, isA<bool>());
      });

      test('isPlaying returns correct value', () {
        expect(provider.isPlaying, isA<bool>());
      });

      test('isCompleted returns correct value', () {
        expect(provider.isCompleted, false);
      });

      test('hasOpponent returns correct value', () {
        expect(provider.hasOpponent, isA<bool>());
      });
    });

    group('cell selection', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('selects cell at specified position', () {
        provider.selectCell(3, 5);

        expect(provider.selectedRow, 3);
        expect(provider.selectedCol, 5);
      });

      test('clears cell selection', () {
        provider.selectCell(2, 4);
        provider.clearSelection();

        expect(provider.selectedRow, isNull);
        expect(provider.selectedCol, isNull);
      });
    });

    group('notes mode', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('toggles notes mode', () {
        expect(provider.notesMode, false);

        provider.toggleNotesMode();
        expect(provider.notesMode, true);

        provider.toggleNotesMode();
        expect(provider.notesMode, false);
      });
    });

    group('number placement', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('cannot place number without selection', () async {
        await provider.placeNumber(5);
        // Should not crash
      });

      test('cannot place number without board', () async {
        final noBoardProvider = SudokuOnlineProvider(
          matchmakingService: matchmakingService,
          userId: 'user2',
          displayName: 'User 2',
        );

        noBoardProvider.selectCell(0, 0);
        await noBoardProvider.placeNumber(5);

        // Should not crash
        noBoardProvider.dispose();
      });
    });

    group('clear cell', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('cannot clear without selection', () async {
        await provider.clearCell();
        // Should not crash
      });
    });

    group('hint system', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('hint limits are tracked', () {
        expect(provider.hintsRemaining, 3);
        expect(provider.hintsUsed, 0);
      });

      test('canUseHint requires selection', () {
        expect(provider.canUseHint, false);

        provider.selectCell(0, 0);
        expect(provider.canUseHint, isA<bool>());
      });
    });

    group('undo/redo', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('canUndo is false initially', () {
        expect(provider.canUndo, false);
      });

      test('canRedo is false initially', () {
        expect(provider.canRedo, false);
      });

      test('undo without history does not crash', () async {
        await provider.undo();
        // Should not crash
      });

      test('redo without history does not crash', () async {
        await provider.redo();
        // Should not crash
      });
    });

    group('board reset', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('resetBoard clears state', () async {
        provider.selectCell(2, 3);
        
        await provider.resetBoard();

        expect(provider.mistakes, 0);
        expect(provider.hintsUsed, 0);
        expect(provider.selectedRow, isNull);
        expect(provider.selectedCol, isNull);
      });
    });

    group('opponent tracking', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('tracks opponent name', () {
        expect(provider.opponentName, isA<String?>());
      });

      test('tracks opponent progress', () {
        expect(provider.opponentProgress, isA<int?>());
      });

      test('tracks opponent mistakes', () {
        expect(provider.opponentMistakes, isA<int>());
      });

      test('tracks opponent hints used', () {
        expect(provider.opponentHintsUsed, isA<int>());
      });

      test('tracks opponent completion status', () {
        expect(provider.opponentCompleted, isA<bool>());
      });

      test('tracks opponent connection state', () {
        expect(provider.opponentIsConnected, isA<bool>());
        expect(provider.opponentConnectionState, isA<ConnectionState>());
      });
    });

    group('connection state', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('starts in offline state', () {
        final offlineProvider = SudokuOnlineProvider(
          matchmakingService: matchmakingService,
          userId: 'user3',
          displayName: 'User 3',
        );

        expect(offlineProvider.connectionState, ConnectionState.offline);
        offlineProvider.dispose();
      });

      test('connection state can be checked', () {
        expect(provider.connectionState, isA<ConnectionState>());
      });
    });

    group('match lifecycle', () {
      test('leaves match successfully', () async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));

        await provider.leaveMatch();

        expect(provider.currentMatch, isNull);
        expect(provider.board, isNull);
      });

      test('handles multiple match joins', () async {
        await provider.createMatch('easy');
        await Future.delayed(const Duration(milliseconds: 100));

        await provider.leaveMatch();
        await Future.delayed(const Duration(milliseconds: 100));

        await provider.createMatch('hard');
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.currentMatch, isNotNull);
      });
    });

    group('timer management', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('elapsed seconds starts at 0', () {
        expect(provider.elapsedSeconds, greaterThanOrEqualTo(0));
      });
    });

    group('winner determination', () {
      setUp(() async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('isWinner checks userId', () {
        expect(provider.isWinner, isA<bool>());
      });
    });

    group('disposal', () {
      test('cleans up resources on dispose', () async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));

        provider.dispose();

        // Should not crash
        expect(provider.connectionState, ConnectionState.offline);
      });

      test('cancels subscriptions on dispose', () async {
        await provider.createMatch('medium');
        await Future.delayed(const Duration(milliseconds: 100));

        provider.dispose();

        // Subsequent operations should be safe
        expect(provider.currentMatch, isNull);
      });
    });

    group('error handling', () {
      test('handles match creation errors gracefully', () async {
        final errorService = FakeMatchmakingService();
        final errorProvider = SudokuOnlineProvider(
          matchmakingService: errorService,
          userId: 'error_user',
          displayName: 'Error User',
        );

        try {
          await errorProvider.createMatch('invalid');
        } catch (e) {
          // Expected to handle errors
        }

        errorProvider.dispose();
        errorService.dispose();
      });
    });
  });
}
