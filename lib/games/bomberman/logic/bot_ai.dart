import 'dart:math';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';

// ─── Difficulty ───────────────────────────────────────────────────────────────

enum BotDifficulty {
  easy,   // reactive only, rare bombing
  medium, // balanced
  hard,   // aggressive, always chases, always bombs
}

// ─── Decision ─────────────────────────────────────────────────────────────────

/// Decision made by the bot for one tick.
class BotDecision {
  final double dx;
  final double dy;
  final bool placeBomb;

  const BotDecision({this.dx = 0, this.dy = 0, this.placeBomb = false});

  static const none = BotDecision();
}

// ─── AI ───────────────────────────────────────────────────────────────────────

/// Rule-based bot AI with three difficulty levels.
///
/// Easy   → flee danger only; rarely places bombs; never chases
/// Medium → all 4 rules balanced (original behavior)
/// Hard   → aggressive: always chases; always bombs when possible; tighter danger sense
class BotAI {
  static final _rng = Random();

  static BotDecision decide({
    required int botId,
    required BombGameState state,
    BotDifficulty difficulty = BotDifficulty.medium,
  }) {
    final bot = state.players[botId];
    if (!bot.isAlive) return BotDecision.none;

    final bx = bot.gridX;
    final by = bot.gridY;

    // Danger threshold: how early to flee
    final fuseThreshold = difficulty == BotDifficulty.hard ? 2200 : 1800;

    // 1. Flee if in danger — always highest priority
    if (_inDanger(bx, by, state.bombs, state.explosions, fuseThreshold)) {
      final safeDir = _fleeDirection(bx, by, state);
      if (safeDir != null) {
        return BotDecision(dx: safeDir.dx, dy: safeDir.dy);
      }
    }

    // 2. Bomb placement
    if (bot.canPlaceBomb) {
      final shouldBomb = _shouldPlaceBomb(bx, by, botId, state, difficulty);
      if (shouldBomb) {
        final safeDir = _fleeFromBomb(bx, by, bot.range, state);
        return BotDecision(
          dx: safeDir?.dx ?? 0,
          dy: safeDir?.dy ?? 0,
          placeBomb: true,
        );
      }
    }

    // Easy: no further active behavior
    if (difficulty == BotDifficulty.easy) return BotDecision.none;

    // 3. Chase powerup (medium + hard)
    if (state.powerups.isNotEmpty) {
      final pw = state.powerups.first;
      final dir = _toward(bx, by, pw.x, pw.y, state);
      if (dir != null) return BotDecision(dx: dir.dx, dy: dir.dy);
    }

    // 4. Chase human player
    final human = state.players.firstWhere(
      (p) => !p.isBot && p.isAlive && !p.isGhost,
      orElse: () => state.players.firstWhere(
        (p) => !p.isBot && p.isAlive,
        orElse: () => state.players.first,
      ),
    );
    final dir = _toward(bx, by, human.gridX, human.gridY, state);
    if (dir != null) return BotDecision(dx: dir.dx, dy: dir.dy);

    return BotDecision.none;
  }

  // ──────────────────────────────────────────────────────────────────────────

  /// Whether the bot should place a bomb at this position.
  static bool _shouldPlaceBomb(
    int bx, int by, int botId, BombGameState state, BotDifficulty difficulty,
  ) {
    switch (difficulty) {
      case BotDifficulty.easy:
        // Rarely bomb — only 15% chance when adjacent to a block
        return _hasAdjacentBlock(bx, by, state.grid) && _rng.nextDouble() < 0.15;

      case BotDifficulty.medium:
        return _hasAdjacentBlock(bx, by, state.grid);

      case BotDifficulty.hard:
        // Bomb if adjacent to block OR within 2 cells of a living player
        if (_hasAdjacentBlock(bx, by, state.grid)) return true;
        return state.players.any((p) {
          if (p.id == botId || !p.isAlive || p.isGhost) return false;
          return (p.gridX - bx).abs() + (p.gridY - by).abs() <= 2;
        });
    }
  }

  static bool _inDanger(
    int x, int y,
    List<Bomb> bombs,
    List<ExplosionTile> explosions,
    int fuseThreshold,
  ) {
    if (explosions.any((e) => e.x == x && e.y == y)) return true;
    for (final bomb in bombs) {
      if (bomb.fuseMs < fuseThreshold) {
        final dist = (bomb.x - x).abs() + (bomb.y - y).abs();
        if (dist <= bomb.range + 1) return true;
      }
    }
    return false;
  }

  static _Dir? _fleeDirection(int x, int y, BombGameState state) {
    return _bfsFirstStep(x, y, state, (nx, ny) {
      return !_inDanger(nx, ny, state.bombs, state.explosions, 1800);
    });
  }

  static _Dir? _fleeFromBomb(int bx, int by, int range, BombGameState state) {
    final fakeBombs = [
      ...state.bombs,
      Bomb(id: -1, x: bx, y: by, ownerId: -1, range: range, fuseMs: 0),
    ];
    final fakeState = state.copyWith(bombs: fakeBombs);
    return _bfsFirstStep(bx, by, fakeState, (nx, ny) {
      return !_inDanger(nx, ny, fakeBombs, state.explosions, 1800);
    });
  }

  static bool _hasAdjacentBlock(int x, int y, List<List<CellType>> grid) {
    const offsets = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final (dx, dy) in offsets) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < kGridW && ny >= 0 && ny < kGridH) {
        if (grid[ny][nx] == CellType.block) return true;
      }
    }
    return false;
  }

  static _Dir? _toward(int fromX, int fromY, int toX, int toY, BombGameState state) {
    return _bfsFirstStep(fromX, fromY, state, (nx, ny) => nx == toX && ny == toY);
  }

  /// BFS from (startX,startY) — returns the first step direction toward a cell
  /// satisfying [goal]. Returns null if unreachable.
  static _Dir? _bfsFirstStep(
    int startX, int startY, BombGameState state, bool Function(int, int) goal,
  ) {
    final grid = state.grid;
    final bombPositions = {for (final b in state.bombs) (b.x, b.y)};

    final visited = <(int, int)>{};
    final queue = <(int, int, _Dir?)>[];
    queue.add((startX, startY, null));
    visited.add((startX, startY));

    const dirs = [(0, -1), (0, 1), (-1, 0), (1, 0)];
    const dirObjs = [_Dir(0, -1), _Dir(0, 1), _Dir(-1, 0), _Dir(1, 0)];

    while (queue.isNotEmpty) {
      final (cx, cy, firstDir) = queue.removeAt(0);

      if (goal(cx, cy) && !(cx == startX && cy == startY)) {
        return firstDir;
      }

      for (int i = 0; i < 4; i++) {
        final nx = cx + dirs[i].$1;
        final ny = cy + dirs[i].$2;
        if (nx < 0 || nx >= kGridW || ny < 0 || ny >= kGridH) continue;
        if (visited.contains((nx, ny))) continue;
        final cell = grid[ny][nx];
        if (cell == CellType.wall || cell == CellType.block) continue;
        if (bombPositions.contains((nx, ny))) continue;

        visited.add((nx, ny));
        queue.add((nx, ny, firstDir ?? dirObjs[i]));
      }
    }
    return null;
  }
}

class _Dir {
  final double dx;
  final double dy;
  const _Dir(this.dx, this.dy);
}
