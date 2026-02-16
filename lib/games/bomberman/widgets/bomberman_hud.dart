import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/bomberman/providers/bomberman_notifier.dart';

/// Top HUD bar: score (left) + timer (right) with icon accents.
class BombermanHud extends ConsumerWidget {
  const BombermanHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      bombermanProvider.select(
        (s) => (
          time: s.roundTimeSeconds,
          wins: s.roundWins,
        ),
      ),
    );

    final mins = s.time ~/ 60;
    final secs = s.time % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')} : ${secs.toString().padLeft(2, '0')}';
    final danger = s.time <= 30;
    final score = s.wins.isNotEmpty ? s.wins[0] * 500 : 0;

    return Container(
      color: const Color(0xFF0a0c14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score — gem icon + label + value
          _HudMetric(
            icon: Icons.diamond_outlined,
            iconColor: const Color(0xFF00b4ff),
            label: 'SCORE',
            value: score.toString(),
            valueColor: Colors.white,
          ),

          // Timer — value + flame icon
          _HudMetric(
            icon: Icons.local_fire_department_rounded,
            iconColor: danger ? const Color(0xFFff4444) : const Color(0xFFff7043),
            label: 'TIME',
            value: timeStr,
            valueColor: danger ? const Color(0xFFff4444) : Colors.white,
            iconOnRight: true,
          ),
        ],
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool iconOnRight;

  const _HudMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.iconOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: iconColor, size: 20);
    final textWidget = Column(
      crossAxisAlignment:
          iconOnRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            height: 1.1,
          ),
        ),
      ],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconOnRight
          ? [textWidget, const SizedBox(width: 8), iconWidget]
          : [iconWidget, const SizedBox(width: 8), textWidget],
    );
  }
}
