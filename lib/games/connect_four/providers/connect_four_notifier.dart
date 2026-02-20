import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

import '../logic/connect_four_logic.dart';
import '../models/connect_four_enums.dart';
import '../models/connect_four_state.dart';

final connectFourProvider =
    NotifierProvider.autoDispose<ConnectFourNotifier, ConnectFourState>(
  ConnectFourNotifier.new,
);

class ConnectFourNotifier extends GameStatsNotifier<ConnectFourState> {
  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  ConnectFourState build() {
    ref.onDispose(() {
      _botTimer?.cancel();
      _botTimer = null;
    });
    return const ConnectFourState();
  }

  Timer? _botTimer;

  // ── Public API ─────────────────────────────────────────────────────────────

  void startSolo(ConnectFourDifficulty difficulty) {
    state = ConnectFourState(
      grid: ConnectFourState.emptyGrid(),
      phase: ConnectFourPhase.playing,
      mode: ConnectFourMode.solo,
      difficulty: difficulty,
      currentPlayer: 1,
    );
  }

  void startPassAndPlay() {
    state = ConnectFourState(
      grid: ConnectFourState.emptyGrid(),
      phase: ConnectFourPhase.playing,
      mode: ConnectFourMode.passAndPlay,
      currentPlayer: 1,
    );
  }

  /// Human drops a piece in [col]. Ignored if it's the bot's turn or game is over.
  void dropInColumn(int col) {
    if (state.phase != ConnectFourPhase.playing) {
      return;
    }
    if (state.isBotTurn) {
      return;
    }

    _applyDrop(col);
  }

  void restartGame() {
    _botTimer?.cancel();
    if (state.mode == ConnectFourMode.solo) {
      startSolo(state.difficulty);
    } else {
      startPassAndPlay();
    }
  }

  void goToIdle() {
    _botTimer?.cancel();
    state = const ConnectFourState();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _applyDrop(int col) {
    final row = landingRow(state.grid, col);
    if (row == -1) {
      return; // column full
    }

    final player = state.currentPlayer;
    final newGrid = dropPiece(state.grid, col, row, player);
    final win = checkWin(newGrid, col, row, player);

    if (win.isNotEmpty) {
      state = state.copyWith(
        grid: newGrid,
        phase: ConnectFourPhase.won,
        winLine: win,
        dropAnimCol: col,
      );
      if (player == 1) {
        saveScore('connect_four', 1);
      }
      return;
    }

    if (isDraw(newGrid)) {
      state = state.copyWith(
        grid: newGrid,
        phase: ConnectFourPhase.draw,
        dropAnimCol: col,
      );
      return;
    }

    final nextPlayer = player == 1 ? 2 : 1;
    state = state.copyWith(
      grid: newGrid,
      currentPlayer: nextPlayer,
      dropAnimCol: col,
    );

    // Schedule bot move after a short delay so the piece drop animates first
    if (state.isBotTurn) {
      _scheduleBotMove();
    }
  }

  void _scheduleBotMove() {
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 500), () {
      if (state.phase != ConnectFourPhase.playing) {
        return;
      }
      final col = getBotMove(state.grid, state.difficulty, 2);
      if (col != -1) {
        _applyDrop(col);
      }
    });
  }
}
