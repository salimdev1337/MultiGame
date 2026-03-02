// dart:io is not available on web. This file is only compiled for native targets.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:io';

import 'package:multigame/utils/secure_logger.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'rummy_message.dart';
import 'rummy_room.dart';
import 'rummy_server.dart';

/// Host-side WebSocket server for Rummy multiplayer (native only).
///
/// Maintains per-player connections so the host can send targeted state
/// updates (private hands). Each player only receives their own hand face-up;
/// opponents' hands are replaced with a card count.
class RummyServerIo implements RummyServer {
  final String hostDisplayName;
  final RummyRoom room = RummyRoom();

  RummyServerIo({required this.hostDisplayName});

  HttpServer? _httpServer;
  final Map<int, WebSocketChannel> _connections = {};
  int _nextGuestId = 1;

  void Function(RummyMessage msg, int fromPlayerId)? _onMessage;
  void Function(int playerId)? _onClientDisconnected;

  @override
  set onMessage(void Function(RummyMessage msg, int fromPlayerId)? handler) =>
      _onMessage = handler;

  @override
  set onClientDisconnected(void Function(int playerId)? handler) =>
      _onClientDisconnected = handler;

  // ── RummyServer interface ──────────────────────────────────────────────────

  @override
  Future<void> start(int port) async {
    room.addPlayer(hostDisplayName, isHost: true);
    room.roomCode = RummyRoom.generateCode();

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
          'RummyServer broadcast failed for id ${entry.key}',
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
        'RummyServer sendTo failed for playerId $playerId',
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
        final msg = RummyMessage.tryDecode(raw);
        if (msg == null) {
          return;
        }

        if (msg.type == RummyMessageType.join) {
          final name = (msg.payload['name'] as String?) ?? 'Player $id';
          room.addPlayer(name);
          final roomList = room.players
              .map((p) => {'id': p.id, 'name': p.displayName, 'isHost': p.isHost})
              .toList();
          channel.sink.add(RummyMessage.joined(id, name, roomList).encode());
          broadcast(RummyMessage.playerJoined(id, name).encode());
          _onMessage?.call(msg, id);
        } else {
          _onMessage?.call(msg, id);
        }
      },
      onDone: () {
        _connections.remove(id);
        room.removePlayer(id);
        broadcast(RummyMessage.disconnect.encode());
        _onClientDisconnected?.call(id);
      },
      onError: (error, stackTrace) {
        SecureLogger.error(
          'RummyServer connection error for id $id',
          error: error,
          stackTrace: stackTrace,
        );
        _connections.remove(id);
        room.removePlayer(id);
        _onClientDisconnected?.call(id);
      },
    );
  }

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
