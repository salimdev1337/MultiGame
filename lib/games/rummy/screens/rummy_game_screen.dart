import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../logic/rummy_logic.dart';
import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import '../widgets/rummy_center_pile.dart';
import '../widgets/rummy_hand_widget.dart';
import '../widgets/rummy_meld_widget.dart';
import '../widgets/rummy_opponent_widget.dart';
import '../widgets/rummy_score_panel.dart';

class RummyGamePage extends ConsumerWidget {
  const RummyGamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rummyProvider);

    if (state.phase == RummyPhase.idle) {
      return _ModeSelectScreen();
    }

    return _GameScreen();
  }
}

// ── Mode selection ─────────────────────────────────────────────────────────────

class _ModeSelectScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DSColors.rummyFelt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: DSColors.rummyAccent,
          onPressed: () => context.pop(),
        ),
        title: Text('Rummy', style: DSTypography.titleMedium.copyWith(color: DSColors.rummyAccent)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose Difficulty',
              style: DSTypography.titleLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 32),
            for (final diff in AiDifficulty.values)
              _DifficultyButton(difficulty: diff),
          ],
        ),
      ),
    );
  }
}

class _DifficultyButton extends ConsumerWidget {
  const _DifficultyButton({required this.difficulty});
  final AiDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = difficulty.name[0].toUpperCase() + difficulty.name.substring(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.rummyPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(220, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => ref.read(rummyProvider.notifier).startSolo(difficulty),
        child: Text(label, style: DSTypography.buttonLarge),
      ),
    );
  }
}

// ── Active game screen ─────────────────────────────────────────────────────────

class _GameScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rummyProvider);
    final notifier = ref.read(rummyProvider.notifier);

    if (state.phase == RummyPhase.gameOver) {
      return _GameOverScreen(state: state, notifier: notifier);
    }

    final humanPlayer = state.players.isNotEmpty ? state.players[0] : null;

    return Scaffold(
      backgroundColor: DSColors.rummyFelt,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: score + back.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () {
                      notifier.goToIdle();
                      context.pop();
                    },
                  ),
                  Expanded(
                    child: RummyScorePanel(
                      players: state.players,
                      currentPlayerIndex: state.currentPlayerIndex,
                      roundNumber: state.roundNumber,
                    ),
                  ),
                ],
              ),
            ),

            // Opponents row (top + sides).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.players.length > 1)
                    _OpponentSlot(
                      playerIdx: 1,
                      state: state,
                      horizontal: true,
                    ),
                  if (state.players.length > 2)
                    _OpponentSlot(
                      playerIdx: 2,
                      state: state,
                      horizontal: true,
                    ),
                  if (state.players.length > 3)
                    _OpponentSlot(
                      playerIdx: 3,
                      state: state,
                      horizontal: true,
                    ),
                ],
              ),
            ),

            // Center piles.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RummyCenterPile(
                    drawPileCount: state.drawPile.length,
                    topDiscard: state.topDiscard,
                    canDraw: state.isHumanTurn &&
                        state.turnPhase == TurnPhase.draw,
                    onDrawFromDeck: notifier.drawFromDeck,
                    onDrawFromDiscard: notifier.drawFromDiscard,
                  ),
                  const SizedBox(height: 8),
                  // Status message.
                  if (state.statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        state.statusMessage!,
                        style: DSTypography.bodySmall
                            .copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Human player melds.
            if (humanPlayer != null && humanPlayer.melds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RummyMeldWidget(
                  melds: humanPlayer.melds,
                  label: 'Your melds',
                ),
              ),

            // Human action buttons (meld phase).
            if (state.isHumanTurn && state.turnPhase == TurnPhase.meld)
              _ActionBar(state: state, notifier: notifier),

            // Human hand.
            if (humanPlayer != null)
              RummyHandWidget(
                cards: humanPlayer.hand,
                selectedCardIds: state.selectedCardIds,
                onCardTap: (card) {
                  if (state.turnPhase == TurnPhase.meld) {
                    notifier.toggleCardSelection(card.id);
                  } else if (state.turnPhase == TurnPhase.discard ||
                      (state.turnPhase == TurnPhase.meld)) {
                    // Tapping selected card in discard phase discards it.
                  }
                },
                enabled: state.isHumanTurn,
              ),

            // Discard button when in meld phase.
            if (state.isHumanTurn &&
                (state.turnPhase == TurnPhase.meld) &&
                state.selectedCardIds.length == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: const Text('Discard Selected'),
                    onPressed: () {
                      final selectedId = state.selectedCardIds.first;
                      final player = state.players[0];
                      final card = player.hand.firstWhere(
                        (c) => c.id == selectedId,
                        orElse: () => player.hand.first,
                      );
                      notifier.discard(card);
                    },
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OpponentSlot extends StatelessWidget {
  const _OpponentSlot({
    required this.playerIdx,
    required this.state,
    required this.horizontal,
  });

  final int playerIdx;
  final RummyGameState state;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (playerIdx >= state.players.length) {
      return const SizedBox.shrink();
    }
    return RummyOpponentWidget(
      player: state.players[playerIdx],
      isCurrentTurn: state.currentPlayerIndex == playerIdx,
      horizontal: horizontal,
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.state, required this.notifier});
  final RummyGameState state;
  final RummyNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          // Lay meld button.
          if (state.selectedCardIds.length >= 3)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.rummyPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Lay Meld'),
                  onPressed: () {
                    final error = notifier.laySelectedMeld();
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),

          // Declare button.
          if (canDeclare(state.players[0].melds))
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.rummyAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Declare!'),
                  onPressed: notifier.declare,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Game over ────────────────────────────────────────────────────────────────

class _GameOverScreen extends StatelessWidget {
  const _GameOverScreen({required this.state, required this.notifier});
  final RummyGameState state;
  final RummyNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final winners = state.players.where((p) => !p.isEliminated).toList();

    return Scaffold(
      backgroundColor: DSColors.rummyFelt,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎉 Game Over!',
                  style: DSTypography.displaySmall
                      .copyWith(color: DSColors.rummyAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  winners.isEmpty
                      ? 'No winners'
                      : 'Winner${winners.length > 1 ? 's' : ''}: ${winners.map((p) => p.name).join(' & ')}',
                  style: DSTypography.titleMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Final scores.
                ...state.players.map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          p.isEliminated
                              ? Icons.cancel
                              : Icons.emoji_events,
                          color: p.isEliminated
                              ? DSColors.error
                              : DSColors.rummyAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.name}: ${p.score} pts',
                          style: DSTypography.bodyMedium.copyWith(
                            color: p.isEliminated
                                ? DSColors.textDisabled
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.rummyPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => notifier.goToIdle(),
                  child: const Text('Play Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    notifier.goToIdle();
                    context.pop();
                  },
                  child: Text(
                    'Main Menu',
                    style: DSTypography.bodyMedium
                        .copyWith(color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
