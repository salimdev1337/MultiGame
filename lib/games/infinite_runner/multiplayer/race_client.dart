import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'race_message.dart';
import 'race_player_state.dart';
import 'race_room.dart';
import 'race_server.dart';

/// WebSocket client used by ALL participants (including the host, who runs
/// both a RaceServer and a RaceClient so it receives its own broadcasts).
///
/// Responsibilities:
/// - Connect to `ws://hostIp:4567`
/// - Send `join` on connect
/// - Send `pos` every 100ms during racing
/// - Relay incoming messages to the room model and fire [onEvent]
class RaceClient {
  RaceClient({
    required this.hostIp,
    required this.displayName,
    required this.room,
    this.raceServer,
  });

  final String hostIp;
  final String displayName;
  final RaceRoom room;

  /// If this device is also the host, pass the server so position updates
  /// can be relayed to guests without going through the network loop.
  final RaceServer? raceServer;

  WebSocketChannel? _channel;
  Timer? _posTimer;
  bool _connected = false;
  bool get isConnected => _connected;

  /// Fired when a message changes the room state
  void Function(RaceClientEvent event)? onEvent;

  /// Fired on unrecoverable disconnect
  void Function()? onHostLeft;

  // ── Connection lifecycle ───────────────────────────────────────────────────

  Future<void> connect() async {
    final uri = Uri.parse('ws://$hostIp:$kRaceServerPort');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      _handleMessage,
      onDone: _handleDisconnect,
      onError: (_) => _handleDisconnect(),
    );

    // Send join message
    _send(RaceMessage.join(displayName: displayName).toJson());
    _connected = true;
  }

  Future<void> disconnect() async {
    _posTimer?.cancel();
    _posTimer = null;
    _connected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  // ── Outgoing messages ─────────────────────────────────────────────────────

  void sendReady(bool isReady) {
    _send(
      RaceMessage.ready(playerId: room.localPlayerId, isReady: isReady).toJson(),
    );
  }

  /// Start sending position updates every 100ms.
  /// [getDistance] is called each tick to get the current scroll distance.
  void startPositionBroadcast(double Function() getDistance) {
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final dist = getDistance();
      _send(
        RaceMessage.pos(playerId: room.localPlayerId, distance: dist).toJson(),
      );
      // Also tell the server directly if we're host (avoids echo)
      raceServer?.broadcastHostPos(dist);
    });
  }

  void stopPositionBroadcast() {
    _posTimer?.cancel();
    _posTimer = null;
  }

  void sendAbilityUsed(String abilityId) {
    _send(
      RaceMessage.abilityUsed(
        playerId: room.localPlayerId,
        abilityId: abilityId,
      ).toJson(),
    );
  }

  void sendFinish(int timeMs) {
    _send(
      RaceMessage.finish(playerId: room.localPlayerId, timeMs: timeMs).toJson(),
    );
    if (raceServer != null) {
      raceServer!.recordHostFinish(timeMs);
    }
  }

  // ── Incoming messages ─────────────────────────────────────────────────────

  void _handleMessage(dynamic rawData) {
    final msg = RaceMessage.fromJson(rawData as String);

    switch (msg.type) {
      case RaceMessageType.joined:
        final assignedId = (msg.payload['assignedId'] as num).toInt();
        final playerMaps =
            (msg.payload['players'] as List).cast<Map<String, dynamic>>();
        for (final map in playerMaps) {
          room.upsertPlayer(RacePlayerState.fromMap(map));
        }
        onEvent?.call(RaceClientEvent(
          RaceClientEventType.playerListUpdated,
          assignedId: assignedId,
          players: room.players,
        ));

      case RaceMessageType.ready:
        final id = msg.playerId;
        final isReady = msg.payload['isReady'] as bool? ?? false;
        final existing = room.players.firstWhere(
          (p) => p.playerId == id,
          orElse: () => RacePlayerState(playerId: id, displayName: 'Player $id'),
        );
        room.upsertPlayer(existing.copyWith(isReady: isReady));
        onEvent?.call(RaceClientEvent(
          RaceClientEventType.playerListUpdated,
          players: room.players,
        ));

      case RaceMessageType.start:
        room.phase = RoomPhase.countdown;
        onEvent?.call(const RaceClientEvent(RaceClientEventType.raceStarting));

      case RaceMessageType.pos:
        final dist = (msg.payload['distance'] as num?)?.toDouble() ?? 0.0;
        final existing = room.players.firstWhere(
          (p) => p.playerId == msg.playerId,
          orElse: () => RacePlayerState(
            playerId: msg.playerId,
            displayName: 'Player ${msg.playerId}',
          ),
        );
        room.upsertPlayer(existing.copyWith(distance: dist));
        onEvent?.call(const RaceClientEvent(RaceClientEventType.positionsUpdated));

      case RaceMessageType.abilityUsed:
        onEvent?.call(RaceClientEvent(
          RaceClientEventType.opponentUsedAbility,
          opponentId: msg.playerId,
          abilityId: msg.payload['abilityId'] as String? ?? '',
        ));

      case RaceMessageType.finish:
        final id = msg.playerId;
        final timeMs = (msg.payload['timeMs'] as num?)?.toInt() ?? 0;
        final existing = room.players.firstWhere(
          (p) => p.playerId == id,
          orElse: () => RacePlayerState(playerId: id, displayName: 'Player $id'),
        );
        room.upsertPlayer(existing.copyWith(isFinished: true, finishTimeMs: timeMs));
        onEvent?.call(RaceClientEvent(
          RaceClientEventType.playerFinished,
          opponentId: id,
        ));

      case RaceMessageType.results:
        final rankings =
            (msg.payload['rankings'] as List).cast<Map<String, dynamic>>();
        room.phase = RoomPhase.finished;
        onEvent?.call(RaceClientEvent(
          RaceClientEventType.resultsReceived,
          rankings: rankings,
        ));

      case RaceMessageType.disconnect:
        final id = msg.playerId;
        final existing = room.players.firstWhere(
          (p) => p.playerId == id,
          orElse: () => RacePlayerState(playerId: id, displayName: 'Player $id'),
        );
        room.upsertPlayer(existing.copyWith(isConnected: false));
        onEvent?.call(RaceClientEvent(
          RaceClientEventType.playerDisconnected,
          opponentId: id,
        ));

      case RaceMessageType.error:
        final errorMsg = msg.payload['message'] as String? ?? 'Unknown error';
        onEvent?.call(RaceClientEvent(
          RaceClientEventType.errorReceived,
          errorMessage: errorMsg,
        ));

      default:
        break;
    }
  }

  void _handleDisconnect() {
    _connected = false;
    _posTimer?.cancel();
    // If the host leaves mid-race, notify the UI
    if (room.phase == RoomPhase.racing) {
      onHostLeft?.call();
    }
  }

  void _send(String json) {
    if (_connected && _channel != null) {
      _channel!.sink.add(json);
    }
  }
}

// ── Client events ──────────────────────────────────────────────────────────

enum RaceClientEventType {
  playerListUpdated,
  raceStarting,
  positionsUpdated,
  opponentUsedAbility,
  playerFinished,
  resultsReceived,
  playerDisconnected,
  errorReceived,
}

class RaceClientEvent {
  const RaceClientEvent(
    this.type, {
    this.assignedId,
    this.players,
    this.opponentId,
    this.abilityId,
    this.rankings,
    this.errorMessage,
  });

  final RaceClientEventType type;
  final int? assignedId;
  final List<RacePlayerState>? players;
  final int? opponentId;
  final String? abilityId;
  final List<Map<String, dynamic>>? rankings;
  final String? errorMessage;
}
