import 'dart:convert';

enum BombMessageType {
  join,
  joined,
  ready,
  start,
  move,
  placeBomb,
  bombPlaced,
  explosion,
  playerState,
  playerDied,
  powerupSpawned,
  powerupTaken,
  roundOver,
  rematchVote,
  rematchStart,
  disconnect,
  frameSync, // host→all, every tick: players/bombs/explosions/powerups + meta
  gridUpdate, // host→all, when blocks are destroyed: list of {x, y, type}
}

class BombMessage {
  final BombMessageType type;
  final Map<String, dynamic> payload;

  const BombMessage(this.type, [this.payload = const {}]);

  String encode() => jsonEncode({'type': type.name, 'payload': payload});

  static BombMessage? tryDecode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final type = BombMessageType.values.byName(map['type'] as String);
      final payload = (map['payload'] as Map<String, dynamic>?) ?? {};
      return BombMessage(type, payload);
    } catch (_) {
      return null;
    }
  }

  // ─── Factory helpers ────────────────────────────────────────────────────────

  static BombMessage join(String displayName) =>
      BombMessage(BombMessageType.join, {'name': displayName});

  static BombMessage joined(int playerId, String displayName) => BombMessage(
    BombMessageType.joined,
    {'id': playerId, 'name': displayName},
  );

  static BombMessage ready(int playerId) =>
      BombMessage(BombMessageType.ready, {'id': playerId});

  static BombMessage start() => const BombMessage(BombMessageType.start);

  static BombMessage move(int playerId, double dx, double dy) =>
      BombMessage(BombMessageType.move, {'id': playerId, 'dx': dx, 'dy': dy});

  static BombMessage placeBomb(int playerId) =>
      BombMessage(BombMessageType.placeBomb, {'id': playerId});

  static BombMessage bombPlaced(
    int bombId,
    int x,
    int y,
    int ownerId,
    int range,
  ) => BombMessage(BombMessageType.bombPlaced, {
    'bombId': bombId,
    'x': x,
    'y': y,
    'ownerId': ownerId,
    'range': range,
  });

  static BombMessage explosion(
    List<Map<String, int>> tiles,
    List<Map<String, int>> destroyed,
  ) => BombMessage(BombMessageType.explosion, {
    'tiles': tiles,
    'destroyed': destroyed,
  });

  static BombMessage playerState(List<Map<String, dynamic>> players) =>
      BombMessage(BombMessageType.playerState, {'players': players});

  static BombMessage playerDied(int playerId) =>
      BombMessage(BombMessageType.playerDied, {'id': playerId});

  static BombMessage powerupSpawned(int x, int y, String type) => BombMessage(
    BombMessageType.powerupSpawned,
    {'x': x, 'y': y, 'type': type},
  );

  static BombMessage powerupTaken(int playerId, int x, int y) => BombMessage(
    BombMessageType.powerupTaken,
    {'id': playerId, 'x': x, 'y': y},
  );

  static BombMessage roundOver(int? winnerId, List<int> wins) => BombMessage(
    BombMessageType.roundOver,
    {'winner': winnerId, 'wins': wins},
  );

  static BombMessage rematchVote(int playerId) =>
      BombMessage(BombMessageType.rematchVote, {'id': playerId});

  static BombMessage rematchStart() =>
      const BombMessage(BombMessageType.rematchStart);

  static BombMessage disconnect(int playerId) =>
      BombMessage(BombMessageType.disconnect, {'id': playerId});

  static BombMessage frameSync(Map<String, dynamic> frameJson) =>
      BombMessage(BombMessageType.frameSync, {'data': frameJson});

  static BombMessage gridUpdate(List<Map<String, dynamic>> changedCells) =>
      BombMessage(BombMessageType.gridUpdate, {'cells': changedCells});
}
