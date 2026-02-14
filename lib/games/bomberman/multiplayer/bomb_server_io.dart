// dart:io is not available on web. This file is only compiled for native targets.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_room.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_server.dart';

/// Host-side WebSocket server for Bomberman multiplayer.
///
/// The host device runs this server. All clients (including the host's own
/// BombClient) connect to it. The server:
/// - Assigns player IDs
/// - Relays input messages to the host's game notifier
/// - Broadcasts authoritative state from the host to all clients
class BombServerIo implements BombServer {
  final String hostDisplayName;
  final BombRoom room = BombRoom();

  BombServerIo({required this.hostDisplayName});

  HttpServer? _httpServer;
  final Map<int, WebSocketChannel> _connections = {};
  int _nextGuestId = 1;

  /// Called when a new client joins, sends input, or disconnects.
  void Function(BombMessage msg, int fromPlayerId)? _onMessage;

  @override
  set onMessage(void Function(BombMessage msg, int fromPlayerId)? handler) =>
      _onMessage = handler;

  // ─── BombServer interface ─────────────────────────────────────────────────

  @override
  Future<void> start(int port) async {
    room.addPlayer(hostDisplayName, isHost: true);
    room.roomCode = BombRoom.generateCode();

    final handler = webSocketHandler(_handleConnection);
    _httpServer = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
    );
  }

  @override
  void broadcast(String message) {
    for (final ch in _connections.values) {
      try {
        ch.sink.add(message);
      } catch (_) {}
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

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _handleConnection(WebSocketChannel channel) {
    final id = _nextGuestId++;
    _connections[id] = channel;

    channel.stream.listen(
      (raw) {
        if (raw is! String) return;
        final msg = BombMessage.tryDecode(raw);
        if (msg == null) return;

        if (msg.type == BombMessageType.join) {
          final name = (msg.payload['name'] as String?) ?? 'Player $id';
          room.addPlayer(name);
          // Confirm assignment
          channel.sink.add(BombMessage.joined(id, name).encode());
          // Notify host notifier
          _onMessage?.call(msg, id);
        } else {
          _onMessage?.call(msg, id);
        }
      },
      onDone: () {
        _connections.remove(id);
        room.removePlayer(id);
        broadcast(BombMessage.disconnect(id).encode());
        _onMessage?.call(BombMessage.disconnect(id), id);
      },
      onError: (_) {
        _connections.remove(id);
      },
    );
  }

  /// Returns the host's local IPv4 address for room-code derivation.
  static Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }
}
