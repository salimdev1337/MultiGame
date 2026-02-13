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

// ── Colours per player slot ───────────────────────────────────────────────────

const _kPlayerColors = [
  Color(0xFF00d4ff), // 0 = host (cyan)
  Color(0xFFffd700), // 1 = gold
  Color(0xFF7c4dff), // 2 = purple
  Color(0xFFff6b35), // 3 = orange
];

const _kPlaceMedals = ['🥇', '🥈', '🥉', '4️⃣'];

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatMs(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

// ── Finish overlay (solo & multiplayer) ──────────────────────────────────────

/// Shown when the local player crosses the finish line.
/// Solo: simple time card.  Multiplayer: full podium with all players.
class RaceFinishOverlay extends StatelessWidget {
  const RaceFinishOverlay({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    final isMultiplayer = game.raceRoom != null && game.raceRoom!.players.length > 1;
    return isMultiplayer ? _MultiplayerFinish(game: game) : _SoloFinish(game: game);
  }
}

// ── Solo finish ───────────────────────────────────────────────────────────────

class _SoloFinish extends StatelessWidget {
  const _SoloFinish({required this.game});
  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatMs(game.finishTimeSeconds * 1000);

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
              const Icon(Icons.emoji_events, size: 60, color: Color(0xFFffd700)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00d4ff), width: 2),
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

// ── Multiplayer podium ────────────────────────────────────────────────────────

class _MultiplayerFinish extends StatelessWidget {
  const _MultiplayerFinish({required this.game});
  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    final rankings = game.raceLeaderboard;
    final localId = game.raceRoom!.localPlayerId;
    final localRank = rankings.indexWhere((p) => p.playerId == localId);
    final isWinner = localRank == 0;

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF21242b),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWinner
                    ? const Color(0xFFffd700).withValues(alpha: 0.7)
                    : const Color(0xFF00d4ff).withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isWinner ? const Color(0xFFffd700) : const Color(0xFF00d4ff))
                      .withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  isWinner ? '🏆  WINNER!' : 'RACE OVER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isWinner ? const Color(0xFFffd700) : Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 20),

                // Rankings
                ...rankings.asMap().entries.map((entry) {
                  final rank = entry.key;
                  final player = entry.value;
                  final isLocal = player.playerId == localId;
                  final color = _kPlayerColors[player.playerId.clamp(0, 3)];
                  final medal = rank < 4 ? _kPlaceMedals[rank] : '${rank + 1}.';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isLocal
                          ? color.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: isLocal
                          ? Border.all(color: color.withValues(alpha: 0.6), width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Medal / rank
                        SizedBox(
                          width: 36,
                          child: Text(
                            medal,
                            style: const TextStyle(fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.8),
                          child: Text(
                            player.displayName.isNotEmpty
                                ? player.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.displayName +
                                    (isLocal ? ' (you)' : ''),
                                style: TextStyle(
                                  color: isLocal ? color : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!player.isFinished)
                                Text(
                                  '${(player.progress * 100).floor()}% complete',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Time / DNF
                        if (player.isFinished)
                          Text(
                            _formatMs(player.finishTimeMs),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00d4ff),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DNF',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Buttons
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00d4ff), width: 2),
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
      ),
    );
  }
}

// ── Host-disconnected overlay ─────────────────────────────────────────────────

/// Shown to guests when the host drops during a race.
class HostLeftOverlay extends StatelessWidget {
  const HostLeftOverlay({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF21242b),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.shade700.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: Colors.red.shade400),
              const SizedBox(height: 14),
              const Text(
                'Host Disconnected',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The host left the race.\nYour progress has been saved.',
                style: TextStyle(color: Colors.white54, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00d4ff),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'BACK TO HOME',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
