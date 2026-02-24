import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/rummy_game_state.dart';
import '../models/rummy_player.dart';

/// Compact score panel shown at the top of the game screen.
class RummyScorePanel extends StatelessWidget {
  const RummyScorePanel({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.roundNumber,
  });

  final List<RummyPlayer> players;
  final int currentPlayerIndex;
  final int roundNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DSColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Round $roundNumber',
            style: DSTypography.labelSmall.copyWith(color: DSColors.textTertiary),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: players
                  .asMap()
                  .entries
                  .map((e) => _PlayerScore(
                        player: e.value,
                        isCurrent: e.key == currentPlayerIndex,
                      ))
                  .toList(),
            ),
          ),
          Text(
            '/$kRummyEliminationScore',
            style: DSTypography.labelSmall.copyWith(color: DSColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  const _PlayerScore({required this.player, required this.isCurrent});
  final RummyPlayer player;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final eliminated = player.isEliminated;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: eliminated
            ? DSColors.surfaceHighlight.withValues(alpha: 0.4)
            : isCurrent
                ? DSColors.rummyPrimary.withValues(alpha: 0.3)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent
            ? Border.all(color: DSColors.rummyAccent, width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            style: DSTypography.labelSmall.copyWith(
              color: eliminated ? DSColors.textDisabled : DSColors.textSecondary,
              fontSize: 9,
            ),
          ),
          Text(
            '${player.score}',
            style: DSTypography.labelSmall.copyWith(
              color: eliminated
                  ? DSColors.textDisabled
                  : isCurrent
                      ? DSColors.rummyAccent
                      : DSColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          if (eliminated)
            Text(
              'OUT',
              style: DSTypography.labelSmall.copyWith(
                color: DSColors.error,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
