// Stats panel widget - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';

const _primaryCyan = Color(0xFF00d4ff);
const _surfaceDark = Color(0xFF1a1d24);
const _errorRed = Color(0xFFff6b6b);
const _textWhite = Color(0xFFffffff);
const _textGray = Color(0xFF9ca3af);

class StatsPanel extends StatelessWidget {
  final int mistakes;

  final int score;

  final String formattedTime;

  final int maxMistakes;

  const StatsPanel({
    super.key,
    required this.mistakes,
    required this.score,
    required this.formattedTime,
    this.maxMistakes = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.6 * 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05 * 255),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2 * 255),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'MISTAKES',
            value: '$mistakes/$maxMistakes',
            color: mistakes >= maxMistakes ? _errorRed : _textWhite,
            hasGlow: false,
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withValues(alpha: 0.1 * 255),
          ),
          _StatItem(
            label: 'SCORE',
            value: _formatScore(score),
            color: _primaryCyan,
            hasGlow: true,
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withValues(alpha: 0.1 * 255),
          ),
          _StatItem(
            label: 'TIME',
            value: formattedTime,
            color: _textWhite,
            hasGlow: false,
          ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool hasGlow;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.hasGlow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
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
                      color: color.withValues(alpha: 0.5 * 255),
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
