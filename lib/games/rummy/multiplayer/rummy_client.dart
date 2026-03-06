import 'dart:async';

import 'package:multigame/utils/secure_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'rummy_message.dart';

/// WebSocket client used by all participants (host + guests).
///
/// The host self-connects to 127.0.0.1 so it receives its own broadcasts.
/// CRITICAL: wire [onMessage] and [onDisconnected] BEFORE calling [connect].
class RummyClient {
  RummyClient({required this.hostIp, required this.displayName});

  final String hostIp;
  final String displayName;

  WebSocketChannel? _channel;
  bool _connected = false;

  bool get isConnected => _connected;

  void Function(RummyMessage msg)? onMessage;
  void Function()? onDisconnected;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> connect(int port) async {
    final uri = Uri.parse('ws://$hostIp:$port');
    _channel = WebSocketChannel.connect(uri);

    await _channel!.ready.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('Connection timed out'),
    );

    _channel!.stream.listen(
      (raw) {
        if (raw is! String) {
          return;
        }
        final msg = RummyMessage.tryDecode(raw);
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

    _send(RummyMessage.join(displayName).encode());
    _connected = true;
  }

  Future<void> disconnect() async {
    _connected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  // ── Outgoing ───────────────────────────────────────────────────────────────

  void sendDrawDeck(int playerId) =>
      _send(RummyMessage.drawDeck(playerId).encode());

  void sendDrawDiscard(int playerId) =>
      _send(RummyMessage.drawDiscard(playerId).encode());

  void sendReturnDiscard(int playerId) =>
      _send(RummyMessage.returnDiscard(playerId).encode());

  void sendLayMeld(int playerId, List<String> cardIds) =>
      _send(RummyMessage.layMeld(playerId, cardIds).encode());

  void sendAddToMeld(
    int playerId,
    List<String> cardIds,
    int meldOwnerId,
    int meldIdx,
  ) => _send(RummyMessage.addToMeld(playerId, cardIds, meldOwnerId, meldIdx).encode());

  void sendDiscard(int playerId, String cardId) =>
      _send(RummyMessage.discard(playerId, cardId).encode());

  void sendDeclare(int playerId) =>
      _send(RummyMessage.declare(playerId).encode());

  void sendSortHand(int playerId, String mode) =>
      _send(RummyMessage.sortHand(playerId, mode).encode());

  void sendReorderHand(int playerId, int oldIndex, int newIndex) =>
      _send(RummyMessage.reorderHand(playerId, oldIndex, newIndex).encode());

  // ── Private ────────────────────────────────────────────────────────────────

  void _send(String message) {
    try {
      _channel?.sink.add(message);
    } catch (e, st) {
      SecureLogger.error(
        'RummyClient failed to send message',
        error: e,
        stackTrace: st,
      );
    }
  }
}
