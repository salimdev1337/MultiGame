import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

import '../logic/rummy_ai.dart';
import '../logic/rummy_deck.dart';
import '../logic/rummy_logic.dart';
import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../models/rummy_meld.dart';
import '../models/rummy_player.dart';

final rummyProvider =
    NotifierProvider.autoDispose<RummyNotifier, RummyGameState>(
  RummyNotifier.new,
);

class RummyNotifier extends GameStatsNotifier<RummyGameState> {
  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  RummyGameState build() {
    ref.onDispose(_cancelBotTimer);
    return const RummyGameState();
  }

  Timer? _botTimer;

  void _cancelBotTimer() {
    _botTimer?.cancel();
    _botTimer = null;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  void startSolo(AiDifficulty difficulty) {
    _cancelBotTimer();
    final deck = shuffle(generateDeck());
    final dealt = dealHands(deck, kRummyPlayerCount, kRummyHandSize);
    final hands = dealt.hands;
    var remaining = dealt.remaining;

    // Flip top card to start discard pile.
    final firstDiscard = remaining.removeAt(0);

    final players = [
      RummyPlayer(
        id: 0,
        name: 'You',
        isHuman: true,
        hand: hands[0],
        melds: const [],
        score: 0,
        isEliminated: false,
      ),
      RummyPlayer(
        id: 1,
        name: 'Bot 1',
        isHuman: false,
        hand: hands[1],
        melds: const [],
        score: 0,
        isEliminated: false,
      ),
      RummyPlayer(
        id: 2,
        name: 'Bot 2',
        isHuman: false,
        hand: hands[2],
        melds: const [],
        score: 0,
        isEliminated: false,
      ),
      RummyPlayer(
        id: 3,
        name: 'Bot 3',
        isHuman: false,
        hand: hands[3],
        melds: const [],
        score: 0,
        isEliminated: false,
      ),
    ];

    state = RummyGameState(
      players: players,
      drawPile: remaining,
      discardPile: [firstDiscard],
      currentPlayerIndex: 0,
      phase: RummyPhase.playing,
      turnPhase: TurnPhase.draw,
      roundNumber: 1,
      difficulty: difficulty,
      statusMessage: 'Draw a card to begin.',
    );

    _scheduleNextBotTurn();
  }

  void goToIdle() {
    _cancelBotTimer();
    state = const RummyGameState();
  }

  // ── Human actions ───────────────────────────────────────────────────────────

  void drawFromDeck() {
    if (!_canAct(TurnPhase.draw)) {
      state = state.copyWith(statusMessage: 'Not your turn to draw.');
      return;
    }
    if (state.drawPile.isEmpty) {
      _reshuffleDiscard();
    }
    if (state.drawPile.isEmpty) {
      state = state.copyWith(statusMessage: 'Draw pile is empty and discard cannot be reshuffled.');
      return;
    }

    final draw = state.drawPile.last;
    final newDraw = List<PlayingCard>.from(state.drawPile)..removeLast();

    final updatedPlayers = _updatePlayerHand(
      state.currentPlayerIndex,
      add: [draw],
    );

    state = state.copyWith(
      players: updatedPlayers,
      drawPile: newDraw,
      turnPhase: TurnPhase.meld,
      drawnCardThisTurn: draw,
      statusMessage: 'Draw a card or lay down melds.',
    );
  }

  void drawFromDiscard() {
    if (!_canAct(TurnPhase.draw)) {
      state = state.copyWith(statusMessage: 'Not your turn to draw.');
      return;
    }
    final top = state.topDiscard;
    if (top == null) {
      state = state.copyWith(statusMessage: 'Discard pile is empty.');
      return;
    }

    final newDiscard = List<PlayingCard>.from(state.discardPile)..removeLast();
    final updatedPlayers = _updatePlayerHand(
      state.currentPlayerIndex,
      add: [top],
    );

    state = state.copyWith(
      players: updatedPlayers,
      discardPile: newDiscard,
      turnPhase: TurnPhase.meld,
      drawnCardThisTurn: top,
      statusMessage: 'Lay down melds or discard.',
    );
  }

  void toggleCardSelection(String cardId) {
    if (state.turnPhase != TurnPhase.meld) {
      return;
    }
    if (!state.isHumanTurn) {
      return;
    }
    final selected = List<String>.from(state.selectedCardIds);
    if (selected.contains(cardId)) {
      selected.remove(cardId);
    } else {
      selected.add(cardId);
    }
    state = state.copyWith(selectedCardIds: selected);
  }

  /// Attempts to lay down the currently selected cards as a meld.
  String? laySelectedMeld() {
    if (state.turnPhase != TurnPhase.meld) {
      return 'Not your meld phase.';
    }
    if (!state.isHumanTurn) {
      return 'Not your turn.';
    }

    final player = state.currentPlayer;
    final selectedCards = player.hand
        .where((c) => state.selectedCardIds.contains(c.id))
        .toList();

    if (selectedCards.length < 3) {
      return 'Select at least 3 cards.';
    }

    final type = validateMeld(selectedCards);
    if (type == null) {
      return 'Not a valid meld.';
    }

    final meld = RummyMeld(type: type, cards: selectedCards);
    final newHand = player.hand.where((c) => !state.selectedCardIds.contains(c.id)).toList();
    final newMelds = [...player.melds, meld];

    final updatedPlayer = player.copyWith(hand: newHand, melds: newMelds);
    final players = List<RummyPlayer>.from(state.players);
    players[state.currentPlayerIndex] = updatedPlayer;

    state = state.copyWith(
      players: players,
      selectedCardIds: [],
      statusMessage: 'Meld laid! Lay more or discard.',
    );
    return null;
  }

  void discard(PlayingCard card) {
    if (!_canAct(TurnPhase.meld) && !_canAct(TurnPhase.discard)) {
      state = state.copyWith(statusMessage: 'Not your turn to discard.');
      return;
    }
    if (state.turnPhase == TurnPhase.draw) {
      state = state.copyWith(statusMessage: 'Draw a card first.');
      return;
    }

    final player = state.currentPlayer;
    final newHand = List<PlayingCard>.from(player.hand)..remove(card);
    final updatedPlayer = player.copyWith(hand: newHand);
    final players = List<RummyPlayer>.from(state.players);
    players[state.currentPlayerIndex] = updatedPlayer;

    final newDiscard = [...state.discardPile, card];

    final next = nextActivePlayer(state.players, state.currentPlayerIndex);

    state = state.copyWith(
      players: players,
      discardPile: newDiscard,
      currentPlayerIndex: next,
      turnPhase: TurnPhase.draw,
      lastDiscardByPlayer: state.currentPlayerIndex,
      lastDiscardedCard: card,
      drawnCardThisTurn: null,
      selectedCardIds: [],
      statusMessage: state.players[next].isHuman
          ? 'Your turn — draw a card.'
          : '${state.players[next].name}\'s turn...',
    );

    _scheduleNextBotTurn();
  }

  void declare() {
    if (!state.isHumanTurn) {
      state = state.copyWith(statusMessage: 'Not your turn.');
      return;
    }
    if (!canDeclare(state.currentPlayer.melds)) {
      state = state.copyWith(statusMessage: 'Need at least $kRummyMinMeldsToDeclare melds to declare.');
      return;
    }
    _applyDeclare(state.currentPlayerIndex);
  }

  // ── Bot logic ───────────────────────────────────────────────────────────────

  void _scheduleNextBotTurn() {
    _cancelBotTimer();
    if (state.phase != RummyPhase.playing) {
      return;
    }
    if (state.isHumanTurn) {
      return;
    }
    _botTimer = Timer(const Duration(milliseconds: 600), _executeBotTurn);
  }

  void _executeBotTurn() {
    if (state.phase != RummyPhase.playing) {
      return;
    }
    if (state.isHumanTurn) {
      return;
    }

    final selfIdx = state.currentPlayerIndex;
    final self = state.players[selfIdx];
    if (self.isEliminated) {
      _advanceTurn();
      return;
    }

    final decisions = aiDecide(
      state.difficulty,
      self,
      state.topDiscard,
      state,
      selfIdx,
    );

    _applyBotDecisions(decisions, selfIdx);
  }

  void _applyBotDecisions(List<AiDecision> decisions, int selfIdx) {
    for (final decision in decisions) {
      if (state.phase != RummyPhase.playing) {
        return;
      }

      if (decision is DrawFromDeck) {
        _botDraw(selfIdx, fromDiscard: false);
      } else if (decision is DrawFromDiscard) {
        _botDraw(selfIdx, fromDiscard: true);
      } else if (decision is LayMeld) {
        _botLayMeld(selfIdx, decision.meld);
      } else if (decision is DiscardCard) {
        _botDiscard(selfIdx, decision.card);
        return; // discard ends turn
      } else if (decision is DeclareWin) {
        _applyDeclare(selfIdx);
        return;
      }
    }
    // If AI never discarded, fallback: discard highest value card.
    _botFallbackDiscard(selfIdx);
  }

  void _botDraw(int selfIdx, {required bool fromDiscard}) {
    if (fromDiscard && state.topDiscard != null) {
      final top = state.topDiscard!;
      final newDiscard = List<PlayingCard>.from(state.discardPile)..removeLast();
      final updatedPlayers = _updatePlayerHand(selfIdx, add: [top]);
      state = state.copyWith(
        players: updatedPlayers,
        discardPile: newDiscard,
        drawnCardThisTurn: top,
      );
    } else {
      if (state.drawPile.isEmpty) {
        _reshuffleDiscard();
      }
      if (state.drawPile.isEmpty) {
        return;
      }
      final draw = state.drawPile.last;
      final newDraw = List<PlayingCard>.from(state.drawPile)..removeLast();
      final updatedPlayers = _updatePlayerHand(selfIdx, add: [draw]);
      state = state.copyWith(
        players: updatedPlayers,
        drawPile: newDraw,
        drawnCardThisTurn: draw,
      );
    }
  }

  void _botLayMeld(int selfIdx, RummyMeld meld) {
    final player = state.players[selfIdx];
    final meldIds = meld.cards.map((c) => c.id).toSet();
    // Verify the player actually has these cards.
    final actualCards = player.hand.where((c) => meldIds.contains(c.id)).toList();
    if (actualCards.length != meld.cards.length) {
      return;
    }
    final type = validateMeld(actualCards);
    if (type == null) {
      return;
    }
    final validMeld = RummyMeld(type: type, cards: actualCards);
    final newHand = player.hand.where((c) => !meldIds.contains(c.id)).toList();
    final newMelds = [...player.melds, validMeld];
    final updatedPlayer = player.copyWith(hand: newHand, melds: newMelds);
    final players = List<RummyPlayer>.from(state.players);
    players[selfIdx] = updatedPlayer;
    state = state.copyWith(players: players);
  }

  void _botDiscard(int selfIdx, PlayingCard card) {
    final player = state.players[selfIdx];
    // Check the bot actually has this card (may have changed after draw).
    PlayingCard? actual;
    for (final c in player.hand) {
      if (c.id == card.id) {
        actual = c;
        break;
      }
    }
    if (actual == null) {
      _botFallbackDiscard(selfIdx);
      return;
    }

    final newHand = List<PlayingCard>.from(player.hand)..remove(actual);
    final updatedPlayer = player.copyWith(hand: newHand);
    final players = List<RummyPlayer>.from(state.players);
    players[selfIdx] = updatedPlayer;

    final newDiscard = [...state.discardPile, actual];
    final next = nextActivePlayer(state.players, selfIdx);

    state = state.copyWith(
      players: players,
      discardPile: newDiscard,
      currentPlayerIndex: next,
      turnPhase: TurnPhase.draw,
      lastDiscardByPlayer: selfIdx,
      lastDiscardedCard: actual,
      drawnCardThisTurn: null,
      selectedCardIds: [],
      statusMessage: state.players[next].isHuman
          ? 'Your turn — draw a card.'
          : '${state.players[next].name}\'s turn...',
    );

    _scheduleNextBotTurn();
  }

  void _botFallbackDiscard(int selfIdx) {
    final player = state.players[selfIdx];
    if (player.hand.isEmpty) {
      _advanceTurn();
      return;
    }
    final sorted = List<PlayingCard>.from(player.hand)
      ..sort((a, b) => cardPointValue(b).compareTo(cardPointValue(a)));
    _botDiscard(selfIdx, sorted.first);
  }

  void _advanceTurn() {
    final next = nextActivePlayer(state.players, state.currentPlayerIndex);
    state = state.copyWith(
      currentPlayerIndex: next,
      turnPhase: TurnPhase.draw,
      statusMessage: state.players[next].isHuman
          ? 'Your turn — draw a card.'
          : '${state.players[next].name}\'s turn...',
    );
    _scheduleNextBotTurn();
  }

  // ── Declare & round end ─────────────────────────────────────────────────────

  void _applyDeclare(int declarerIdx) {
    state = state.copyWith(
      phase: RummyPhase.declaring,
      statusMessage: '${state.players[declarerIdx].name} declares!',
    );

    // Check discard penalty for previous discard.
    var players = List<RummyPlayer>.from(state.players);
    final declarer = players[declarerIdx];

    if (state.lastDiscardByPlayer != null &&
        state.drawnCardThisTurn != null &&
        checkDiscardPenalty(
            state, declarerIdx, state.drawnCardThisTurn!, declarer)) {
      final penaltyIdx = state.lastDiscardByPlayer!;
      final penalized = players[penaltyIdx];
      players[penaltyIdx] =
          penalized.copyWith(score: penalized.score + 50);
    }

    // Compute round penalties.
    final penalties = computeRoundPenalties(
      state.copyWith(players: players),
      declarerIdx,
    );

    for (final entry in penalties.entries) {
      final p = players[entry.key];
      players[entry.key] = p.copyWith(score: p.score + entry.value);
    }

    // Mark eliminated players (reached 1200).
    final newEliminated = List<int>.from(state.eliminatedPlayers);
    for (var i = 0; i < players.length; i++) {
      if (!players[i].isEliminated &&
          players[i].score >= kRummyEliminationScore) {
        players[i] = players[i].copyWith(isEliminated: true);
        newEliminated.add(i);
      }
    }

    // Check game over (only 0 or 1 active players left).
    final activeCount = players.where((p) => !p.isEliminated).length;
    if (activeCount <= 1) {
      state = state.copyWith(
        players: players,
        eliminatedPlayers: newEliminated,
        phase: RummyPhase.gameOver,
        statusMessage: _buildWinMessage(players),
      );
      // Save score for the winner(s).
      final winners = players.where((p) => !p.isEliminated).toList();
      if (winners.length == 1 && winners.first.isHuman) {
        saveScore('rummy', 1);
      }
      return;
    }

    // Otherwise start a new round.
    state = state.copyWith(
      players: players,
      eliminatedPlayers: newEliminated,
      phase: RummyPhase.roundEnd,
      statusMessage: _buildRoundEndMessage(penalties, declarerIdx, players),
    );

    Timer(const Duration(seconds: 3), _startNewRound);
  }

  void _startNewRound() {
    final deck = shuffle(generateDeck());
    final dealt = dealHands(deck, kRummyPlayerCount, kRummyHandSize);
    var remaining = dealt.remaining;
    final firstDiscard = remaining.removeAt(0);

    final players = state.players.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      return RummyPlayer(
        id: p.id,
        name: p.name,
        isHuman: p.isHuman,
        hand: p.isEliminated ? const [] : dealt.hands[i],
        melds: const [],
        score: p.score,
        isEliminated: p.isEliminated,
      );
    }).toList();

