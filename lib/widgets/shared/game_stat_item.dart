import 'package:flutter/material.dart';

const _textGray = Color(0xFF9ca3af);

/// A single stat cell used in horizontal in-game stats rows.
/// Displays a [label] above and a colored [value] below, with optional glow.
///
/// Used by [StatsPanel] (Sudoku Classic) and [_RushStatsPanel] (Sudoku Rush).
class GameStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool hasGlow;

  const GameStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _textGray,
            letterSpacing: 1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.0,
            shadows: hasGlow
                ? [
                    Shadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// A single stat cell with an icon above, value in the middle, label below.
/// Used in the Sudoku Rush stats panel.
class GameStatItemWithIcon extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const GameStatItemWithIcon({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
