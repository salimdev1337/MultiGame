import 'dart:convert';

/// All message types exchanged between host and guests.
enum WordleMessageType {
  // Lobby lifecycle
  join,    // guest → host: {name}
  joined,  // host → guest: {playerId, name}
  start,   // host → all: match is starting

  // Gameplay: guest → host
  submitGuess, // {playerId, guess}

  // Gameplay: host → player(s)
  guessResult,    // {playerId, valid, evaluation?, attemptsUsed, isSolved}
  opponentUpdate, // {attemptsUsed} sent to the OTHER player
  roundWin,       // {winnerId, word} broadcast to all
  matchWin,       // {winnerId, myScore, opponentScore} broadcast to all

  // Connection
  disconnect,
}

class WordleMessage {
  const WordleMessage({required this.type, this.payload = const {}});

  final WordleMessageType type;
  final Map<String, dynamic> payload;

  // ── Factories ──────────────────────────────────────────────────────────────

  static WordleMessage join(String name) =>
      WordleMessage(type: WordleMessageType.join, payload: {'name': name});

  static WordleMessage joined(int playerId, String name) => WordleMessage(
        type: WordleMessageType.joined,
        payload: {'playerId': playerId, 'name': name},
      );

  static const WordleMessage start =
      WordleMessage(type: WordleMessageType.start);

  static WordleMessage submitGuess(int playerId, String guess) => WordleMessage(
        type: WordleMessageType.submitGuess,
        payload: {'playerId': playerId, 'guess': guess},
      );

  static WordleMessage guessResult({
    required int playerId,
    required bool valid,
    List<String>? evaluation,
    required int attemptsUsed,
    required bool isSolved,
  }) =>
      WordleMessage(
        type: WordleMessageType.guessResult,
        payload: {
          'playerId': playerId,
          'valid': valid,
          if (evaluation != null) 'evaluation': evaluation,
          'attemptsUsed': attemptsUsed,
          'isSolved': isSolved,
        },
      );

  static WordleMessage opponentUpdate(int attemptsUsed) => WordleMessage(
        type: WordleMessageType.opponentUpdate,
        payload: {'attemptsUsed': attemptsUsed},
      );

  static WordleMessage roundWin(int winnerId, String word) => WordleMessage(
        type: WordleMessageType.roundWin,
        payload: {'winnerId': winnerId, 'word': word},
      );

  static WordleMessage matchWin({
    required int winnerId,
    required int player0Score,
    required int player1Score,
  }) =>
      WordleMessage(
        type: WordleMessageType.matchWin,
        payload: {
          'winnerId': winnerId,
          'player0Score': player0Score,
          'player1Score': player1Score,
        },
      );

  static const WordleMessage disconnect =
      WordleMessage(type: WordleMessageType.disconnect);

  // ── Serialisation ──────────────────────────────────────────────────────────

  String encode() => jsonEncode({'type': type.name, 'payload': payload});

  static WordleMessage? tryDecode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final type =
          WordleMessageType.values.byName(map['type'] as String);
      final payload =
          (map['payload'] as Map<String, dynamic>?) ?? {};
      return WordleMessage(type: type, payload: payload);
    } catch (_) {
      return null;
    }
  }
}
