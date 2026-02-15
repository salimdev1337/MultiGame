import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';
import 'dart:math';

/// Pure functions for bomb explosion propagation, player collision, and
/// powerup spawning. All functions are stateless — they take old state and
/// return new immutable objects.
class BombLogic {
  static const _explosionDuration = 400; // ms
  static const _powerupChance = 0.35;

  /// Propagate a bomb explosion: compute blast tiles, destroy blocks, check
  /// for chain reactions. Returns updated (grid, explosions, bombs, players,
  /// powerups).
  ///
  /// Ghost bombs: destroy blocks but cannot hurt living players.
  static ({
    List<List<CellType>> grid,
    List<ExplosionTile> newExplosions,
    List<Bomb> remainingBombs,
    List<BombPlayer> players,
    List<PowerupCell> powerups,
    List<Bomb> chainBombs,
  })
  explode({
    required Bomb bomb,
    required List<List<CellType>> grid,
    required List<Bomb> allBombs,
    required List<BombPlayer> players,
    required List<PowerupCell> powerups,
    Random? rng,
  }) {
    final r = rng ?? Random();
    final newGrid = grid.map((row) => List<CellType>.from(row)).toList();
    final blastTiles = <ExplosionTile>[];
    final newPowerups = List<PowerupCell>.from(powerups);
    final chainBombs = <Bomb>[];

    // Determine if the bomb owner is a ghost (ghost bombs only reshape map)
    final isGhostBomb = players.any((p) => p.id == bomb.ownerId && p.isGhost);

    // Center tile always explodes
    blastTiles.add(
      ExplosionTile(x: bomb.x, y: bomb.y, remainingMs: _explosionDuration),
    );

    // Expand in 4 directions
    const dx = [0, 0, -1, 1];
    const dy = [-1, 1, 0, 0];

    for (int dir = 0; dir < 4; dir++) {
      for (int step = 1; step <= bomb.range; step++) {
        final nx = bomb.x + dx[dir] * step;
        final ny = bomb.y + dy[dir] * step;

        if (nx < 0 || nx >= kGridW || ny < 0 || ny >= kGridH) break;

        final cell = newGrid[ny][nx];

        if (cell == CellType.wall) break; // permanent wall stops blast

        blastTiles.add(
          ExplosionTile(x: nx, y: ny, remainingMs: _explosionDuration),
        );

        if (cell == CellType.block) {
          // Destroy block
          newGrid[ny][nx] = CellType.empty;
          // Maybe spawn powerup
          if (r.nextDouble() < _powerupChance) {
            final type =
                PowerupType.values[r.nextInt(PowerupType.values.length)];
            newPowerups.add(PowerupCell(x: nx, y: ny, type: type));
          }
          break; // blast doesn't continue through destroyed block
        }

        // Check chain bomb
        final chainBomb = allBombs
            .where((b) => b != bomb && b.x == nx && b.y == ny)
            .firstOrNull;
        if (chainBomb != null) {
          chainBombs.add(chainBomb);
        }
      }
    }

    // Apply damage to living players (ghost bombs skip this entirely)
    List<BombPlayer> updatedPlayers = players;
    if (!isGhostBomb) {
      updatedPlayers = players.map((p) {
        if (!p.isAlive || p.isGhost) return p; // already a ghost / dead
        final inBlast = blastTiles.any((t) => t.x == p.gridX && t.y == p.gridY);
        if (!inBlast) return p;
        // Shield absorbs one hit
        if (p.hasShield) return p.copyWith(hasShield: false);
        // One hit → become ghost
        return p.copyWith(isGhost: true);
      }).toList();
    }

    // Decrement owner's activeBombs
    final updatedPlayers2 = updatedPlayers.map((p) {
      if (p.id == bomb.ownerId) {
        return p.copyWith(activeBombs: max(0, p.activeBombs - 1));
      }
      return p;
    }).toList();

    return (
      grid: newGrid,
      newExplosions: blastTiles,
      remainingBombs: allBombs.where((b) => b != bomb).toList(),
      players: updatedPlayers2,
      powerups: newPowerups,
      chainBombs: chainBombs,
    );
  }

  /// Collect powerups at each player's grid position.
  /// Only living non-ghost players collect powerups.
  static ({List<BombPlayer> players, List<PowerupCell> powerups})
  collectPowerups({
    required List<BombPlayer> players,
    required List<PowerupCell> powerups,
  }) {
    final remaining = List<PowerupCell>.from(powerups);
    final updated = players.map((p) {
      if (!p.isAlive || p.isGhost) return p; // ghosts can't collect
      final collected = remaining
          .where((pw) => pw.x == p.gridX && pw.y == p.gridY)
          .toList();
      if (collected.isEmpty) return p;
      for (final pw in collected) {
        remaining.remove(pw);
      }
      var player = p;
      for (final pw in collected) {
        player = _applyPowerup(player, pw.type);
      }
      return player;
    }).toList();

    return (players: updated, powerups: remaining);
  }

  static BombPlayer _applyPowerup(BombPlayer p, PowerupType type) {
    switch (type) {
      case PowerupType.extraBomb:
        return p.copyWith(maxBombs: min(p.maxBombs + 1, 3));
      case PowerupType.blastRange:
        return p.copyWith(range: min(p.range + 1, 6));
      case PowerupType.speed:
        return p.copyWith(speed: min(p.speed + 0.5, 6.0));
      case PowerupType.shield:
        return p.copyWith(hasShield: true);
    }
  }

  /// Check if a tile is walkable for non-ghost players.
  static bool isWalkable(List<List<CellType>> grid, int x, int y) {
    if (x < 0 || x >= kGridW || y < 0 || y >= kGridH) return false;
    final cell = grid[y][x];
    return cell == CellType.empty || cell == CellType.powerup;
  }
}
