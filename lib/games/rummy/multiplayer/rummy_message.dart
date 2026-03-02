import 'dart:convert';

import 'package:multigame/utils/secure_logger.dart';

enum RummyMessageType {
  // Lobby
  join, joined, playerJoined, playerLeft, start,
  // Guest → host actions
  drawDeck, drawDiscard,
  layMeld,      // {cardIds: List<String>}
  addToMeld,    // {cardIds, meldOwnerId, meldIdx}
  discard,      // {cardId}
  declare,
  sortHand,     // {mode: 'bySuit'|'byRank'|'byColor'}
  reorderHand,  // {oldIndex, newIndex}
  // Host → player(s)
  stateUpdate,  // targeted sanitized state
  actionError,  // {message}
  // Connection
  disconnect,
}

class RummyMessage {
  const RummyMessage({required this.type, this.payload = const {}});

  final RummyMessageType type;
  final Map<String, dynamic> payload;

  String encode() => jsonEncode({'type': type.name, 'payload': payload});

  static RummyMessage? tryDecode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final type = RummyMessageType.values.byName(map['type'] as String);
      final payload = (map['payload'] as Map<String, dynamic>?) ?? {};
      return RummyMessage(type: type, payload: payload);
    } catch (e, st) {
      SecureLogger.error('RummyMessage.tryDecode failed', error: e, stackTrace: st);
      return null;
    }
  }

  // ── Factories ───────────────────────────────────────────────────────────────

  static RummyMessage join(String name) =>
      RummyMessage(type: RummyMessageType.join, payload: {'name': name});

  static RummyMessage joined(int playerId, String name, List<Map<String, dynamic>> room) =>
      RummyMessage(
        type: RummyMessageType.joined,
        payload: {'id': playerId, 'name': name, 'room': room},
      );

  static RummyMessage playerJoined(int id, String name) =>
      RummyMessage(type: RummyMessageType.playerJoined, payload: {'id': id, 'name': name});

  static const RummyMessage start = RummyMessage(type: RummyMessageType.start);

  static RummyMessage drawDeck(int playerId) =>
      RummyMessage(type: RummyMessageType.drawDeck, payload: {'playerId': playerId});

  static RummyMessage drawDiscard(int playerId) =>
      RummyMessage(type: RummyMessageType.drawDiscard, payload: {'playerId': playerId});

  static RummyMessage layMeld(int playerId, List<String> cardIds) =>
      RummyMessage(type: RummyMessageType.layMeld, payload: {'playerId': playerId, 'cardIds': cardIds});

  static RummyMessage addToMeld(
    int playerId,
    List<String> cardIds,
    int meldOwnerId,
    int meldIdx,
  ) => RummyMessage(
    type: RummyMessageType.addToMeld,
    payload: {
      'playerId': playerId,
      'cardIds': cardIds,
      'meldOwnerId': meldOwnerId,
      'meldIdx': meldIdx,
    },
  );

  static RummyMessage discard(int playerId, String cardId) =>
      RummyMessage(type: RummyMessageType.discard, payload: {'playerId': playerId, 'cardId': cardId});

  static RummyMessage declare(int playerId) =>
      RummyMessage(type: RummyMessageType.declare, payload: {'playerId': playerId});

  static RummyMessage sortHand(int playerId, String mode) =>
      RummyMessage(type: RummyMessageType.sortHand, payload: {'playerId': playerId, 'mode': mode});

  static RummyMessage reorderHand(int playerId, int oldIndex, int newIndex) =>
      RummyMessage(
        type: RummyMessageType.reorderHand,
        payload: {'playerId': playerId, 'oldIndex': oldIndex, 'newIndex': newIndex},
      );

  static RummyMessage stateUpdate(Map<String, dynamic> sanitizedState) =>
      RummyMessage(type: RummyMessageType.stateUpdate, payload: {'state': sanitizedState});

  static RummyMessage actionError(String message) =>
      RummyMessage(type: RummyMessageType.actionError, payload: {'message': message});

  static const RummyMessage disconnect =
      RummyMessage(type: RummyMessageType.disconnect);
}
