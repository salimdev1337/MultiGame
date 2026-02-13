import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import '../infinite_runner_game.dart';

/// Animated 3-2-1-GO! countdown shown before the race starts
class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  int _count = 3;
  Timer? _timer;

  static const _accentCyan = Color(0xFF00d4ff);

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _count--;
        _scaleCtrl.reset();
        _scaleCtrl.forward();
      });
      if (_count <= 0) {
        timer.cancel();
        // Small pause so "GO!" is readable before game starts
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.game.beginRacing();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGo = _count <= 0;
    final label = isGo ? 'GO!' : '$_count';
    final color = isGo ? Colors.greenAccent : Colors.white;

    return Material(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 2.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut)),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.w900,
              color: color,
              shadows: [
                Shadow(
                  color: (isGo ? Colors.green : _accentCyan).withValues(
                    alpha: 0.6,
                  ),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the local player crosses the finish line
class RaceFinishOverlay extends StatelessWidget {
  const RaceFinishOverlay({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = game.finishTimeSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF21242b),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.15),
                blurRadius: 50,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 60,
                color: Color(0xFFffd700),
              ),
              const SizedBox(height: 10),
              const Text(
                'FINISH!',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFffd700),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              // Time display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TIME',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00d4ff),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Race again
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => game.restartRace(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00d4ff),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'RACE AGAIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Main menu
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF00d4ff),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'MAIN MENU',
                    style: TextStyle(
                      fontSize: 16,
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
