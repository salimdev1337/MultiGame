import 'rummy_message.dart';
import 'rummy_room.dart';
import 'rummy_server.dart';

/// Web stub — browsers cannot host a WebSocket server.
/// Guests on web can still join a native host via RummyClient.
class RummyServerIo implements RummyServer {
  RummyServerIo({required String hostDisplayName});

  final RummyRoom room = RummyRoom();

  // ignore: unused_field
  void Function(RummyMessage msg, int fromPlayerId)? _onMessage;
  // ignore: unused_field
  void Function(int playerId)? _onClientDisconnected;

  @override
  set onMessage(void Function(RummyMessage msg, int fromPlayerId)? handler) =>
      _onMessage = handler;

  @override
  set onClientDisconnected(void Function(int playerId)? handler) =>
      _onClientDisconnected = handler;

  @override
  Future<void> start(int port) async =>
      throw UnsupportedError('Hosting is not supported on web.');

  @override
  void broadcast(String message) {}

  @override
  void sendTo(int playerId, String message) {}

  @override
  void stop() {}

  static Future<String?> getLocalIp() async => null;
}
