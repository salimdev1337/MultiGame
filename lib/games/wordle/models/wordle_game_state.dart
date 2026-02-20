import 'package:flutter/foundation.dart';
import 'wordle_enums.dart';
import 'wordle_round_state.dart';

const int kWordleWordLength = 5;
const int kWordleMaxGuesses = 6;
const int kWordleRounds = 5;
const int kWordlePointsToWin = 3;

@immutable
class WordleGameState {
  const WordleGameState({
    this.phase = WordlePhase.idle,
    this.role = WordleRole.solo,
    this.roundIndex = 0,
    this.words = const [],
    this.myRound = const WordlePlayerRound(),
    this.myScore = 0,
    this.opponentScore = 0,
    this.opponentAttemptsUsed,
    this.currentInput = '',
    this.invalidWordMessage,
    this.roundWinnerId,
    this.matchWinnerId,
    this.countdownValue,
    this.revealedWord,
    this.myPlayerId = 0,
    this.opponentName,
  });

  final WordlePhase phase;
  final WordleRole role;

  /// Current round index (0–4).
  final int roundIndex;

  /// The 5 answer words for this match.
  /// In multiplayer guest mode, this is empty — host resolves words server-side.
  /// In solo or host mode, populated at match start.
  final List<String> words;

  /// Local player's state for the current round.
  final WordlePlayerRound myRound;

  /// Local player's match score (rounds won).
  final int myScore;

  /// Opponent's match score.
  final int opponentScore;

  /// How many guesses opponent has used this round (null in solo).
  final int? opponentAttemptsUsed;

  /// Letters typed so far (not yet submitted).
  final String currentInput;

  /// Non-null when the last submission was invalid — triggers shake + message.
  final String? invalidWordMessage;

  /// Player ID of round winner (null until round ends).
  final int? roundWinnerId;

  /// Player ID of match winner (null until match ends).
  final int? matchWinnerId;

  /// Countdown number (3, 2, 1, null when done).
  final int? countdownValue;

  /// The answer word revealed at round end.
  final String? revealedWord;

  /// This device's player ID (0 = host/solo, 1 = guest).
  final int myPlayerId;

  /// Opponent's display name (null in solo).
  final String? opponentName;

  bool get isSolo => role == WordleRole.solo;
  bool get isHost => role == WordleRole.host;

  String get currentWord =>
      (words.isNotEmpty && roundIndex < words.length) ? words[roundIndex] : '';

  /// Creates a copy with updated values.
  ///
  /// Uses sentinel pattern for all nullable fields so they can be explicitly
  /// cleared to null by passing null.
  WordleGameState copyWith({
    WordlePhase? phase,
    WordleRole? role,
    int? roundIndex,
    List<String>? words,
    WordlePlayerRound? myRound,
    int? myScore,
    int? opponentScore,
    Object? opponentAttemptsUsed = _sentinel,
    String? currentInput,
    Object? invalidWordMessage = _sentinel,
    Object? roundWinnerId = _sentinel,
    Object? matchWinnerId = _sentinel,
    Object? countdownValue = _sentinel,
    Object? revealedWord = _sentinel,
    int? myPlayerId,
    Object? opponentName = _sentinel,
  }) {
    return WordleGameState(
      phase: phase ?? this.phase,
      role: role ?? this.role,
      roundIndex: roundIndex ?? this.roundIndex,
      words: words ?? this.words,
      myRound: myRound ?? this.myRound,
      myScore: myScore ?? this.myScore,
      opponentScore: opponentScore ?? this.opponentScore,
      opponentAttemptsUsed: opponentAttemptsUsed == _sentinel
          ? this.opponentAttemptsUsed
          : opponentAttemptsUsed as int?,
      currentInput: currentInput ?? this.currentInput,
      invalidWordMessage: invalidWordMessage == _sentinel
          ? this.invalidWordMessage
          : invalidWordMessage as String?,
      roundWinnerId: roundWinnerId == _sentinel
          ? this.roundWinnerId
          : roundWinnerId as int?,
      matchWinnerId: matchWinnerId == _sentinel
          ? this.matchWinnerId
          : matchWinnerId as int?,
      countdownValue: countdownValue == _sentinel
          ? this.countdownValue
          : countdownValue as int?,
      revealedWord: revealedWord == _sentinel
          ? this.revealedWord
          : revealedWord as String?,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      opponentName: opponentName == _sentinel
          ? this.opponentName
          : opponentName as String?,
    );
  }

  WordleGameState clearInvalidWord() => copyWith(invalidWordMessage: null);
  WordleGameState clearCountdown() => copyWith(countdownValue: null);
}

const Object _sentinel = Object();
