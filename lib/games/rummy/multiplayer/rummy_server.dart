import 'rummy_message.dart';

/// Platform-agnostic abstract interface for the Rummy WebSocket server.
/// Native: RummyServerIo. Web: stub (throws on start).
abstract class RummyServer {
  Future<void> start(int port);
  void broadcast(String message);

  /// Send a message to a specific player only (needed for private hand delivery).
  void sendTo(int playerId, String message);
  void stop();

  set onMessage(void Function(RummyMessage msg, int fromPlayerId)? handler);
  set onClientDisconnected(void Function(int playerId)? handler);
}
