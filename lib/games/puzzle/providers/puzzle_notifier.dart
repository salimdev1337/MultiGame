import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/puzzle/logic/puzzle_game_logic.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/utils/secure_logger.dart';

class PuzzleState {
  final PuzzleGame? game;
  final int gridSize;
  final int moveCount;
  final int elapsedSeconds;

  const PuzzleState({
    this.game,
    this.gridSize = 4,
    this.moveCount = 0,
    this.elapsedSeconds = 0,
  });

  bool get isGameInitialized => game != null;

  PuzzleState copyWith({
    PuzzleGame? game,
    int? gridSize,
    int? moveCount,
    int? elapsedSeconds,
  }) {
    return PuzzleState(
      game: game ?? this.game,
      gridSize: gridSize ?? this.gridSize,
      moveCount: moveCount ?? this.moveCount,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  String formatTime() {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class PuzzleNotifier extends GameStatsNotifier<PuzzleState> {
  late AchievementService _achievementService;
  Timer? _timer;

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  PuzzleState build() {
    _achievementService = ref.read(achievementServiceProvider);
    ref.onDispose(() => _timer?.cancel());
    return const PuzzleState();
  }

  Future<void> initializeGame() async {
    _cancelTimer();
    final game = PuzzleGame(gridSize: state.gridSize);
    await game.loadPuzzleImages();
    state = state.copyWith(game: game, moveCount: 0, elapsedSeconds: 0);
    _startTimer();
  }

  Future<void> resetGame() async {
    if (state.game == null) return;
    _cancelTimer();
    await state.game!.loadPuzzleImages();
    state = state.copyWith(moveCount: 0, elapsedSeconds: 0);
    _startTimer();
  }

  Future<void> newImageGame() async {
    if (state.game == null) return;
    _cancelTimer();
    await state.game!.loadNewPuzzle();
    state = state.copyWith(moveCount: 0, elapsedSeconds: 0);
    _startTimer();
  }

  Future<void> changeGridSize(int newSize) async {
    if (newSize == state.gridSize) return;
    _cancelTimer();
    // Reuse the cached image URL so no extra network fetch is needed.
    final cachedUrl = state.game?.currentImageUrl;
    final game = PuzzleGame(gridSize: newSize, initialImageUrl: cachedUrl);
    await game.loadPuzzleImages();
    state = state.copyWith(
      game: game,
      gridSize: newSize,
      moveCount: 0,
      elapsedSeconds: 0,
    );
    _startTimer();
  }

  bool movePiece(int position) {
    final game = state.game;
    if (game == null || !game.movePiece(position)) return false;

    final newMoves = state.moveCount + 1;
    state = state.copyWith(moveCount: newMoves);

    if (game.isSolved) {
      _cancelTimer();
      _saveScore(newMoves);
    }
    return true;
  }

  Future<List<String>> recordGameCompletion() async {
    if (state.game == null) return [];
    return _achievementService.recordGameCompletion(
      gridSize: state.gridSize,
      moves: state.moveCount,
      seconds: state.elapsedSeconds,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final game = state.game;
      if (game == null || game.isSolved) {
        _cancelTimer();
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _saveScore(int moves) {
    if (moves > 0) {
      final score = (10000 - (moves * 10) - state.elapsedSeconds).clamp(
        0,
        10000,
      );
      SecureLogger.firebase('Saving puzzle score', details: 'score: $score');
      saveScore('puzzle', score);
    }
  }
}

final puzzleProvider =
    NotifierProvider.autoDispose<PuzzleNotifier, PuzzleState>(
      PuzzleNotifier.new,
    );
