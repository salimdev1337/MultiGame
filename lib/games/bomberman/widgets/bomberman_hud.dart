import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/providers/bomberman_notifier.dart';

// Colors matching the grid painter
const _kPlayerColors = [
  Color(0xFF00d4ff),
  Color(0xFFffd700),
  Color(0xFF7c4dff),
  Color(0xFFff6b35),
];

/// Top HUD bar: timer, round wins, round number.
class BombermanHud extends ConsumerWidget {
  const BombermanHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      bombermanProvider.select(
        (s) => (
          round: s.round,
          time: s.roundTimeSeconds,
          wins: s.roundWins,
          players: s.players,
        ),
      ),
    );

    final mins = s.time ~/ 60;
    final secs = s.time % 60;
    final timeStr = '$mins:${secs.toString().padLeft(2, '0')}';
    final danger = s.time <= 30;

    return Container(
      color: const Color(0xFF0d1018),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player status indicators
          Row(
            children: s.players
                .mapIndexed(
                  (i, p) => _PlayerChip(
                    player: p,
                    wins: i < s.wins.length ? s.wins[i] : 0,
                  ),
                )
                .toList(),
          ),

          // Timer
          Text(
            timeStr,
            style: TextStyle(
              color: danger ? const Color(0xFFff4444) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          // Round indicator
          Text(
            'Round ${s.round}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final BombPlayer player;
  final int wins;

  const _PlayerChip({required this.player, required this.wins});

  @override
  Widget build(BuildContext context) {
    final color = _kPlayerColors[player.id % _kPlayerColors.length];
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          // Colored circle
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.isAlive ? color : color.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 4),
          // Lives
          Row(
            children: List.generate(
              3,
              (i) => Icon(
                Icons.favorite,
                size: 10,
                color: i < player.lives ? color : color.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Round wins
          Text(
            '[$wins]',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int, T) f) =>
      List.generate(length, (i) => f(i, this[i]));
}
