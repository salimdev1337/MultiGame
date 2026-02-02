import 'package:flutter/material.dart';
import '../logic/sudoku_generator.dart';
import 'sudoku_classic_screen.dart';
import 'sudoku_rush_screen.dart';
import 'mode_selection_screen.dart';

// Color constants
const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);

/// Difficulty selection screen for Sudoku.
///
/// Allows players to choose from:
/// - Easy (green): 36-40 clues, perfect for beginners
/// - Medium (yellow): 30-35 clues, intermediate
/// - Hard (orange): 25-29 clues, advanced
/// - Expert (red): 20-24 clues, masters
///
/// Routes to the appropriate game screen based on selected mode.
class DifficultySelectionScreen extends StatelessWidget {
  final GameMode mode;

  const DifficultySelectionScreen({
    super.key,
    this.mode = GameMode.classic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'SELECT DIFFICULTY',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
            Text(
              mode == GameMode.classic ? 'Classic Mode' : 'Rush Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6 * 255),
              ),
            ),
          ],
        ),
        backgroundColor: _surfaceDark,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            _DifficultyCard(
              difficulty: SudokuDifficulty.easy,
              name: 'Easy',
              description: '36-40 clues • Perfect for beginners',
              icon: Icons.sentiment_satisfied,
              color: const Color(0xFF4ade80), // Green
              onTap: () => _startGame(context, SudokuDifficulty.easy),
            ),
            const SizedBox(height: 16),
            _DifficultyCard(
              difficulty: SudokuDifficulty.medium,
              name: 'Medium',
              description: '30-35 clues • Intermediate challenge',
              icon: Icons.sentiment_neutral,
              color: const Color(0xFFfbbf24), // Yellow
              onTap: () => _startGame(context, SudokuDifficulty.medium),
            ),
            const SizedBox(height: 16),
            _DifficultyCard(
              difficulty: SudokuDifficulty.hard,
              name: 'Hard',
              description: '25-29 clues • Advanced strategies',
              icon: Icons.sentiment_dissatisfied,
              color: const Color(0xFFfb923c), // Orange
              onTap: () => _startGame(context, SudokuDifficulty.hard),
            ),
            const SizedBox(height: 16),
            _DifficultyCard(
              difficulty: SudokuDifficulty.expert,
              name: 'Expert',
              description: '20-24 clues • Master level',
              icon: Icons.whatshot,
              color: const Color(0xFFef4444), // Red
              onTap: () => _startGame(context, SudokuDifficulty.expert),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to the game screen with the selected difficulty
  void _startGame(BuildContext context, SudokuDifficulty difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => mode == GameMode.classic
            ? SudokuClassicScreen(difficulty: difficulty)
            : SudokuRushScreen(difficulty: difficulty),
      ),
    );
  }
}

/// Individual difficulty selection card
class _DifficultyCard extends StatelessWidget {
  final SudokuDifficulty difficulty;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.5 * 255),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2 * 255),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15 * 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7 * 255),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: color.withValues(alpha: 0.5 * 255),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
