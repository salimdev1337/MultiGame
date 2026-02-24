import 'package:flutter/material.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';

import '../providers/game_2048_notifier.dart';

Future<void> showGame2048GameOverDialog(
  BuildContext context, {
  required Game2048State state,
  required Game2048Notifier notifier,
}) async {
  await notifier.recordGameCompletion();

  if (!context.mounted) return;

  final highestTile = notifier.getHighestTile();
  final milestoneLabel = state.currentMilestoneLabel;
  final isNewBest = state.score >= state.bestScore && state.score > 0;
  final isSuccess = state.highestMilestoneIndex >= 0;
  const accentGreen = Color(0xFF19e6a2);
  const accentRed = Color(0xFFff6b6b);
  final accent = isSuccess ? accentGreen : accentRed;

  GameResultWidget.show(
    context,
    GameResultConfig(
      isVictory: isSuccess,
      title: 'GAME OVER',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
      icon: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Icon(
          isSuccess ? Icons.workspace_premium_rounded : Icons.heart_broken,
          color: accent,
          size: 48,
        ),
      ),
      subtitle: Column(
        children: [
          if (isSuccess) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: accentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$milestoneLabel · ${state.currentMilestoneTile}',
                style: const TextStyle(
                  color: accentGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Final Score',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.score}',
            style: TextStyle(
              color: accent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (isNewBest) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFf59e0b).withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Color(0xFFf59e0b), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'New Best Score!',
                    style: TextStyle(
                      color: Color(0xFFf59e0b),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Highest tile: $highestTile',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
      accentColor: accent,
      stats: const [],
      statsLayout: GameResultStatsLayout.cards,
      primary: GameResultAction(
        label: 'PLAY AGAIN',
        icon: Icons.replay,
        style: GameResultButtonStyle.solid,
        color: accent,
        onTap: () {
          Navigator.pop(context);
          notifier.initializeGame();
        },
      ),
      presentation: GameResultPresentation.dialog,
      animated: false,
      containerBorderRadius: 40,
      containerColor: const Color(0xFF1a1e26),
      contentPadding: const EdgeInsets.all(32),
      constraints: const BoxConstraints(maxWidth: 340),
    ),
  );
}

void showGame2048SettingsDialog(
  BuildContext context, {
  required Game2048Notifier notifier,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1a1e26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            Icons.settings,
            color: const Color(0xFF19e6a2).withValues(alpha: 0.6),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF19e6a2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, color: Color(0xFF19e6a2)),
            ),
            title: const Text(
              'Reset Game',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Start a new game',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              notifier.initializeGame();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF19e6a2)),
          ),
        ),
      ],
    ),
  );
}
