import 'package:flutter/foundation.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';

const kGridW = 15;
const kGridH = 13;
const kMaxRounds = 3;
const kRoundDurationSeconds = 180;

@immutable
class BombGameState {
  final List<List<CellType>> grid;     // [row][col], size kGridH × kGridW
  final List<BombPlayer> players;
  final List<Bomb> bombs;
  final List<ExplosionTile> explosions;
  final List<PowerupCell> powerups;
  final GamePhase phase;
  final int countdown;                  // 3-2-1 before round starts
  final int roundTimeSeconds;           // time left this round
  final int round;                      // 1-based
  final List<int> roundWins;            // wins per player index
  final int? winnerId;                  // set at gameOver
  final String? roundOverMessage;

  const BombGameState({
    required this.grid,
    required this.players,
    this.bombs = const [],
    this.explosions = const [],
    this.powerups = const [],
    this.phase = GamePhase.lobby,
    this.countdown = 3,
    this.roundTimeSeconds = kRoundDurationSeconds,
    this.round = 1,
    required this.roundWins,
    this.winnerId,
    this.roundOverMessage,
  });

  BombGameState copyWith({
    List<List<CellType>>? grid,
    List<BombPlayer>? players,
    List<Bomb>? bombs,
    List<ExplosionTile>? explosions,
    List<PowerupCell>? powerups,
    GamePhase? phase,
    int? countdown,
    int? roundTimeSeconds,
    int? round,
    List<int>? roundWins,
    int? winnerId,
    String? roundOverMessage,
    bool clearWinner = false,
    bool clearRoundOverMessage = false,
  }) {
    return BombGameState(
      grid: grid ?? this.grid,
      players: players ?? this.players,
      bombs: bombs ?? this.bombs,
      explosions: explosions ?? this.explosions,
      powerups: powerups ?? this.powerups,
      phase: phase ?? this.phase,
      countdown: countdown ?? this.countdown,
      roundTimeSeconds: roundTimeSeconds ?? this.roundTimeSeconds,
      round: round ?? this.round,
      roundWins: roundWins ?? this.roundWins,
      winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
      roundOverMessage: clearRoundOverMessage
          ? null
          : (roundOverMessage ?? this.roundOverMessage),
    );
  }

  int get playerCount => players.length;

  /// Players who are alive AND not ghosts — counts toward win condition
  int get livingCount => players.where((p) => p.isAlive && !p.isGhost).length;

  /// All players still participating (alive or ghost)
  int get activeCount => players.where((p) => p.isAlive).length;

  /// Kept for compat — use livingCount for win checks
  int get aliveCount => livingCount;

  BombPlayer? get localPlayer =>
      players.isNotEmpty ? players[0] : null;
}
