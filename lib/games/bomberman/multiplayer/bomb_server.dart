/// Platform-agnostic abstract interface for the Bomberman WebSocket server.
abstract class BombServer {
  Future<void> start(int port);
  void broadcast(String message);
  void stop();
}
