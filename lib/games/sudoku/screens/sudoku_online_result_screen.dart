import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sudoku_online_provider.dart';

// Color constants
const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _accentGreen = Color(0xFF4ade80);
const _accentRed = Color(0xFFef4444);
const _accentBlue = Color(0xFF3b82f6);

/// Result screen for online 1v1 matches showing winner/loser
class SudokuOnlineResultScreen extends StatelessWidget {
  const SudokuOnlineResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      body: SafeArea(
        child: Consumer<SudokuOnlineProvider>(
          builder: (context, provider, child) {
            final isWinner = provider.isWinner;
            final match = provider.currentMatch;
            final opponentName = provider.opponentName ?? 'Opponent';

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Result icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isWinner
                            ? _accentGreen.withValues(alpha: 0.15 * 255)
                            : _accentRed.withValues(alpha: 0.15 * 255),
                        border: Border.all(
                          color: isWinner ? _accentGreen : _accentRed,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                        size: 64,
                        color: isWinner ? _accentGreen : _accentRed,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Result title
                    Text(
                      isWinner ? 'VICTORY!' : 'DEFEATED',
                      style: TextStyle(
                        color: isWinner ? _accentGreen : _accentRed,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Result message
                    Text(
                      isWinner
                          ? 'You completed the puzzle first!'
                          : '$opponentName completed the puzzle first',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7 * 255),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Match stats
                    Container(
                      decoration: BoxDecoration(
                        color: _surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWinner
                              ? _accentGreen.withValues(alpha: 0.3 * 255)
                              : _accentRed.withValues(alpha: 0.3 * 255),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _StatRow(
                            label: 'Your Time',
                            value: _formatTime(provider.elapsedSeconds),
                            color: _accentBlue,
                          ),
                          const SizedBox(height: 16),
                          _StatRow(
                            label: 'Mistakes',
                            value: '${provider.mistakes}',
                            color: _accentRed,
                          ),
                          const SizedBox(height: 16),
                          _StatRow(
                            label: 'Completion',
                            value: '${((match?.getPlayer(provider.userId)?.filledCells ?? 0) / 81 * 100).round()}%',
                            color: _accentGreen,
                          ),
                          if (match?.winnerId != null && match?.winnerId != provider.userId) ...[
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withValues(alpha: 0.1 * 255)),
                            const SizedBox(height: 16),
                            _StatRow(
                              label: '$opponentName\'s Time',
                              value: _formatTime((DateTime.now().difference(
                                match!.startedAt ?? match.createdAt
                              )).inSeconds),
                              color: _accentBlue.withValues(alpha: 0.6 * 255),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Go back to mode selection or home
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isWinner ? _accentGreen : _accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'PLAY AGAIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3 * 255),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'BACK TO MENU',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7 * 255),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
