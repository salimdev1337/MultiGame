import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';

/// Platform-agnostic abstract interface for the Bomberman WebSocket server.
abstract class BombServer {
  Future<void> start(int port);
  void broadcast(String message);
  void stop();

  /// Called when a client sends a message to the server.
  set onMessage(void Function(BombMessage msg, int fromPlayerId)? handler);
}
