import 'wordle_message.dart';
import 'wordle_room.dart';
import 'wordle_server.dart';

/// Web stub — browsers cannot host a WebSocket server.
/// Guests on web can still join a native host via WordleClient.
class WordleServerIo implements WordleServer {
  WordleServerIo({required String hostDisplayName});

  // Exposed so the lobby screen can read room state (always empty on web).
  final WordleRoom room = WordleRoom();

  // ignore: unused_field
  void Function(WordleMessage msg, int fromPlayerId)? _onMessage;

  @override
  set onMessage(void Function(WordleMessage msg, int fromPlayerId)? handler) =>
      _onMessage = handler;

  @override
  Future<void> start(int port) async =>
      throw UnsupportedError('Hosting is not supported on web.');

  @override
  void broadcast(String message) {}

  @override
  void sendTo(int playerId, String message) {}

  @override
  void stop() {}

  /// Web stub always returns null.
  static Future<String?> getLocalIp() async => null;
}
