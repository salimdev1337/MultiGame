import 'wordle_message.dart';

/// Abstract interface for the Wordle WebSocket server.
/// Native: WordleServerIo. Web: WordleServerStub (throws).
abstract class WordleServer {
  Future<void> start(int port);
  void broadcast(String message);
  void sendTo(int playerId, String message);
  void stop();

  set onMessage(void Function(WordleMessage msg, int fromPlayerId)? handler);
}
