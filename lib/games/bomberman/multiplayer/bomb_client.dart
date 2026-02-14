import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_room.dart';

/// WebSocket client used by all participants (host + guests).
///
/// Guests connect to the host's IP. The host also runs a client so it
/// receives its own broadcast messages.
class BombClient {
  final String hostIp;
  final String displayName;
  final BombRoom room;

  BombClient({
    required this.hostIp,
    required this.displayName,
    required this.room,
  });

  WebSocketChannel? _channel;
  bool _connected = false;

  bool get isConnected => _connected;

  /// Fired when a message arrives from the server.
  void Function(BombMessage msg)? onMessage;

  /// Fired when the connection drops unexpectedly.
  void Function()? onDisconnected;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> connect(int port) async {
    final uri = Uri.parse('ws://$hostIp:$port');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (raw) {
        if (raw is! String) return;
        final msg = BombMessage.tryDecode(raw);
        if (msg != null) onMessage?.call(msg);
      },
      onDone: () {
        _connected = false;
        onDisconnected?.call();
      },
      onError: (_) {
        _connected = false;
        onDisconnected?.call();
      },
    );

    _send(BombMessage.join(displayName).encode());
    _connected = true;
  }

  Future<void> disconnect() async {
    _connected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  // ─── Outgoing ──────────────────────────────────────────────────────────────

  void sendReady(int playerId) => _send(BombMessage.ready(playerId).encode());

  void sendMove(int playerId, double dx, double dy) =>
      _send(BombMessage.move(playerId, dx, dy).encode());

  void sendPlaceBomb(int playerId) =>
      _send(BombMessage.placeBomb(playerId).encode());

  void sendRematchVote(int playerId) =>
      _send(BombMessage.rematchVote(playerId).encode());

  // ─── Private ───────────────────────────────────────────────────────────────

  void _send(String message) {
    try {
      _channel?.sink.add(message);
    } catch (_) {}
  }
}
