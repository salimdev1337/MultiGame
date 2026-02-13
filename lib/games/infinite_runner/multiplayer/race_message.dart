import 'dart:convert';

/// All message types sent over the WebSocket connection
enum RaceMessageType {
  /// Guest → Host: player wants to join the room (includes displayName)
  join,

  /// Host → All: player joined successfully (includes assigned playerId)
  joined,

  /// Any → Any: player toggled ready state
  ready,

  /// Host → All: countdown starts — everyone should show 3-2-1-GO!
  start,

  /// Any → All: position update broadcast every 100ms
  pos,

  /// Any → All: player activated an ability (others apply remote effects)
  abilityUsed,

  /// Any → Host: player crossed the finish line
  finish,

  /// Host → All: final results after everyone finishes or timeout
  results,

  /// Any → All: player disconnected
  disconnect,

  /// Host → Guest: error (e.g. room full)
  error,
}

/// Base class for all race messages.
/// Serialises/deserialises to/from JSON strings sent over WebSocket.
class RaceMessage {
  const RaceMessage({
    required this.type,
    required this.playerId,
    this.payload = const {},
  });

  final RaceMessageType type;

  /// The sender's player ID (0 = host, 1–3 = guests in join order)
  final int playerId;

  /// Type-specific extra data
  final Map<String, dynamic> payload;

  // ── Factory constructors ──────────────────────────────────────────────────

  /// Guest → Host: request to join
  factory RaceMessage.join({required String displayName}) => RaceMessage(
    type: RaceMessageType.join,
    playerId: -1, // Not yet assigned
    payload: {'displayName': displayName},
  );

  /// Host → Guest: welcome + assignment
  factory RaceMessage.joined({
    required int assignedId,
    required List<Map<String, dynamic>> players,
  }) => RaceMessage(
    type: RaceMessageType.joined,
    playerId: 0,
    payload: {'assignedId': assignedId, 'players': players},
  );

  /// Any → All: ready toggle
  factory RaceMessage.ready({required int playerId, required bool isReady}) =>
      RaceMessage(
        type: RaceMessageType.ready,
        playerId: playerId,
        payload: {'isReady': isReady},
      );

  /// Host → All: race is starting
  factory RaceMessage.start() =>
      RaceMessage(type: RaceMessageType.start, playerId: 0);

  /// Any → All: position update (distance 0–10000)
  factory RaceMessage.pos({required int playerId, required double distance}) =>
      RaceMessage(
        type: RaceMessageType.pos,
        playerId: playerId,
        payload: {'distance': distance},
      );

  /// Any → All: ability was activated
  factory RaceMessage.abilityUsed({
    required int playerId,
    required String abilityId,
  }) => RaceMessage(
    type: RaceMessageType.abilityUsed,
    playerId: playerId,
    payload: {'abilityId': abilityId},
  );

  /// Any → Host: crossed finish line
  factory RaceMessage.finish({
    required int playerId,
    required int timeMs,
  }) => RaceMessage(
    type: RaceMessageType.finish,
    playerId: playerId,
    payload: {'timeMs': timeMs},
  );

  /// Host → All: final results
  factory RaceMessage.results({
    required List<Map<String, dynamic>> rankings,
  }) => RaceMessage(
    type: RaceMessageType.results,
    playerId: 0,
    payload: {'rankings': rankings},
  );

  /// Any → All: player disconnected
  factory RaceMessage.disconnect({required int playerId}) =>
      RaceMessage(type: RaceMessageType.disconnect, playerId: playerId);

  /// Host → Guest: error
  factory RaceMessage.error({required String message}) => RaceMessage(
    type: RaceMessageType.error,
    playerId: 0,
    payload: {'message': message},
  );

  // ── Serialisation ─────────────────────────────────────────────────────────

  String toJson() => jsonEncode({
    'type': type.name,
    'playerId': playerId,
    'payload': payload,
  });

  static RaceMessage fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final type = RaceMessageType.values.byName(map['type'] as String);
    return RaceMessage(
      type: type,
      playerId: (map['playerId'] as num).toInt(),
      payload: (map['payload'] as Map<String, dynamic>?) ?? {},
    );
  }
}
