import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/games/bomberman/providers/bomberman_notifier.dart';

const _kPlayerColors = [
  Color(0xFF00d4ff),
  Color(0xFFffd700),
  Color(0xFF7c4dff),
  Color(0xFFff6b35),
];

const _kPlayerNames = ['You', 'Bot', 'P3', 'P4'];

/// Overlay that appears on top of the game grid during countdown, round over,
/// and game over phases.
class BombermanOverlay extends ConsumerWidget {
  const BombermanOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(bombermanProvider.select((s) => s.phase));
    final countdown = ref.watch(bombermanProvider.select((s) => s.countdown));
    final msg = ref.watch(bombermanProvider.select((s) => s.roundOverMessage));
    final winnerId = ref.watch(bombermanProvider.select((s) => s.winnerId));
    final wins = ref.watch(bombermanProvider.select((s) => s.roundWins));

    return switch (phase) {
      GamePhase.countdown => _CountdownOverlay(count: countdown),
      GamePhase.roundOver => _RoundOverOverlay(message: msg ?? 'Round Over'),
      GamePhase.gameOver => _GameOverOverlay(
          winnerId: winnerId,
          wins: wins,
          onPlayAgain: () => ref.read(bombermanProvider.notifier).startSolo(),
          onHome: () {
            ref.read(bombermanProvider.notifier).reset();
            context.go(AppRoutes.home);
          },
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Countdown ────────────────────────────────────────────────────────────────

class _CountdownOverlay extends StatelessWidget {
  final int count;
  const _CountdownOverlay({required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        count > 0 ? '$count' : 'GO!',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 80,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          shadows: [
            Shadow(color: Color(0xFF00d4ff), blurRadius: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Round Over ───────────────────────────────────────────────────────────────

class _RoundOverOverlay extends StatelessWidget {
  final String message;
  const _RoundOverOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ROUND OVER',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Next round starting…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Game Over ────────────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final int? winnerId;
  final List<int> wins;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const _GameOverOverlay({
    required this.winnerId,
    required this.wins,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final winnerColor = winnerId != null
        ? _kPlayerColors[winnerId! % _kPlayerColors.length]
        : Colors.white;
    final winnerName = winnerId != null
        ? _kPlayerNames[winnerId! % _kPlayerNames.length]
        : 'Draw';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF111520).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: winnerColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: winnerColor.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 12),
            Icon(
              winnerId != null
                  ? Icons.emoji_events_rounded
                  : Icons.handshake_outlined,
              color: winnerColor,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              winnerId != null ? '$winnerName Wins!' : 'It\'s a Draw!',
              style: TextStyle(
                color: winnerColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: winnerColor.withValues(alpha: 0.5), blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 20),
            // Round wins summary
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                wins.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        _kPlayerNames[i % _kPlayerNames.length],
                        style: TextStyle(
                          color: _kPlayerColors[i % _kPlayerColors.length],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${wins[i]} wins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: winnerColor,
                      foregroundColor: const Color(0xFF111520),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Play Again',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
