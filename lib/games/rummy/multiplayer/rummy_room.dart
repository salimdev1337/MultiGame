class RummyRoomPlayer {
  RummyRoomPlayer({
    required this.id,
    required this.displayName,
    this.isHost = false,
  });

  final int id;
  final String displayName;
  final bool isHost;
}

class RummyRoom {
  static const maxPlayers = 4;
  static const minPlayers = 2;

  final List<RummyRoomPlayer> players = [];
  String roomCode = '';

  bool get isFull => players.length >= maxPlayers;
  bool get canStart => players.length >= minPlayers;

  int get nextId => players.isEmpty
      ? 0
      : players.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

  RummyRoomPlayer addPlayer(String name, {bool isHost = false}) {
    final player = RummyRoomPlayer(id: nextId, displayName: name, isHost: isHost);
    players.add(player);
    return player;
  }

  void removePlayer(int id) => players.removeWhere((p) => p.id == id);

  static String generateCode() {
    final n = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return n.toString();
  }

  static int portFromCode(String code) {
    final n = int.tryParse(code) ?? 0;
    return 10000 + (n % 10000);
  }
}
