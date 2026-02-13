import 'race_player_state.dart';

/// Enum for the current phase of the room / race
enum RoomPhase {
  /// Waiting in lobby — not all players ready yet
  lobby,

  /// 3-2-1-GO! countdown
  countdown,

  /// Race in progress
  racing,

  /// All players finished (or timeout) — show results
  finished,
}

/// Shared room state (updated on the client side from incoming messages).
/// The host is the source of truth; this model reflects what was last received.
class RaceRoom {
  RaceRoom({
    required this.hostIp,
    required this.localPlayerId,
    this.phase = RoomPhase.lobby,
    List<RacePlayerState>? players,
  }) : players = players ?? [];

  /// Host's local IP (e.g. 192.168.1.42)
  final String hostIp;

  /// This device's player ID (0 = host)
  final int localPlayerId;

  /// Current phase
  RoomPhase phase;

  /// All players currently in the room (ordered by playerId)
  final List<RacePlayerState> players;

  bool get isHost => localPlayerId == 0;

  /// Max 4 players
  static const int maxPlayers = 4;

  bool get isFull => players.length >= maxPlayers;

  bool get allReady =>
      players.isNotEmpty && players.every((p) => p.isReady || !p.isConnected);

  RacePlayerState? get localPlayer {
    try {
      return players.firstWhere((p) => p.playerId == localPlayerId);
    } catch (_) {
      return null;
    }
  }

  List<RacePlayerState> get opponents =>
      players.where((p) => p.playerId != localPlayerId).toList();

  /// Update a player's state; inserts if not present
  void upsertPlayer(RacePlayerState updated) {
    final idx = players.indexWhere((p) => p.playerId == updated.playerId);
    if (idx >= 0) {
      players[idx] = updated;
    } else {
      players.add(updated);
    }
  }

  /// Sort players by descending distance for leaderboard display
  List<RacePlayerState> get leaderboard =>
      List<RacePlayerState>.from(players)
        ..sort((a, b) => b.distance.compareTo(a.distance));

  /// 6-char room code derived from the last two octets of the host IP
  /// e.g. 192.168.1.42 → "001042"
  static String ipToRoomCode(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return '??????';
    final a = int.tryParse(parts[2]) ?? 0;
    final b = int.tryParse(parts[3]) ?? 0;
    return '${a.toString().padLeft(3, '0')}${b.toString().padLeft(3, '0')}';
  }

  /// Reverse a room code back to the last two octets appended to a prefix.
  /// The caller supplies the network prefix (e.g. "192.168.").
  static String roomCodeToIp(String code, String prefix) {
    if (code.length != 6) return '';
    final a = int.tryParse(code.substring(0, 3)) ?? 0;
    final b = int.tryParse(code.substring(3, 6)) ?? 0;
    return '$prefix$a.$b';
  }
}
