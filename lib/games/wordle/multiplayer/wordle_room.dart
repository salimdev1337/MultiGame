/// Tracks players connected to a Wordle lobby room.
class WordleRoomPlayer {
  WordleRoomPlayer({
    required this.id,
    required this.displayName,
    this.isHost = false,
  });

  final int id;
  final String displayName;
  final bool isHost;
}

class WordleRoom {
  static const maxPlayers = 2;

  final List<WordleRoomPlayer> players = [];
  String roomCode = '';

  bool get isFull => players.length >= maxPlayers;

  WordleRoomPlayer addPlayer(String name, {bool isHost = false}) {
    if (isFull) {
      throw StateError('Room is full');
    }
    final id = isHost ? 0 : (players.isEmpty ? 1 : players.last.id + 1);
    final player = WordleRoomPlayer(id: id, displayName: name, isHost: isHost);
    players.add(player);
    return player;
  }

  void removePlayer(int id) {
    players.removeWhere((p) => p.id == id);
  }

  /// Generates a 6-digit room code from the current timestamp.
  static String generateCode() {
    final n = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return n.toString();
  }

  /// Maps a 6-digit room code to a port in [10000, 19999].
  static int portFromCode(String code) {
    final n = int.tryParse(code) ?? 0;
    return 10000 + (n % 10000);
  }
}
