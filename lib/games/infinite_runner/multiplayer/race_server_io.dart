import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'race_message.dart';
import 'race_player_state.dart';
import 'race_room.dart';

/// Server port for local WiFi races
const int kRaceServerPort = 4567;

/// Runs on the host phone.
/// Accepts WebSocket connections, assigns player IDs, relays messages,
/// and tracks the authoritative finish order.
class RaceServer {
  RaceServer({required this.hostDisplayName});

  final String hostDisplayName;

  HttpServer? _httpServer;
  final Map<int, WebSocketChannel> _connections = {};
  final List<RacePlayerState> _players = [];
  int _nextGuestId = 1;
  bool _raceStarted = false;
  bool _resultsPublished = false;
  final List<Map<String, dynamic>> _finishOrder = [];
  Timer? _timeoutTimer;

  /// Callback invoked on the host when a meaningful state change occurs
  /// (player joined/ready, race started, finish results ready).
  void Function(RaceServerEvent event)? onEvent;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Start the WebSocket server.  Returns the local IP address that guests
  /// should connect to, or null on failure.
  Future<String?> start() async {
    try {
      final ip = await _getLocalIp();
      if (ip == null) return null;

      // Register host as player 0
      _players.add(
        RacePlayerState(playerId: 0, displayName: hostDisplayName),
      );

      final handler = webSocketHandler(_handleConnection);
      _httpServer = await shelf_io.serve(handler, InternetAddress.anyIPv4, kRaceServerPort);
      return ip;
    } catch (_) {
      return null;
    }
  }

