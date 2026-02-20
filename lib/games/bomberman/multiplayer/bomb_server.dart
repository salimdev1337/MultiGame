import 'dart:typed_data';

import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';

/// Platform-agnostic abstract interface for the Bomberman WebSocket server.
abstract class BombServer {
  Future<void> start(int port);
  void broadcast(String message);

  /// Broadcast a raw binary frame to all connected clients.
  /// Used for high-frequency frameSync messages.
  void broadcastBytes(Uint8List bytes);

  void stop();

  /// Called when a client sends a message to the server.
  set onMessage(void Function(BombMessage msg, int fromPlayerId)? handler);
}
