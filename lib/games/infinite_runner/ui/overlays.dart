import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import '../infinite_runner_game.dart';
import '../screens/race_lobby_screen.dart';

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
                  _buildInstruction(
                    const _BouncingIcon(
                      icon: Icons.keyboard_arrow_up_rounded,
                      direction: -1,
                    ),
                    'Swipe UP to jump',
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(
                    const _BouncingIcon(
                      icon: Icons.keyboard_arrow_down_rounded,
                      direction: 1,
                    ),
                    'Swipe DOWN to slide',
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(
                    const _PulsingWarning(),
                    'Avoid obstacles!',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Solo run
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
                'SOLO RUN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Race mode row — HOST RACE only available on native (dart:io required)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!kIsWeb) ...[
                  _RaceButton(
                    label: 'HOST RACE',
                    icon: Icons.wifi_tethering,
                    color: const Color(0xFFffd700),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RaceLobbyScreen(isHost: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                _RaceButton(
                  label: 'JOIN RACE',
                  icon: Icons.group,
                  color: const Color(0xFF7c4dff),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RaceLobbyScreen(isHost: false),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(Widget icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ],
    );
  }
}

// ── Animated gesture indicator widgets ────────────────────────────────────────

/// Arrow icon that bounces vertically (direction: -1 = up, 1 = down).
class _BouncingIcon extends StatefulWidget {
  const _BouncingIcon({required this.icon, required this.direction});
  final IconData icon;
  final double direction; // -1 = up, 1 = down

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _offset.value * widget.direction),
        child: Icon(
          widget.icon,
          size: 26,
          color: const Color(0xFF00d4ff),
        ),
      ),
    );
  }
}

/// Warning icon that pulses in opacity.
class _PulsingWarning extends StatefulWidget {
  const _PulsingWarning();

  @override
  State<_PulsingWarning> createState() => _PulsingWarningState();
}

class _PulsingWarningState extends State<_PulsingWarning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Icon(
        Icons.warning_amber_rounded,
        size: 26,
        color: Colors.amber.withValues(alpha: _opacity.value),
      ),
    );
  }
}

/// HUD showing score during gameplay
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.gameTick,
      builder: (context, _, _) {
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
                      onPressed: () => game.pauseGame(),
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
                        '${game.score}',
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
              ],
            ),
          ),
        );
      },
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
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'QUIT TO MENU',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
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
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Scale down sizes for landscape
    final iconSize = isLandscape ? 40.0 : 56.0;
    final titleSize = isLandscape ? 20.0 : 24.0;
    final scoreSize = isLandscape ? 32.0 : 40.0;
    final buttonTextSize = isLandscape ? 14.0 : 16.0;
    final containerPadding = isLandscape ? 16.0 : 24.0;
    final spacing = isLandscape ? 8.0 : 12.0;
    final buttonPadding = isLandscape ? 10.0 : 14.0;

    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: isLandscape ? 320 : 360),
            margin: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isLandscape ? 8 : 16,
            ),
            padding: EdgeInsets.all(containerPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF21242b),
              borderRadius: BorderRadius.circular(16),
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
                  size: iconSize,
                  color: isNewHighScore
                      ? const Color(0xFFffd700)
                      : const Color(0xFFff5c00),
                ),
                SizedBox(height: spacing),
                // Title
                Text(
                  isNewHighScore ? 'NEW HIGH SCORE!' : 'GAME OVER',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: isNewHighScore
                        ? const Color(0xFFffd700)
                        : Colors.white,
                  ),
                ),
                SizedBox(height: spacing * 1.5),
                // Score
                Container(
                  padding: EdgeInsets.all(spacing * 1.2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontSize: isLandscape ? 10 : 12,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        '${game.score}',
                        style: TextStyle(
                          fontSize: scoreSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00d4ff),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                // High score
                Text(
                  'Best: ${game.highScore}',
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: spacing),
                // Run stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      icon: Icons.timer_outlined,
                      label: _formatRunTime(game.runTimeSeconds),
                    ),
                    SizedBox(width: spacing),
                    _StatChip(
                      icon: Icons.directions_run,
                      label: '${game.obstaclesDodged} dodged',
                    ),
                  ],
                ),
                SizedBox(height: spacing * 2),
                // Restart button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => game.restart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00d4ff),
                      padding: EdgeInsets.symmetric(vertical: buttonPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'PLAY AGAIN',
                      style: TextStyle(
                        fontSize: buttonTextSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                // Main menu button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF00d4ff),
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: buttonPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'MAIN MENU',
                      style: TextStyle(
                        fontSize: buttonTextSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00d4ff),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatRunTime(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ── Small stat chip ───────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00d4ff)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ── Small race-mode button ────────────────────────────────────────────────────

class _RaceButton extends StatelessWidget {
  const _RaceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
