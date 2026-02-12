// Stats panel widget - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sudoku_notifier.dart';

const _primaryCyan = Color(0xFF00d4ff);
const _surfaceDark = Color(0xFF1a1d24);
const _errorRed = Color(0xFFff6b6b);
const _textWhite = Color(0xFFffffff);
const _textGray = Color(0xFF9ca3af);

/// Displays live mistakes / score / time for Sudoku Classic.
/// Consumes [sudokuClassicProvider] directly so that the timer ticking
/// every second only rebuilds this small widget — not the 81-cell grid.
class StatsPanel extends ConsumerWidget {
  final int maxMistakes;

  const StatsPanel({
    super.key,
    this.maxMistakes = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(
      sudokuClassicProvider.select(
        (s) => (
          mistakes: s.mistakes,
          score: s.score,
          formattedTime: s.formattedTime,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
            value: '${stats.mistakes}/$maxMistakes',
            color: stats.mistakes >= maxMistakes ? _errorRed : _textWhite,
            hasGlow: false,
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatItem(
            label: 'SCORE',
            value: _formatScore(stats.score),
            color: _primaryCyan,
            hasGlow: true,
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatItem(
            label: 'TIME',
            value: stats.formattedTime,
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
