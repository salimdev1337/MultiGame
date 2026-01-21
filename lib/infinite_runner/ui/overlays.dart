import 'package:flutter/material.dart';
import 'package:multigame/screens/main_navigation.dart';
import '../infinite_runner_game.dart';

/// Overlay shown when game is loading
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF16181d),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'INFINITE RUNNER',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 60),
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00d4ff)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay shown when game is in idle state (before starting)
class IdleOverlay extends StatelessWidget {
  const IdleOverlay({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'INFINITE RUNNER',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF21242b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00d4ff).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  _buildInstruction('^', 'Tap to JUMP'),
                  const SizedBox(height: 12),
                  _buildInstruction('!', 'Avoid obstacles!'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('idle');
                game.startGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00d4ff),
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'TAP TO START',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ],
    );
  }
}

/// HUD showing score during gameplay
class GameHud extends StatefulWidget {
  const GameHud({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> {
  @override
  void initState() {
    super.initState();
    // Rebuild UI periodically to update score
    Future.delayed(const Duration(milliseconds: 100), _updateScore);
  }

  void _updateScore() {
    if (mounted) {
      setState(() {});
      Future.delayed(const Duration(milliseconds: 100), _updateScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pause button
                IconButton(
                  onPressed: () => widget.game.pauseGame(),
                  icon: const Icon(Icons.pause, color: Colors.white, size: 32),
                ),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00d4ff).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${widget.game.score}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00d4ff),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance layout
              ],
            ),
            // FPS Counter (debug)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'FPS: ${widget.game.fps}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay shown when game is paused
class PausedOverlay extends StatelessWidget {
  const PausedOverlay({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF21242b),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00d4ff).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle,
                size: 64,
                color: Color(0xFF00d4ff),
              ),
              const SizedBox(height: 16),
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => game.resumeGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00d4ff),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'RESUME',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay shown when game is over
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = game.score == game.highScore && game.score > 0;

    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF21242b),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNewHighScore
                  ? const Color(0xFFffd700).withValues(alpha: 0.5)
                  : const Color(0xFFff5c00).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                isNewHighScore ? Icons.emoji_events : Icons.close,
                size: 64,
                color: isNewHighScore
                    ? const Color(0xFFffd700)
                    : const Color(0xFFff5c00),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                isNewHighScore ? 'NEW HIGH SCORE!' : 'GAME OVER',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isNewHighScore
                      ? const Color(0xFFffd700)
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Score
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${game.score}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00d4ff),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // High score
              Text(
                'Best: ${game.highScore}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              // Restart button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => game.restart(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00d4ff),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Main menu button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to home tab using MainNavigation's GlobalKey
                    final state = MainNavigation.navigatorKey.currentState;
                    if (state != null) {
                      (state as dynamic).onTabTapped(0);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00d4ff), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'MAIN MENU',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00d4ff),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
