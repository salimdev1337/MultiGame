/// Room state management and room-code helpers for Bomberman multiplayer.
library;

class BombRoomPlayer {
  final int id;
  final String displayName;
  bool isReady;
  bool isHost;

  BombRoomPlayer({
    required this.id,
    required this.displayName,
    this.isReady = false,
    this.isHost = false,
  });
}

class BombRoom {
  static const maxPlayers = 4;

  final List<BombRoomPlayer> players = [];
  String roomCode = '';

  bool get isFull => players.length >= maxPlayers;
  bool get allReady => players.isNotEmpty && players.every((p) => p.isReady);

  int get nextId => players.isEmpty ? 0 : players.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

  BombRoomPlayer? findById(int id) =>
      players.where((p) => p.id == id).firstOrNull;

  BombRoomPlayer addPlayer(String name, {bool isHost = false}) {
    final player = BombRoomPlayer(
      id: nextId,
      displayName: name,
      isHost: isHost,
    );
    players.add(player);
    return player;
  }

  void removePlayer(int id) => players.removeWhere((p) => p.id == id);

  void setReady(int id, bool ready) {
    final p = findById(id);
    if (p != null) p.isReady = ready;
  }

  // ─── Room code helpers ────────────────────────────────────────────────────
  // Simple 6-digit code derived from local IP address (same approach as
  // InfiniteRunner's RaceRoom.ipToRoomCode).

  static String generateCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now % 900000) + 100000).toString();
  }

  static int portFromCode(String code) {
    final n = int.tryParse(code) ?? 100000;
    // Map to a port in [10000, 19999] range
    return 10000 + (n % 10000);
  }
}
