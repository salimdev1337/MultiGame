import 'dart:ui';

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: DSColors.rummyAccent.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DSColors.rummyAccent.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 56,
                          color: DSColors.rummyAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Game Over!',
                        style: DSTypography.displaySmall
                            .copyWith(color: DSColors.rummyAccent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        winners.isEmpty
                            ? 'No winners'
                            : 'Winner${winners.length > 1 ? 's' : ''}: ${winners.map((p) => p.name).join(' & ')}',
                        style: DSTypography.titleMedium
                            .copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ...state.players.map(
                        (p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: DSColors.rummyFelt.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                      ),
                      const SizedBox(height: 28),
                      Container(
                        height: 50,
                        constraints: const BoxConstraints(minWidth: 200),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DSColors.rummyPrimary,
                              DSColors.rummyAccent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: DSColors.rummyPrimary.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => notifier.goToIdle(),
                            child: const Center(
                              child: Text(
                                'Play Again',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
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
          ),
        ),
      ),
    );
  }
}
