import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_room.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_server.dart';

/// Web stub — browsers cannot host a WebSocket server.
/// Guests on web can still join a native host via BombClient.
class BombServerIo implements BombServer {
  BombServerIo({required String hostDisplayName});

  // Exposed so the lobby screen can read room state (always empty on web).
  final BombRoom room = BombRoom();

  // Callback (no-op on web).
  void Function(BombMessage msg, int fromPlayerId)? onMessage;

  @override
  Future<void> start(int port) async {
    throw UnsupportedError('Hosting is not supported in the web build.');
  }

  @override
  void broadcast(String message) {}

  @override
  void stop() {}

  /// Web stub always returns null.
  static Future<String?> getLocalIp() async => null;
}
