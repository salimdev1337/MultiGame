import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import '../widgets/tunisian_background.dart';

class RummyGameOverScreen extends StatelessWidget {
  const RummyGameOverScreen({
    super.key,
    required this.state,
    required this.notifier,
  });

  final RummyGameState state;
  final RummyNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final winners = state.players.where((p) => !p.isEliminated).toList();

    return Scaffold(
      backgroundColor: DSColors.rummyFelt,
      body: TunisianBackground(
        child: SafeArea(
          child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Game Over!',
                  style: DSTypography.displaySmall
                      .copyWith(color: DSColors.rummyAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  winners.isEmpty
                      ? 'No winners'
                      : 'Winner${winners.length > 1 ? 's' : ''}: ${winners.map((p) => p.name).join(' & ')}',
                  style:
                      DSTypography.titleMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      ),),
    );
  }
}
