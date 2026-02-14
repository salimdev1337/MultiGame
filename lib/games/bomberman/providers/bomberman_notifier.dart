import 'dart:async';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/bomberman/logic/bomb_logic.dart';
import 'package:multigame/games/bomberman/logic/bot_ai.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// ─── Player body half-size used for wall collision ────────────────────────────

const _kPlayerRadius = 0.35; // cells — player body is 0.7×0.7 cells

// ─── Input state ─────────────────────────────────────────────────────────────

class _InputState {
  double dx = 0;
  double dy = 0;
  bool wantBomb = false;
}

// ─── Provider ────────────────────────────────────────────────────────────────

final bombermanProvider =
    NotifierProvider.autoDispose<BombermanNotifier, BombGameState>(
  BombermanNotifier.new,
);

// ─── Notifier ────────────────────────────────────────────────────────────────

class BombermanNotifier extends GameStatsNotifier<BombGameState> {
  static const _countdownSec = 3;
  // Bot AI recalculates its decision every N ticks (movement still applied every tick)
  static const _botAiInterval = 6;
  static const _fuseMs = 2500;

  // Frame-synced game loop — fires once per vsync so physics and rendering
  // are always in lockstep, eliminating the timer/vsync desync wiggle.
  bool _loopActive = false;
  Duration? _lastFrameTimestamp;

  Timer? _countdownTimer;
  int _nextBombId = 0;
  int _tickCount = 0;
  double _roundTimeAccum = 0.0; // seconds accumulated toward next round-second decrement

  BotDifficulty _difficulty = BotDifficulty.medium;
  // Last bot decisions, refreshed every _botAiInterval ticks
  final _botDecisions = <int, ({double dx, double dy, bool placeBomb})>{};

