// dart:io is not available on web. This file is only compiled for native targets.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:io';

import 'package:multigame/utils/secure_logger.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'wordle_message.dart';
import 'wordle_room.dart';
import 'wordle_server.dart';

/// Host-side WebSocket server for Wordle multiplayer (native only).
///
/// The host runs this server. Both devices (host + guest) connect to it.
/// Host has player ID 0, first guest gets ID 1.
class WordleServerIo implements WordleServer {
  final String hostDisplayName;
  final WordleRoom room = WordleRoom();

  WordleServerIo({required this.hostDisplayName});

  HttpServer? _httpServer;
  final Map<int, WebSocketChannel> _connections = {};
  int _nextGuestId = 1;

  void Function(WordleMessage msg, int fromPlayerId)? _onMessage;

  @override
  set onMessage(void Function(WordleMessage msg, int fromPlayerId)? handler) =>
      _onMessage = handler;

  // ── WordleServer interface ─────────────────────────────────────────────────

  @override
  Future<void> start(int port) async {
    room.addPlayer(hostDisplayName, isHost: true);
    room.roomCode = WordleRoom.generateCode();

    final handler = webSocketHandler(_handleConnection);
    _httpServer = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  }

  @override
  void broadcast(String message) {
    for (final entry in _connections.entries) {
      try {
        entry.value.sink.add(message);
      } catch (e, st) {
        SecureLogger.error(
          'WordleServer broadcast failed for connection id ${entry.key}',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  void sendTo(int playerId, String message) {
    try {
      _connections[playerId]?.sink.add(message);
    } catch (e, st) {
      SecureLogger.error(
        'WordleServer sendTo failed for playerId $playerId',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void stop() {
    for (final ch in _connections.values) {
      ch.sink.close();
    }
    _connections.clear();
    _httpServer?.close(force: true);
    _httpServer = null;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _handleConnection(WebSocketChannel channel) {
    final id = _nextGuestId++;
    _connections[id] = channel;

    channel.stream.listen(
      (raw) {
        if (raw is! String) {
          return;
        }
        final msg = WordleMessage.tryDecode(raw);
        if (msg == null) {
          return;
        }

        if (msg.type == WordleMessageType.join) {
          final name = (msg.payload['name'] as String?) ?? 'Player $id';
          room.addPlayer(name);
          channel.sink.add(WordleMessage.joined(id, name).encode());
          _onMessage?.call(msg, id);
        } else {
          _onMessage?.call(msg, id);
        }
      },
      onDone: () {
        _connections.remove(id);
        room.removePlayer(id);
        broadcast(WordleMessage.disconnect.encode());
        _onMessage?.call(WordleMessage.disconnect, id);
      },
      onError: (error, stackTrace) {
        SecureLogger.error(
          'WordleServer connection error for id $id',
          error: error,
          stackTrace: stackTrace,
        );
        _connections.remove(id);
        room.removePlayer(id);
        broadcast(WordleMessage.disconnect.encode());
        _onMessage?.call(WordleMessage.disconnect, id);
      },
    );
  }

  /// Returns the host's local IPv4 address (shown in lobby).
  static Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
