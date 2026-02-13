import 'package:flutter/material.dart';
import '../infinite_runner_game.dart';

/// HUD shown during a race — progress bar, pause button, slowdown indicator
class RaceHud extends StatefulWidget {
  const RaceHud({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  State<RaceHud> createState() => _RaceHudState();
}

class _RaceHudState extends State<RaceHud> {
  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    if (mounted) {
      setState(() {});
      Future.delayed(const Duration(milliseconds: 50), _tick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (widget.game.distanceTraveled / InfiniteRunnerGame.trackLength).clamp(
          0.0,
          1.0,
        );
    final isSlowed = widget.game.isPlayerSlowed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Pause
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    onPressed: () => widget.game.pauseGame(),
                    icon: const Icon(Icons.pause, color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Progress bar
                Expanded(child: _ProgressBar(progress: progress, isSlowed: isSlowed)),
                const SizedBox(width: 8),
                // Percentage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00d4ff).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${(progress * 100).floor()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00d4ff),
                    ),
                  ),
                ),
              ],
            ),
            // Slowdown warning
            if (isSlowed) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠  SLOWED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.isSlowed});

  final double progress;
  final bool isSlowed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Fill
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isSlowed
                            ? [Colors.red.shade700, Colors.deepOrange]
                            : [
                              const Color(0xFF00d4ff),
                              const Color(0xFF7c4dff),
                            ],
                  ),
                ),
              ),
            ),
            // Finish flag at the right end
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(
                  Icons.flag,
                  size: 12,
                  color: Colors.yellow.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