  final _input = _InputState();
  final _rng = Random();

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  BombGameState build() {
    ref.onDispose(_dispose);
    return _emptyState();
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  void startSolo([BotDifficulty difficulty = BotDifficulty.medium]) {
    _difficulty = difficulty;
    _dispose();

    // Bot speed varies by difficulty (cells/sec — same unit as player 6.0)
    final botSpeed = switch (difficulty) {
      BotDifficulty.easy => 3.5,
      BotDifficulty.medium => 5.0,
      BotDifficulty.hard => 7.0,
    };

    final grid = MapGenerator.generate(seed: _rng.nextInt(9999));
    // Spawn at cell CENTRES: cell (c,r) centre = (c+0.5, r+0.5)
    final players = [
      BombPlayer(id: 0, x: 1.5, y: 1.5, displayName: 'You'),
      BombPlayer(
        id: 1,
        x: kGridW - 1.5,
        y: 1.5,
        speed: botSpeed,
        isBot: true,
        displayName: 'Bot',
      ),
    ];
    state = BombGameState(
      grid: grid,
      players: players,
      roundWins: List.filled(players.length, 0),
      phase: GamePhase.countdown,
      countdown: _countdownSec,
    );
    _startCountdown();
  }

  void setInput({double dx = 0, double dy = 0}) {
    _input.dx = dx;
    _input.dy = dy;
  }

  void pressPlaceBomb() {
    _input.wantBomb = true;
  }

  void reset() {
    _dispose();
    state = _emptyState();
  }

  // ─── Countdown ─────────────────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final newCount = state.countdown - 1;
      if (newCount <= 0) {
        t.cancel();
        state = state.copyWith(phase: GamePhase.playing, countdown: 0);
        _startLoop();
      } else {
        state = state.copyWith(countdown: newCount);
      }
    });
  }

  // ─── Game loop ─────────────────────────────────────────────────────────────

  void _startLoop() {
    _loopActive = true;
    _lastFrameTimestamp = null;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!_loopActive || state.phase != GamePhase.playing) {
      _loopActive = false;
      return;
    }
    // Compute actual elapsed time; clamp to 1/15s so a background-then-foreground
    // resume doesn't cause a huge physics jump.
    final rawDt = _lastFrameTimestamp == null
        ? 1 / 60.0
        : (timestamp - _lastFrameTimestamp!).inMicroseconds / 1e6;
    _lastFrameTimestamp = timestamp;
    final dt = rawDt.clamp(0.0, 1 / 15.0);

    _tick(dt);

    if (_loopActive && state.phase == GamePhase.playing) {
      SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
    }
  }

  // Kept as a helper so bomb-tick duration (in ms) stays consistent.
  // dt is now the real elapsed seconds since the last vsync frame.
  void _tick(double dt) {
    if (state.phase != GamePhase.playing) return;

    _tickCount++;
    final dtMs = (dt * 1000).round();

    var s = state;

    // 1. Bot AI — run every tick so bots respond smoothly to cell-by-cell movement
    s = _runBots(s, dt);

    // 2. Move human player
    s = _movePlayer(s, 0, _input.dx, _input.dy, dt);

    // 3. Place bomb?
    if (_input.wantBomb) {
      _input.wantBomb = false;
      s = _tryPlaceBomb(s, 0);
    }

    // 4. Countdown bombs
    s = _tickBombs(s, dtMs);

    // 5. Fade explosions
    s = _tickExplosions(s, dtMs);

    // 6. Collect powerups
    final collected = BombLogic.collectPowerups(
      players: s.players,
      powerups: s.powerups,
    );
    s = s.copyWith(players: collected.players, powerups: collected.powerups);

    // 7. Round time — accumulate real elapsed seconds; decrement once per second
    _roundTimeAccum += dt;
    if (_roundTimeAccum >= 1.0) {
      _roundTimeAccum -= 1.0;
      final newTime = s.roundTimeSeconds - 1;
      if (newTime <= 0) {
        s = s.copyWith(roundTimeSeconds: 0);
        state = s;
        _handleRoundTimeout();
        return;
      }
      s = s.copyWith(roundTimeSeconds: newTime);
    }

    // 8. Win condition — last LIVING (non-ghost) player standing
    final living = s.players.where((p) => p.isAlive && !p.isGhost).toList();
    if (living.length <= 1) {
      state = s;
      _handleRoundEnd(living.isEmpty ? null : living.first.id);
      return;
    }

    state = s;
  }

  // ─── Movement ──────────────────────────────────────────────────────────────
  //
  // Free-form movement with perpendicular auto-alignment:
  //   • Moving horizontally → X slides freely, Y is gently pulled to the
  //     nearest cell centre (N + 0.5).
  //   • Moving vertically   → Y slides freely, X is gently pulled to centre.
  //
  // The alignment eliminates off-axis wiggle and makes turns easy: by the time
  // the player reaches a junction the cross axis is already centred.

  BombGameState _movePlayer(
    BombGameState s, int playerId, double dx, double dy, double dt,
  ) {
    final p = s.players[playerId];
    if (!p.isAlive) return s;

    // Normalise to 4-direction: keep only the dominant axis
    final adx = dx.abs(), ady = dy.abs();
    final ndx = adx >= ady ? dx.sign : 0.0;
    final ndy = adx >= ady ? 0.0 : dy.sign;

    if (ndx == 0 && ndy == 0) return s;

    final step = p.speed * dt;

    double nx, ny;
    // Alignment runs at 2× movement speed so the player centres in ~1 tick
    // when close, making direction changes feel immediate.
    final alignStep = step * 2.0;

    if (ndx != 0) {
      // Horizontal movement — slide X, align Y to cell centre
      nx = _slideAxis(p.x, p.y, ndx, step, s, p, isHorizontal: true);
      ny = _centerAlign(p.y, alignStep);
    } else {
      // Vertical movement — slide Y, align X to cell centre
      ny = _slideAxis(p.y, p.x, ndy, step, s, p, isHorizontal: false);
      nx = _centerAlign(p.x, alignStep);
    }

    // Keep targetX/Y in sync — bombCellX/Y derive from them
    final updated = s.players.map((pl) => pl.id == playerId
        ? pl.copyWith(x: nx, y: ny, targetX: nx, targetY: ny)
        : pl).toList();
    return s.copyWith(players: updated);
  }

  /// Pull [pos] toward the nearest cell centre (integer + 0.5) at most [step]
  /// per tick.  This keeps the player aligned with corridors while moving.
  double _centerAlign(double pos, double step) {
    final center = (pos - 0.5).round() + 0.5;
    final diff = center - pos;
    if (diff.abs() <= step) return center; // snap once close enough
    return pos + diff.sign * step;
  }

  /// Slide position [main] by [dir * step] along one axis, stopping at walls.
  ///
  /// [cross] is the perpendicular position (used to determine which tiles the
  /// player body overlaps).  [isHorizontal] controls how (tx, ty) are assembled
  /// for the cell-blocked check.
  double _slideAxis(
    double main, double cross, double dir, double step,
    BombGameState s, BombPlayer p, {required bool isHorizontal}
  ) {
    const r = _kPlayerRadius;
    final newMain = main + dir * step;

    // Leading edge of player body after the proposed move.
    // For dir > 0 this is the right/bottom edge; for dir < 0 the left/top edge.
    final newLeading = newMain + dir * r;
    final newCell = newLeading.floor();

    // Check every tile the player body overlaps on the perpendicular axis.
    // 0.001 inset avoids double-counting at exact integer boundaries.
    final crossLow  = (cross - r + 0.001).floor();
    final crossHigh = (cross + r - 0.001).floor();

    for (int ci = crossLow; ci <= crossHigh; ci++) {
      final tx = isHorizontal ? newCell : ci;
      final ty = isHorizontal ? ci : newCell;
      if (!p.isGhost && _isCellBlocked(s.grid, s.bombs, p, tx, ty)) {
        // Snap so leading edge is 0.001 back from the wall face.
        // The tiny gap keeps floor(leading) in the safe cell on the next tick,
        // preventing the "same-cell skip" that causes clipping.
        return dir > 0
            ? newCell - r - 0.001          // right/down: right edge just left of wall
            : newCell + 1.0 + r + 0.001;   // left/up:   left edge just right of wall
      }
    }

    return newMain;
  }

  /// Returns true if grid cell (tx, ty) is impassable for this player.
  /// Ghosts are handled by the caller — this always checks solid tiles.
  bool _isCellBlocked(
    List<List<CellType>> grid,
    List<Bomb> bombs,
    BombPlayer player,
    int tx,
    int ty,
  ) {
    if (tx < 1 || tx >= kGridW - 1 || ty < 1 || ty >= kGridH - 1) return true;
    final cell = grid[ty][tx];
    if (cell == CellType.wall || cell == CellType.block) return true;
    // Bombs block passage unless it's the cell the player just placed a bomb on
    // (they're allowed to walk away from their own freshly-placed bomb)
    return bombs.any((b) =>
        b.x == tx &&
        b.y == ty &&
        !(b.x == player.bombCellX && b.y == player.bombCellY));
  }

  // ─── Bomb placement ────────────────────────────────────────────────────────
  //
  // Bomb snaps to the player's STABLE cell (the last whole cell they occupied),
  // so the player is already moving away when the bomb drops.

  BombGameState _tryPlaceBomb(BombGameState s, int playerId) {
    final p = s.players[playerId];
    if (!p.canPlaceBomb) return s;

    final bx = p.bombCellX; // stable cell X
    final by = p.bombCellY; // stable cell Y

    // Bounds guard
    if (bx < 0 || bx >= kGridW || by < 0 || by >= kGridH) return s;

    // No two bombs on same cell
    if (s.bombs.any((b) => b.x == bx && b.y == by)) return s;

    // Can't place on a wall or solid block
    final cell = s.grid[by][bx];
    if (cell == CellType.wall || cell == CellType.block) return s;

    final bomb = Bomb(
      id: _nextBombId++,
      x: bx,
      y: by,
      ownerId: playerId,
      range: p.range,
      fuseMs: _fuseMs,
    );

    final updatedPlayers = s.players.map((pl) {
      return pl.id == playerId
          ? pl.copyWith(activeBombs: pl.activeBombs + 1)
          : pl;
    }).toList();

    return s.copyWith(
      bombs: [...s.bombs, bomb],
      players: updatedPlayers,
    );
  }

  // ─── Bomb tick ─────────────────────────────────────────────────────────────

  BombGameState _tickBombs(BombGameState s, int dtMs) {
    final toExplode = <Bomb>[];
    final updated = <Bomb>[];

    for (final b in s.bombs) {
      final remaining = b.fuseMs - dtMs;
      if (remaining <= 0) {
        toExplode.add(b);
      } else {
        updated.add(b.copyWith(fuseMs: remaining));
      }
    }

    if (toExplode.isEmpty) return s.copyWith(bombs: updated);

    var cur = s.copyWith(bombs: updated);
    final toProcess = List<Bomb>.from(toExplode);

    while (toProcess.isNotEmpty) {
      final bomb = toProcess.removeAt(0);
      final result = BombLogic.explode(
        bomb: bomb,
        grid: cur.grid,
        allBombs: cur.bombs,
        players: cur.players,
        powerups: cur.powerups,
        rng: _rng,
      );
      cur = cur.copyWith(
        grid: result.grid,
        explosions: [...cur.explosions, ...result.newExplosions],
        bombs: result.remainingBombs,
        players: result.players,
        powerups: result.powerups,
      );
      toProcess.addAll(result.chainBombs);
    }

    return cur;
  }

  // ─── Explosion fade ────────────────────────────────────────────────────────

  BombGameState _tickExplosions(BombGameState s, int dtMs) {
    final updated = s.explosions
        .map((e) => e.copyWith(remainingMs: e.remainingMs - dtMs))
        .where((e) => e.remainingMs > 0)
        .toList();
    return s.copyWith(explosions: updated);
  }

  // ─── Bot AI ────────────────────────────────────────────────────────────────
  //
  // AI decisions are recalculated every _botAiInterval ticks (≈100ms) to avoid
  // thrashing, but movement is applied every tick so animation stays smooth.

  BombGameState _runBots(BombGameState s, double dt) {
    var cur = s;
    final refreshDecisions = _tickCount % _botAiInterval == 0;

    for (int i = 0; i < cur.players.length; i++) {
      if (!cur.players[i].isBot || !cur.players[i].isAlive) continue;

      if (refreshDecisions) {
        final d = BotAI.decide(botId: i, state: cur, difficulty: _difficulty);
        _botDecisions[i] = (dx: d.dx, dy: d.dy, placeBomb: d.placeBomb);
      }

      final decision = _botDecisions[i];
      if (decision == null) continue;

      if (decision.dx != 0 || decision.dy != 0) {
        cur = _movePlayer(cur, i, decision.dx, decision.dy, dt);
      }

      if (decision.placeBomb) {
        _botDecisions[i] = (dx: decision.dx, dy: decision.dy, placeBomb: false);
        cur = _tryPlaceBomb(cur, i);
      }
    }

    return cur;
  }

  // ─── Round management ──────────────────────────────────────────────────────

  void _handleRoundEnd(int? survivorId) {
    _loopActive = false;

    var wins = List<int>.from(state.roundWins);
    String? msg;
    if (survivorId != null) {
      wins[survivorId]++;
      final p = state.players[survivorId];
      msg = '${p.displayName} wins the round!';
    } else {
      msg = 'Draw!';
    }

    final maxWins = wins.reduce(max);
    final gameWinner =
        maxWins >= (kMaxRounds + 1) ~/ 2 ? wins.indexOf(maxWins) : -1;

    if (gameWinner >= 0) {
      state = state.copyWith(
        roundWins: wins,
        phase: GamePhase.gameOver,
        winnerId: gameWinner,
        roundOverMessage: msg,
      );
      saveScore('bomberman', wins[0] * 100);
    } else {
      state = state.copyWith(
        roundWins: wins,
        phase: GamePhase.roundOver,
        roundOverMessage: msg,
      );
      Timer(const Duration(seconds: 3), () {
        if (state.phase == GamePhase.roundOver) _nextRound();
      });
    }
  }

  void _handleRoundTimeout() {
    _loopActive = false;
    _handleRoundEnd(null);
  }

  void _nextRound() {
    final grid = MapGenerator.generate(seed: _rng.nextInt(9999));
    // Cell centres: cell (c,r) → (c+0.5, r+0.5)
    final spawnPoints = [
      (x: 1.5, y: 1.5),
      (x: kGridW - 1.5, y: 1.5),
      (x: 1.5, y: kGridH - 1.5),
      (x: kGridW - 1.5, y: kGridH - 1.5),
    ];

    final botSpeed = switch (_difficulty) {
      BotDifficulty.easy => 3.5,
      BotDifficulty.medium => 5.0,
      BotDifficulty.hard => 7.0,
    };

    final resetPlayers = state.players.mapIndexed((i, p) {
      final sp = spawnPoints[i % spawnPoints.length];
      return BombPlayer(
        id: p.id,
        x: sp.x,
        y: sp.y,
        isBot: p.isBot,
        displayName: p.displayName,
        speed: p.isBot ? botSpeed : 6.0,
        // isGhost, hasShield, lives all reset to defaults
      );
    }).toList();

    state = state.copyWith(
      grid: grid,
      players: resetPlayers,
      bombs: [],
      explosions: [],
      powerups: [],
      phase: GamePhase.countdown,
      countdown: _countdownSec,
      round: state.round + 1,
      roundTimeSeconds: kRoundDurationSeconds,
      clearRoundOverMessage: true,
    );
    _startCountdown();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _dispose() {
    _loopActive = false;
    _lastFrameTimestamp = null;
    _roundTimeAccum = 0.0;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _tickCount = 0;
  }

  static BombGameState _emptyState() {
    return BombGameState(
      grid: MapGenerator.generate(),
      players: const [],
      roundWins: const [],
      phase: GamePhase.lobby,
    );
  }
}

// ─── Extension ───────────────────────────────────────────────────────────────

extension<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) {
    return List.generate(length, (i) => f(i, this[i]));
  }
}
