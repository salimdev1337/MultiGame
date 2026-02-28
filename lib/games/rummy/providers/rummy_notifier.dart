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

part 'rummy_notifier_bot.dart';
part 'rummy_notifier_round.dart';

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
    ref.onDispose(() {
      _disposed = true;
      _cancelBotTimer();
    });
    return const RummyGameState();
  }

  Timer? _botTimer;
  bool _disposed = false;

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
      meldMinimum: 71,
      turnMeldPoints: 0,
      turnMeldCount: 0,
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
      drawnFromDiscard: false,
      preTurnMeldMinimum: state.meldMinimum,
      preTurnPlayerOpen: state.players[state.currentPlayerIndex].isOpen,
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
      drawnFromDiscard: true,
      preTurnMeldMinimum: state.meldMinimum,
      preTurnPlayerOpen: state.players[state.currentPlayerIndex].isOpen,
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
    final currentIdx = state.currentPlayerIndex;
    final selectedCards = player.hand
        .where((c) => state.selectedCardIds.contains(c.id))
        .toList();

    if (selectedCards.length < 3) {
      return 'Select at least 3 cards.';
    }

    final type = validateMeld(selectedCards);
    final List<List<PlayingCard>> groups;
    if (type != null) {
      groups = [selectedCards];
    } else {
      final partition = tryPartitionIntoMelds(selectedCards);
      if (partition == null) {
        return 'Not a valid meld.';
      }
      groups = partition;
    }

    final newMelds = [
      ...player.melds,
      for (final group in groups)
        RummyMeld(type: validateMeld(group)!, cards: group),
    ];
    final newHand = player.hand.where((c) => !state.selectedCardIds.contains(c.id)).toList();
    final updatedPlayer = player.copyWith(hand: newHand, melds: newMelds);
    var players = List<RummyPlayer>.from(state.players);
    players[currentIdx] = updatedPlayer;

    final meldValue = deadwoodValue(selectedCards);
    final newTurnTotal = state.turnMeldPoints + meldValue;
    final alreadyOpen = player.isOpen;

    var newState = state.copyWith(
      players: players,
      selectedCardIds: [],
      turnMeldPoints: newTurnTotal,
      turnMeldCount: state.turnMeldCount + groups.length,
      statusMessage: groups.length > 1
          ? '${groups.length} melds laid! Lay more or discard.'
          : (alreadyOpen
              ? 'Meld laid! Lay more or discard.'
              : 'Meld laid! $newTurnTotal/${state.meldMinimum} pts to open.'),
    );

    if (!alreadyOpen && newTurnTotal >= state.meldMinimum) {
      final newMinimum = newTurnTotal + 1;
      final openedPlayers = List<RummyPlayer>.from(newState.players);
      openedPlayers[currentIdx] = newState.players[currentIdx].copyWith(isOpen: true);
      newState = newState.copyWith(
        players: openedPlayers,
        meldMinimum: newMinimum,
        statusMessage: 'You opened with $newTurnTotal pts! Min now $newMinimum. Lay more or discard.',
      );
    }

    state = newState;
    _handleFullSets(state.players);

    if (canDeclare(newHand)) {
      _applyDeclare(currentIdx);
    }

    return null;
  }

  /// Adds the currently selected hand-cards to the player's own meld at [meldIdx].
  /// Joker retrieval is automatic: see [tryAddToMeld].
  /// Returns an error string on failure, null on success.
  String? addSelectedCardsToMeld(int meldIdx) {
    if (state.turnPhase != TurnPhase.meld) return 'Not your meld phase.';
    if (!state.isHumanTurn) return 'Not your turn.';
    if (!state.currentPlayer.isOpen) return 'Open with a meld first.';
    if (state.selectedCardIds.isEmpty) return 'Select at least one card.';

    final player = state.currentPlayer;
    final currentIdx = state.currentPlayerIndex;

    if (meldIdx < 0 || meldIdx >= player.melds.length) return 'Invalid meld.';

    final selectedCards = player.hand
        .where((c) => state.selectedCardIds.contains(c.id))
        .toList();
    if (selectedCards.isEmpty) return 'Selected cards not in hand.';

    final result = tryAddToMeld(player.melds[meldIdx], selectedCards);
    if (result == null) return 'Cannot add those cards to that meld.';

    final newMelds = List<RummyMeld>.from(player.melds)..[meldIdx] = result.newMeld;
    final newHand = player.hand
        .where((c) => !state.selectedCardIds.contains(c.id))
        .toList()
      ..addAll(result.retrievedJokers);

    var players = List<RummyPlayer>.from(state.players);
    players[currentIdx] = player.copyWith(hand: newHand, melds: newMelds);

    final msg = result.retrievedJokers.isNotEmpty
        ? 'Joker retrieved! Reuse it in another meld.'
        : 'Cards added to meld.';

    state = state.copyWith(players: players, selectedCardIds: [], statusMessage: msg);
    _handleFullSets(state.players);

    if (canDeclare(newHand)) {
      _applyDeclare(currentIdx);
    }
    return null;
  }

  /// Drag-and-drop: adds [card] from hand to the player's own meld at [meldIdx].
  /// Returns an error string on failure, null on success.
  String? dropCardOnMeld(PlayingCard card, int meldIdx) {
    if (state.turnPhase != TurnPhase.meld) return 'Not your meld phase.';
    if (!state.isHumanTurn) return 'Not your turn.';
    if (!state.currentPlayer.isOpen) return 'Open with a meld first.';

    final player = state.currentPlayer;
    final currentIdx = state.currentPlayerIndex;

    if (meldIdx < 0 || meldIdx >= player.melds.length) return 'Invalid meld.';
    if (!player.hand.any((c) => c.id == card.id)) return 'Card not in hand.';

    final result = tryAddToMeld(player.melds[meldIdx], [card]);
    if (result == null) return 'Cannot add that card to that meld.';

    final newMelds = List<RummyMeld>.from(player.melds)..[meldIdx] = result.newMeld;
    final newHand = player.hand.where((c) => c.id != card.id).toList()
      ..addAll(result.retrievedJokers);

    var players = List<RummyPlayer>.from(state.players);
    players[currentIdx] = player.copyWith(hand: newHand, melds: newMelds);

    final msg = result.retrievedJokers.isNotEmpty
        ? 'Joker retrieved! Reuse it in another meld.'
        : 'Card added to meld.';

    state = state.copyWith(players: players, selectedCardIds: [], statusMessage: msg);
    _handleFullSets(state.players);

    if (canDeclare(newHand)) {
      _applyDeclare(currentIdx);
    }
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

    // Revert guard: if player hasn't met the opening minimum, return melds to hand.
    final player0 = state.currentPlayer;
    if (!player0.isOpen && state.turnMeldCount > 0) {
      final meldedThisTurn = player0.melds.sublist(player0.melds.length - state.turnMeldCount);
      final revertedCards = meldedThisTurn.expand((m) => m.cards).toList();
      final revertedMelds = player0.melds.sublist(0, player0.melds.length - state.turnMeldCount);
      final revertedHand = [...player0.hand, ...revertedCards];
      final revertedPlayers = List<RummyPlayer>.from(state.players);
      revertedPlayers[state.currentPlayerIndex] = player0.copyWith(
        hand: revertedHand,
        melds: revertedMelds,
      );
      state = state.copyWith(
        players: revertedPlayers,
        turnMeldPoints: 0,
        turnMeldCount: 0,
        statusMessage: 'Need >= ${state.meldMinimum} pts to open. Melds returned.',
      );
    }

    final player = state.currentPlayer;
    final currentIdx = state.currentPlayerIndex;
    final newHand = List<PlayingCard>.from(player.hand)..remove(card);
    final updatedPlayer = player.copyWith(hand: newHand);
    final players = List<RummyPlayer>.from(state.players);
    players[currentIdx] = updatedPlayer;

    final newDiscard = [...state.discardPile, card];

    if (newHand.isEmpty) {
      state = state.copyWith(
        players: players,
        discardPile: newDiscard,
        lastDiscardByPlayer: currentIdx,
        lastDiscardedCard: card,
        drawnCardThisTurn: null,
        selectedCardIds: [],
        turnMeldPoints: 0,
        turnMeldCount: 0,
      );
      _applyDeclare(currentIdx);
      return;
    }

    final next = nextActivePlayer(state.players, currentIdx);

    state = state.copyWith(
      players: players,
      discardPile: newDiscard,
      currentPlayerIndex: next,
      turnPhase: TurnPhase.draw,
      lastDiscardByPlayer: currentIdx,
      lastDiscardedCard: card,
      drawnCardThisTurn: null,
      selectedCardIds: [],
      turnMeldPoints: 0,
      turnMeldCount: 0,
      drawnFromDiscard: false,
      statusMessage: state.players[next].isHuman
          ? 'Your turn — draw a card.'
          : '${state.players[next].name}\'s turn...',
    );

    _scheduleNextBotTurn();
  }

  void reorderHand(int oldIndex, int newIndex) {
    if (state.players.isEmpty) {
      return;
    }
    final player = state.players[0];
    final hand = List<PlayingCard>.from(player.hand);
    if (oldIndex < 0 || oldIndex >= hand.length || newIndex < 0 || newIndex >= hand.length) {
      return;
    }
    final card = hand.removeAt(oldIndex);
    hand.insert(newIndex, card);
    final updatedPlayer = player.copyWith(hand: hand);
    final players = List<RummyPlayer>.from(state.players);
    players[0] = updatedPlayer;
    state = state.copyWith(players: players, handSortMode: HandSortMode.none);
  }

  void sortHand(HandSortMode mode) {
    if (state.players.isEmpty) {
      return;
    }
    final player = state.players[0];
    final hand = List<PlayingCard>.from(player.hand);

    switch (mode) {
      case HandSortMode.bySuit:
        hand.sort((a, b) {
          final suitCmp = a.suit.compareTo(b.suit);
          return suitCmp != 0 ? suitCmp : a.rank.compareTo(b.rank);
        });
      case HandSortMode.byRank:
        hand.sort((a, b) {
          final rankCmp = a.rank.compareTo(b.rank);
          return rankCmp != 0 ? rankCmp : a.suit.compareTo(b.suit);
        });
      case HandSortMode.byColor:
        hand.sort((a, b) {
          final aColor = a.isRed ? 0 : 1;
          final bColor = b.isRed ? 0 : 1;
          final colorCmp = aColor.compareTo(bColor);
          if (colorCmp != 0) {
            return colorCmp;
          }
          final suitCmp = a.suit.compareTo(b.suit);
          return suitCmp != 0 ? suitCmp : a.rank.compareTo(b.rank);
        });
      case HandSortMode.none:
        return;
    }

    final updatedPlayer = player.copyWith(hand: hand);
    final players = List<RummyPlayer>.from(state.players);
    players[0] = updatedPlayer;
    state = state.copyWith(players: players, handSortMode: mode);
  }

  void declare() {
    if (!state.isHumanTurn) {
      state = state.copyWith(statusMessage: 'Not your turn.');
      return;
    }
    if (!canDeclare(state.currentPlayer.hand)) {
      state = state.copyWith(statusMessage: 'Empty your hand to declare.');
      return;
    }
    _applyDeclare(state.currentPlayerIndex);
  }

  /// Undoes the most recent human action this turn.
  /// Priority: undo last meld → undo draw from discard.
  void undo() {
    if (!state.isHumanTurn || state.turnPhase != TurnPhase.meld) {
      return;
    }
    if (state.turnMeldCount > 0) {
      _undoLastMeld();
    } else if (state.drawnFromDiscard) {
      _undoDrawFromDiscard();
    }
  }

  void _undoLastMeld() {
    final player = state.currentPlayer;
    final currentIdx = state.currentPlayerIndex;
    if (player.melds.isEmpty || state.turnMeldCount == 0) {
      return;
    }

    final lastMeld = player.melds.last;
    final meldValue = deadwoodValue(lastMeld.cards);
    final newTurnPoints = state.turnMeldPoints - meldValue;
    final newTurnCount = state.turnMeldCount - 1;

    final shouldRevertOpen = !state.preTurnPlayerOpen &&
        player.isOpen &&
        newTurnPoints < state.preTurnMeldMinimum;

    final players = List<RummyPlayer>.from(state.players);
    players[currentIdx] = player.copyWith(
      hand: [...player.hand, ...lastMeld.cards],
      melds: player.melds.sublist(0, player.melds.length - 1),
      isOpen: shouldRevertOpen ? false : player.isOpen,
    );

    state = state.copyWith(
      players: players,
      selectedCardIds: [],
      turnMeldPoints: newTurnPoints,
      turnMeldCount: newTurnCount,
      meldMinimum: shouldRevertOpen ? state.preTurnMeldMinimum : state.meldMinimum,
      statusMessage: 'Meld undone.',
    );
  }

  void _undoDrawFromDiscard() {
    if (!state.drawnFromDiscard || state.drawnCardThisTurn == null) {
      return;
    }
    final player = state.currentPlayer;
    final currentIdx = state.currentPlayerIndex;
    final card = state.drawnCardThisTurn!;

    final newHand = player.hand.where((c) => c.id != card.id).toList();
    final players = List<RummyPlayer>.from(state.players);
    players[currentIdx] = player.copyWith(hand: newHand);

    state = state.copyWith(
      players: players,
      discardPile: [...state.discardPile, card],
      turnPhase: TurnPhase.draw,
      drawnFromDiscard: false,
      drawnCardThisTurn: null,
      selectedCardIds: [],
      statusMessage: 'Draw undone — pick a card.',
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Marks any 4-card set as completing (triggers flash), then removes after 500 ms.
  void _handleFullSets(List<RummyPlayer> players) {
    final completing = <String>{};
    for (final p in players) {
      for (final m in p.melds) {
        if (m.type == MeldType.set && m.cards.length == 4) {
          completing.add(m.cards.first.id);
        }
      }
    }
    if (completing.isEmpty) {
      return;
    }
    state = state.copyWith(
      completingMeldIds: {...state.completingMeldIds, ...completing},
    );
    Timer(const Duration(milliseconds: 500), () {
      if (_disposed || state.phase != RummyPhase.playing) {
        return;
      }
      final pruned = state.players.map((p) {
        final kept = p.melds
            .where((m) => !completing.contains(m.cards.first.id))
            .toList();
        if (kept.length == p.melds.length) {
          return p;
        }
        return p.copyWith(melds: kept);
      }).toList();
      state = state.copyWith(
        players: pruned,
        completingMeldIds: state.completingMeldIds.difference(completing),
      );
    });
  }

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
}
