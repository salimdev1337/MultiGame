import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/utils/secure_logger.dart';

import '../logic/word_database.dart';
import '../logic/wordle_evaluator.dart';
import '../models/wordle_enums.dart';
import '../models/wordle_game_state.dart';
import '../models/wordle_round_state.dart';
import '../multiplayer/wordle_client.dart';
import '../multiplayer/wordle_message.dart';
import '../multiplayer/wordle_server.dart';

final wordleProvider =
    NotifierProvider.autoDispose<WordleNotifier, WordleGameState>(
      WordleNotifier.new,
    );

class WordleNotifier extends GameStatsNotifier<WordleGameState> {
  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  WordleGameState build() {
    ref.onDispose(_dispose);
    return const WordleGameState();
  }

  // ── Private state ──────────────────────────────────────────────────────────

  WordleServer? _server;
  WordleClient? _client;
  Timer? _invalidWordTimer;
  Timer? _countdownTimer;
  Timer? _roundEndTimer;
  bool _disposed = false;

  /// Stores the in-flight guess word for a guest between send and guessResult.
  String _pendingGuessWord = '';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Starts a solo (single-player) match.
  Future<void> startSolo() async {
    try {
      await WordDatabase.initialize();
    } catch (e, st) {
      SecureLogger.error(
        'Failed to initialize WordDatabase in startSolo',
        error: e,
        stackTrace: st,
      );
      state = const WordleGameState().copyWith(
        phase: WordlePhase.error,
        role: WordleRole.solo,
      );
      return;
    }
    final seed = Random().nextInt(1 << 30);
    final words = WordDatabase.selectWords(seed, kWordleRounds);

    state = const WordleGameState().copyWith(
      phase: WordlePhase.countdown,
      role: WordleRole.solo,
      words: words,
    );
    _startCountdown();
  }

  /// Host takes ownership of [server] and [client] from the lobby.
  Future<void> startMultiplayerHost({
    required WordleServer server,
    required WordleClient client,
    required List<({int id, String name})> players,
  }) async {
    try {
      await WordDatabase.initialize();
    } catch (e, st) {
      SecureLogger.error(
        'Failed to initialize WordDatabase in startMultiplayerHost',
        error: e,
        stackTrace: st,
      );
      state = const WordleGameState().copyWith(phase: WordlePhase.error);
      return;
    }
    _server = server;
    _client = client;

    // Wire incoming messages (guest inputs) to the host handler
    _server!.onMessage = _onHostMessage;

    final seed = Random().nextInt(1 << 30);
    final words = WordDatabase.selectWords(seed, kWordleRounds);

    state = const WordleGameState().copyWith(
      phase: WordlePhase.countdown,
      role: WordleRole.host,
      words: words,
      myPlayerId: 0,
      opponentName: players
          .where((p) => p.id != 0)
          .map((p) => p.name)
          .firstOrNull,
    );

    _startCountdown();
  }