  /// Stop the server and close all connections
  Future<void> stop() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    for (final ch in _connections.values) {
      ch.sink.close();
    }
    _connections.clear();
    await _httpServer?.close(force: true);
    _httpServer = null;
  }

  /// Mark host as ready and check if all players are ready
  void setHostReady(bool isReady) {
    _updatePlayer(0, (p) => p.copyWith(isReady: isReady));
    _broadcast(RaceMessage.ready(playerId: 0, isReady: isReady).toJson());
    _maybeNotifyAllReady();
  }

  /// Broadcast start — called by the host UI after all players are ready
  void broadcastStart() {
    _raceStarted = true;
    _broadcast(RaceMessage.start().toJson());
    onEvent?.call(const RaceServerEvent(RaceServerEventType.raceStarted));
    // 3-minute hard cap: furthest player wins if time runs out
    _timeoutTimer = Timer(const Duration(minutes: 3), _handleTimeout);
  }

  /// Relay a pos update from the host
  void broadcastHostPos(double distance) {
    _updatePlayer(0, (p) => p.copyWith(distance: distance));
    _broadcast(RaceMessage.pos(playerId: 0, distance: distance).toJson());
  }

  /// Relay an ability used event from the host
  void broadcastHostAbility(String abilityId) {
    _broadcast(
      RaceMessage.abilityUsed(playerId: 0, abilityId: abilityId).toJson(),
    );
  }

  /// Record that the host finished
  void recordHostFinish(int timeMs) {
    _handleFinish(0, timeMs);
  }

  List<RacePlayerState> get players => List.unmodifiable(_players);

  // ── Private ────────────────────────────────────────────────────────────────

  void _handleConnection(WebSocketChannel channel) {
    // Temporary ID until 'join' message arrives
    int? assignedId;

    channel.stream.listen(
      (dynamic rawData) {
        final msg = RaceMessage.fromJson(rawData as String);

        switch (msg.type) {
          case RaceMessageType.join:
            if (_raceStarted || _players.length >= RaceRoom.maxPlayers) {
              channel.sink.add(
                RaceMessage.error(message: 'Room full or race already started').toJson(),
              );
              channel.sink.close();
              return;
            }
            final id = _nextGuestId++;
            assignedId = id;
            _connections[id] = channel;
            final name = msg.payload['displayName'] as String? ?? 'Player $id';
            _players.add(RacePlayerState(playerId: id, displayName: name));

            // Confirm join with full player list
            channel.sink.add(
              RaceMessage.joined(
                assignedId: id,
                players: _players.map((p) => p.toMap()).toList(),
              ).toJson(),
            );

            // Notify everyone else
            _broadcastExcept(
              id,
              RaceMessage.joined(
                assignedId: id,
                players: _players.map((p) => p.toMap()).toList(),
              ).toJson(),
            );

            onEvent?.call(RaceServerEvent(
              RaceServerEventType.playerJoined,
              players: List.from(_players),
            ));

          case RaceMessageType.ready:
            if (assignedId == null) return;
            final isReady = msg.payload['isReady'] as bool? ?? false;
            _updatePlayer(assignedId!, (p) => p.copyWith(isReady: isReady));
            _broadcast(
              RaceMessage.ready(playerId: assignedId!, isReady: isReady).toJson(),
            );
            _maybeNotifyAllReady();

          case RaceMessageType.pos:
            if (assignedId == null) return;
            final dist = (msg.payload['distance'] as num?)?.toDouble() ?? 0.0;
            _updatePlayer(assignedId!, (p) => p.copyWith(distance: dist));
            // Relay to all others (host included via client)
            _broadcastExcept(
              assignedId!,
              RaceMessage.pos(playerId: assignedId!, distance: dist).toJson(),
            );

          case RaceMessageType.abilityUsed:
            if (assignedId == null) return;
            final abilityId = msg.payload['abilityId'] as String? ?? '';
            _broadcastExcept(
              assignedId!,
              RaceMessage.abilityUsed(
                playerId: assignedId!,
                abilityId: abilityId,
              ).toJson(),
            );

          case RaceMessageType.finish:
            if (assignedId == null) return;
            final timeMs = (msg.payload['timeMs'] as num?)?.toInt() ?? 0;
            _handleFinish(assignedId!, timeMs);

          default:
            break;
        }
      },
      onDone: () {
        if (assignedId != null) {
          _handleDisconnect(assignedId!);
        }
      },
      onError: (_) {
        if (assignedId != null) {
          _handleDisconnect(assignedId!);
        }
      },
    );
  }

  void _handleFinish(int playerId, int timeMs) {
    _updatePlayer(playerId, (p) => p.copyWith(isFinished: true, finishTimeMs: timeMs));
    _finishOrder.add({'playerId': playerId, 'timeMs': timeMs});
    _broadcast(RaceMessage.finish(playerId: playerId, timeMs: timeMs).toJson());

    final connected = _players.where((p) => p.isConnected).length;
    if (_finishOrder.length >= connected) {
      _broadcastResults();
    }
  }

  void _handleTimeout() {
    if (_resultsPublished) return;
    // Assign synthetic finish times to players who haven't crossed the line yet
    final finished = Set<int>.from(_finishOrder.map((r) => r['playerId'] as int));
    final unfinished = _players
        .where((p) => p.isConnected && !finished.contains(p.playerId))
        .toList()
      ..sort((a, b) => b.distance.compareTo(a.distance));
    for (final p in unfinished) {
      // Time > 180 s, ranked by how far they got (closer to finish = smaller penalty)
      const trackLength = 10000.0; // mirrors InfiniteRunnerGame.trackLength
      final syntheticMs = 180000 + ((trackLength - p.distance) * 10).round();
      _finishOrder.add({'playerId': p.playerId, 'timeMs': syntheticMs});
    }
    _broadcastResults();
  }

  void _broadcastResults() {
    if (_resultsPublished) return;
    _resultsPublished = true;
    _timeoutTimer?.cancel();
    final rankings = List<Map<String, dynamic>>.from(_finishOrder)
      ..sort((a, b) => (a['timeMs'] as int).compareTo(b['timeMs'] as int));
    _broadcast(RaceMessage.results(rankings: rankings).toJson());
    onEvent?.call(RaceServerEvent(
      RaceServerEventType.resultsReady,
      rankings: rankings,
    ));
  }

  void _handleDisconnect(int playerId) {
    _connections.remove(playerId);
    _updatePlayer(playerId, (p) => p.copyWith(isConnected: false));
    _broadcast(RaceMessage.disconnect(playerId: playerId).toJson());
    onEvent?.call(RaceServerEvent(
      RaceServerEventType.playerDisconnected,
      players: List.from(_players),
      disconnectedId: playerId,
    ));
  }

  void _broadcast(String json) {
    for (final ch in _connections.values) {
      ch.sink.add(json);
    }
    // Also call host listener directly (host receives its own broadcasts via onEvent)
  }

  void _broadcastExcept(int excludeId, String json) {
    for (final entry in _connections.entries) {
      if (entry.key != excludeId) {
        entry.value.sink.add(json);
      }
    }
  }

  void _updatePlayer(int id, RacePlayerState Function(RacePlayerState) fn) {
    final idx = _players.indexWhere((p) => p.playerId == id);
    if (idx >= 0) _players[idx] = fn(_players[idx]);
  }

  void _maybeNotifyAllReady() {
    if (_players.length >= 2 && _players.every((p) => p.isReady)) {
      onEvent?.call(const RaceServerEvent(RaceServerEventType.allReady));
    }
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
      // Fallback: any non-loopback IPv4
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }
}

// ── Server events ──────────────────────────────────────────────────────────

enum RaceServerEventType {
  playerJoined,
  allReady,
  raceStarted,
  playerDisconnected,
  resultsReady,
}

class RaceServerEvent {
  const RaceServerEvent(
    this.type, {
    this.players,
    this.disconnectedId,
    this.rankings,
  });

  final RaceServerEventType type;
  final List<RacePlayerState>? players;
  final int? disconnectedId;
  final List<Map<String, dynamic>>? rankings;
}
