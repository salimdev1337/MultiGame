import 'dart:async';

import 'package:multigame/utils/secure_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'wordle_message.dart';

/// WebSocket client used by all participants (host + guest).
///
/// The host also connects as a client (to 127.0.0.1) so it receives
/// its own broadcast messages through the same channel.
class WordleClient {
  final String hostIp;
  final String displayName;

  WordleClient({required this.hostIp, required this.displayName});

  WebSocketChannel? _channel;
  bool _connected = false;

  bool get isConnected => _connected;

  /// Fired when a message arrives from the server.
  void Function(WordleMessage msg)? onMessage;

  /// Fired when the connection drops unexpectedly.
  void Function()? onDisconnected;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> connect(int port) async {
    final uri = Uri.parse('ws://$hostIp:$port');
    _channel = WebSocketChannel.connect(uri);

    // Verify the WebSocket handshake actually completes before proceeding.
    // Without this, connect() returns immediately even if the host is
    // unreachable, and the caller's try/catch never fires.
    await _channel!.ready.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('Connection timed out'),
    );

    _channel!.stream.listen(
      (raw) {
        if (raw is! String) {
          return;
        }
        final msg = WordleMessage.tryDecode(raw);
        if (msg != null) {
          onMessage?.call(msg);
        }
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

    _send(WordleMessage.join(displayName).encode());
    _connected = true;
  }

  Future<void> disconnect() async {
    _connected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  // ── Outgoing ───────────────────────────────────────────────────────────────

  void sendGuess(int playerId, String guess) =>
      _send(WordleMessage.submitGuess(playerId, guess).encode());

  // ── Private ────────────────────────────────────────────────────────────────

  void _send(String message) {
    try {
      _channel?.sink.add(message);
    } catch (e, st) {
      SecureLogger.error(
        'WordleClient failed to send message',
        error: e,
        stackTrace: st,
      );
    }
  }
}