  /// Guest connects to host and waits for frame updates.
  void connectAsGuest({
    required WordleClient client,
    required int localPlayerId,
  }) {
    _client = client;
    _client!.onMessage = _onGuestMessage;

    state = const WordleGameState().copyWith(
      phase: WordlePhase.countdown,
      role: WordleRole.guest,
      myPlayerId: localPlayerId,
    );
    // Mirror the host's 3-second countdown so the guest transitions to
    // roundActive at the same time as the host.
    _startCountdown();
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  void typeKey(String letter) {
    if (state.phase != WordlePhase.roundActive) {
      return;
    }
    if (state.myRound.isFinished) {
      return;
    }
    if (state.currentInput.length >= kWordleWordLength) {
      return;
    }
    state = state.copyWith(
      currentInput: state.currentInput + letter.toUpperCase(),
      invalidWordMessage: null,
    );
  }

  void deleteLast() {
    if (state.phase != WordlePhase.roundActive) {
      return;
    }
    if (state.currentInput.isEmpty) {
      return;
    }
    state = state.copyWith(
      currentInput: state.currentInput.substring(
        0,
        state.currentInput.length - 1,
      ),
      invalidWordMessage: null,
    );
  }

  void submitGuess() {
    if (state.phase != WordlePhase.roundActive) {
      return;
    }
    if (state.myRound.isFinished) {
      return;
    }
    final guess = state.currentInput.toLowerCase();
    if (guess.length != kWordleWordLength) {
      return;
    }

    if (state.role == WordleRole.guest) {
      // Save the word before sending — clear input only when guessResult arrives
      _pendingGuessWord = guess;
      _client?.sendGuess(state.myPlayerId, guess);
      return;
    }

    // Solo or host — validate and evaluate locally
    _processGuess(playerId: state.myPlayerId, guess: guess, fromHost: true);
  }

  // ── Solo / Host guess processing ───────────────────────────────────────────

  void _processGuess({
    required int playerId,
    required String guess,
    required bool fromHost,
  }) {
    final isMyGuess = playerId == state.myPlayerId;
    final word = state.currentWord;

    if (!WordDatabase.isValidGuess(guess)) {
      if (isMyGuess) {
        _showInvalidWord('Not in word list');
      } else {
        // Tell the guest their guess was invalid
        _server?.sendTo(
          playerId,
          WordleMessage.guessResult(
            playerId: playerId,
            valid: false,
            attemptsUsed: state.opponentAttemptsUsed ?? 0,
            isSolved: false,
          ).encode(),
        );
      }
      // Keep currentInput intact so the player can fix their word
      return;
    }

    final evaluation = evaluateGuess(guess, word);
    final solved = isCorrectGuess(evaluation);
    final wordleGuess = WordleGuess(word: guess, evaluation: evaluation);

    if (isMyGuess) {
      // Update local state
      final newRound = state.myRound.addGuess(wordleGuess, solved: solved);
      state = state.copyWith(myRound: newRound, currentInput: '');

      // In multiplayer, tell the opponent how many guesses we've used
      if (!state.isSolo) {
        final opponentId = state.myPlayerId == 0 ? 1 : 0;
        _server?.sendTo(
          opponentId,
          WordleMessage.opponentUpdate(newRound.attemptsUsed).encode(),
        );
      }

      if (solved || newRound.isExhausted) {
        _checkRoundOver();
      }
    } else {
      // Guest's guess received at host — track opponent progress
      // Track opponent's guess count via opponentAttemptsUsed
      final newOpponentAttempts = (state.opponentAttemptsUsed ?? 0) + 1;

      // Send result back to guest
      _server?.sendTo(
        playerId,
        WordleMessage.guessResult(
          playerId: playerId,
          valid: true,
          evaluation: evaluation.map((t) => t.name).toList(),
          attemptsUsed: newOpponentAttempts,
          isSolved: solved,
        ).encode(),
      );

      // Notify local host of opponent's progress
      _server?.sendTo(
        state.myPlayerId,
        WordleMessage.opponentUpdate(newOpponentAttempts).encode(),
      );

      state = state.copyWith(opponentAttemptsUsed: newOpponentAttempts);

      if (solved || newOpponentAttempts >= kWordleMaxGuesses) {
        _checkRoundOver(opponentSolvedId: solved ? playerId : null);
      }
    }
  }

  void _checkRoundOver({int? opponentSolvedId}) {
    final mySolved = state.myRound.isSolved;
    final myExhausted = state.myRound.isExhausted;
    final opponentExhausted =
        (state.opponentAttemptsUsed ?? 0) >= kWordleMaxGuesses;

    if (state.isSolo) {
      if (mySolved || myExhausted) {
        _endRound(winnerId: mySolved ? state.myPlayerId : null);
      }
      return;
    }

    // Multiplayer: round ends when either player finishes or both exhaust
    final roundDone =
        mySolved ||
        opponentSolvedId != null ||
        (myExhausted && opponentExhausted);

    if (!roundDone) {
      return;
    }

    int? winnerId;
    if (mySolved && opponentSolvedId != null) {
      // Both solved — first arrival wins (host processes msgs sequentially)
      winnerId = state.myPlayerId;
    } else if (mySolved) {
      winnerId = state.myPlayerId;
    } else if (opponentSolvedId != null) {
      winnerId = opponentSolvedId;
    }

    _endRound(winnerId: winnerId);
  }

  void _endRound({int? winnerId}) {
    int newMyScore = state.myScore;
    int newOpponentScore = state.opponentScore;

    if (winnerId == state.myPlayerId) {
      newMyScore++;
    } else if (winnerId != null) {
      newOpponentScore++;
    }

    state = state.copyWith(
      phase: WordlePhase.roundEnd,
      roundWinnerId: winnerId,
      revealedWord: state.currentWord,
      myScore: newMyScore,
      opponentScore: newOpponentScore,
    );

    // Broadcast to guests in multiplayer
    if (state.isHost) {
      _server?.broadcast(
        WordleMessage.roundWin(winnerId ?? -1, state.currentWord).encode(),
      );
    }

    // Check match end
    final matchOver =
        newMyScore >= kWordlePointsToWin ||
        newOpponentScore >= kWordlePointsToWin ||
        state.roundIndex >= kWordleRounds - 1;

    if (matchOver) {
      _roundEndTimer = Timer(const Duration(milliseconds: 2500), () {
        if (_disposed) {
          return;
        }
        final matchWinnerId = newMyScore > newOpponentScore
            ? state.myPlayerId
            : newMyScore < newOpponentScore
            ? (state.myPlayerId == 0 ? 1 : 0)
            : null;

        state = state.copyWith(
          phase: WordlePhase.matchEnd,
          matchWinnerId: matchWinnerId,
        );

        if (state.isHost) {
          _server?.broadcast(
            WordleMessage.matchWin(
              winnerId: matchWinnerId ?? -1,
              player0Score: state.myPlayerId == 0
                  ? newMyScore
                  : newOpponentScore,
              player1Score: state.myPlayerId == 0
                  ? newOpponentScore
                  : newMyScore,
            ).encode(),
          );
        }

        // Save score (rounds won as score)
        saveScore('wordle', newMyScore);
      });
    } else {
      _roundEndTimer = Timer(const Duration(milliseconds: 2500), () {
        if (_disposed) {
          return;
        }
        _advanceRound();
      });
    }
  }

  void _advanceRound() {
    state = state.copyWith(
      phase: WordlePhase.roundActive,
      roundIndex: state.roundIndex + 1,
      myRound: const WordlePlayerRound(),
      opponentAttemptsUsed: null,
      currentInput: '',
      roundWinnerId: null,
      revealedWord: null,
      invalidWordMessage: null,
    );
  }

  // ── Countdown ──────────────────────────────────────────────────────────────

  void _startCountdown() {
    var count = 3;
    state = state.copyWith(countdownValue: count);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_disposed) {
        t.cancel();
        return;
      }
      count--;
      if (count <= 0) {
        t.cancel();
        state = state.copyWith(
          phase: WordlePhase.roundActive,
          countdownValue: null,
        );
      } else {
        state = state.copyWith(countdownValue: count);
      }
    });
  }

  // ── Invalid word feedback ──────────────────────────────────────────────────

  void _showInvalidWord(String message) {
    _invalidWordTimer?.cancel();
    state = state.copyWith(invalidWordMessage: message);
    _invalidWordTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!_disposed) {
        state = state.clearInvalidWord();
      }
    });
  }

  // ── Network: host receives guest input ────────────────────────────────────

  void _onHostMessage(WordleMessage msg, int fromPlayerId) {
    switch (msg.type) {
      case WordleMessageType.submitGuess:
        final guess = msg.payload['guess'] as String? ?? '';
        _processGuess(
          playerId: fromPlayerId,
          guess: guess.toLowerCase(),
          fromHost: false,
        );
      case WordleMessageType.disconnect:
        // Opponent disconnected → auto-win round
        _endRound(winnerId: state.myPlayerId);
      default:
        break;
    }
  }

  // ── Network: guest receives host updates ──────────────────────────────────

  void _onGuestMessage(WordleMessage msg) {
    switch (msg.type) {
      case WordleMessageType.guessResult:
        _handleGuestGuessResult(msg);
      case WordleMessageType.opponentUpdate:
        final attempts = msg.payload['attemptsUsed'] as int? ?? 0;
        state = state.copyWith(opponentAttemptsUsed: attempts);
      case WordleMessageType.roundWin:
        final winnerId = msg.payload['winnerId'] as int?;
        final word = msg.payload['word'] as String? ?? '';
        int newMyScore = state.myScore;
        int newOpponentScore = state.opponentScore;
        if (winnerId == state.myPlayerId) {
          newMyScore++;
        } else if (winnerId != null && winnerId != -1) {
          newOpponentScore++;
        }
        state = state.copyWith(
          phase: WordlePhase.roundEnd,
          roundWinnerId: winnerId == -1 ? null : winnerId,
          revealedWord: word,
          myScore: newMyScore,
          opponentScore: newOpponentScore,
        );
        // Mirror the host's 2.5s round-advance timer on the guest side
        _roundEndTimer?.cancel();
        _roundEndTimer = Timer(const Duration(milliseconds: 2500), () {
          if (_disposed || state.phase != WordlePhase.roundEnd) {
            return;
          }
          _advanceRound();
        });
      case WordleMessageType.matchWin:
        final winnerId = msg.payload['winnerId'] as int?;
        final p0Score = msg.payload['player0Score'] as int? ?? 0;
        final p1Score = msg.payload['player1Score'] as int? ?? 0;
        final myScore = state.myPlayerId == 0 ? p0Score : p1Score;
        final opponentScore = state.myPlayerId == 0 ? p1Score : p0Score;
        _roundEndTimer?.cancel(); // cancel round-advance timer if match is over
        state = state.copyWith(
          phase: WordlePhase.matchEnd,
          matchWinnerId: winnerId == -1 ? null : winnerId,
          myScore: myScore,
          opponentScore: opponentScore,
        );
        saveScore('wordle', myScore);
      case WordleMessageType.disconnect:
        // Host disconnected — handled by lobby
        break;
      default:
        break;
    }
  }

  void _handleGuestGuessResult(WordleMessage msg) {
    final valid = msg.payload['valid'] as bool? ?? false;
    final isSolved = msg.payload['isSolved'] as bool? ?? false;
    final evaluationRaw = msg.payload['evaluation'] as List?;

    if (!valid) {
      _showInvalidWord('Not in word list');
      return;
    }

    if (evaluationRaw == null) {
      return;
    }

    final evaluation = evaluationRaw.map((t) {
      try {
        return TileState.values.byName(t as String);
      } catch (e) {
        SecureLogger.error(
          'Invalid TileState name in guessResult: $t',
          error: e,
        );
        return TileState.absent;
      }
    }).toList();

    final guess = WordleGuess(
      word: _pendingGuessWord.isNotEmpty
          ? _pendingGuessWord
          : state.currentInput.toLowerCase(),
      evaluation: evaluation,
    );
    _pendingGuessWord = '';

    final newRound = state.myRound.addGuess(guess, solved: isSolved);
    state = state.copyWith(myRound: newRound, currentInput: '');
  }

  // ── Disposal ───────────────────────────────────────────────────────────────

  void _dispose() {
    _disposed = true;
    _invalidWordTimer?.cancel();
    _countdownTimer?.cancel();
    _roundEndTimer?.cancel();
    _server?.stop();
    _client?.disconnect();
    _server = null;
    _client = null;
  }
}