    // First active player leads.
    var startIdx = 0;
    for (var i = 0; i < players.length; i++) {
      if (!players[i].isEliminated) {
        startIdx = i;
        break;
      }
    }

    state = state.copyWith(
      players: players,
      drawPile: remaining,
      discardPile: [firstDiscard],
      currentPlayerIndex: startIdx,
      phase: RummyPhase.playing,
      turnPhase: TurnPhase.draw,
      lastDiscardByPlayer: null,
      lastDiscardedCard: null,
      roundNumber: state.roundNumber + 1,
      drawnCardThisTurn: null,
      selectedCardIds: [],
      statusMessage: players[startIdx].isHuman
          ? 'Round ${state.roundNumber + 1} — draw a card.'
          : '${players[startIdx].name}\'s turn...',
    );

    _scheduleNextBotTurn();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _canAct(TurnPhase required) {
    return state.phase == RummyPhase.playing &&
        state.isHumanTurn &&
        (state.turnPhase == required ||
            (required == TurnPhase.discard &&
                state.turnPhase == TurnPhase.meld));
  }

  List<RummyPlayer> _updatePlayerHand(
    int playerIdx, {
    List<PlayingCard> add = const [],
    List<PlayingCard> remove = const [],
  }) {
    final players = List<RummyPlayer>.from(state.players);
    final player = players[playerIdx];
    final newHand = List<PlayingCard>.from(player.hand)
      ..removeWhere((c) => remove.any((r) => r.id == c.id))
      ..addAll(add);
    players[playerIdx] = player.copyWith(hand: newHand);
    return players;
  }

  void _reshuffleDiscard() {
    if (state.discardPile.length <= 1) {
      return;
    }
    final top = state.discardPile.last;
    final rest = state.discardPile.sublist(0, state.discardPile.length - 1);
    final reshuffled = shuffle(rest);
    state = state.copyWith(
      drawPile: reshuffled,
      discardPile: [top],
    );
  }

  String _buildWinMessage(List<RummyPlayer> players) {
    final winners = players.where((p) => !p.isEliminated).toList();
    if (winners.isEmpty) {
      return 'Game Over! No winners.';
    }
    final names = winners.map((p) => p.name).join(' & ');
    return 'Game Over! $names win!';
  }

  String _buildRoundEndMessage(
    Map<int, int> penalties,
    int declarerIdx,
    List<RummyPlayer> players,
  ) {
    final buffer = StringBuffer('${players[declarerIdx].name} declared!\n');
    for (final entry in penalties.entries) {
      buffer.write('+${entry.value} pts for ${players[entry.key].name}. ');
    }
    return buffer.toString().trim();
  }
}
