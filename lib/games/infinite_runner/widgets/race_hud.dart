import 'dart:async';

import 'package:flutter/material.dart';
import '../abilities/ability_type.dart';
import '../infinite_runner_game.dart';

/// Data for a single opponent dot on the progress bar.
class _OpponentDot {
  const _OpponentDot({required this.progress, required this.color});
  final double progress;
  final Color color;
}

/// HUD shown during a race — progress bar, pause button, speed indicator, ability slot
class RaceHud extends StatefulWidget {
  const RaceHud({super.key, required this.game});

  final InfiniteRunnerGame game;

  @override
  State<RaceHud> createState() => _RaceHudState();
}

class _RaceHudState extends State<RaceHud> {
  // Transient notification state
  AbilityType? _toastAbility;
  String? _slowedByText;
  Timer? _toastTimer;
  Timer? _slowedTimer;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();

    _subs.add(
      widget.game.abilityToastStream.listen((type) {
        if (!mounted) return;
        setState(() => _toastAbility = type);
        _toastTimer?.cancel();
        _toastTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _toastAbility = null);
        });
      }),
    );

    _subs.add(
      widget.game.slowedByStream.listen((text) {
        if (!mounted) return;
        setState(() => _slowedByText = text);
        _slowedTimer?.cancel();
        _slowedTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _slowedByText = null);
        });
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _toastTimer?.cancel();
    _slowedTimer?.cancel();
    super.dispose();
  }

  String _formatMs(double ms) {
    final totalSecs = (ms / 1000).floor().clamp(0, 999);
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main HUD content — rebuilds on gameTick (every 50 ms)
        ValueListenableBuilder<int>(
          valueListenable: widget.game.gameTick,
          builder: (context, _, _) => _buildHud(context),
        ),

        // Ability pickup toast (appears for 2 s)
        if (_toastAbility != null) _AbilityToast(ability: _toastAbility!),

        // Slowed-by banner (appears for 3 s)
        if (_slowedByText != null) _SlowedBanner(text: _slowedByText!),
      ],
    );
  }

  Widget _buildHud(BuildContext context) {
    final progress =
        (widget.game.distanceTraveled / InfiniteRunnerGame.trackLength).clamp(
          0.0,
          1.0,
        );
    final isSlowed = widget.game.isPlayerSlowed;
    final isBoosted = widget.game.isPlayerBoosted;
    final hasShield = widget.game.playerHasShield;

    final elapsedMs = widget.game.raceElapsedMs;
    final remainingMs = (InfiniteRunnerGame.raceLimitMs - elapsedMs).clamp(
      0.0,
      double.infinity,
    );

    // Opponent positions for the progress bar (non-local players)
    final room = widget.game.raceRoom;
    final localId = room?.localPlayerId;
    final opponents =
        room?.players
            .where((p) => p.playerId != localId)
            .map(
              (p) => _OpponentDot(
                progress: (p.distance / InfiniteRunnerGame.trackLength).clamp(
                  0.0,
                  1.0,
                ),
                color:
                    InfiniteRunnerGame.playerColors[p.playerId.clamp(
                      0,
                      InfiniteRunnerGame.playerColors.length - 1,
                    )],
              ),
            )
            .toList() ??
        [];

    return Stack(
      children: [
        // ── Top bar: pause + progress + percentage + shield badge ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Pause button
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: () => widget.game.pauseGame(),
                        icon: const Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Progress bar
                    Expanded(
                      child: _ProgressBar(
                        progress: progress,
                        isSlowed: isSlowed,
                        isBoosted: isBoosted,
                        opponents: opponents,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Percentage label
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
                    // Shield badge
                    if (hasShield) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00d4ff).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00d4ff)),
                        ),
                        child: const Text('🛡', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ],
                ),
                // Timer row: elapsed | remaining
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatMs(elapsedMs),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      ' / ',
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                    Text(
                      _formatMs(remainingMs),
                      style: TextStyle(
                        fontSize: 12,
                        color: remainingMs < 30000
                            ? Colors.redAccent
                            : Colors.white54,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      ' left',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
                // Speed status banner
                if (isSlowed || isBoosted) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSlowed
                          ? Colors.red.withValues(alpha: 0.75)
                          : Colors.amber.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSlowed ? '⚠  SLOWED' : '⚡  BOOSTED',
                      style: const TextStyle(
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
        ),

        // ── Bottom-right: ability slot ──
        Positioned(
          right: 16,
          bottom: 32,
          child: _AbilityButton(game: widget.game),
        ),
      ],
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.isSlowed,
    required this.isBoosted,
    this.opponents = const [],
  });

  final double progress;
  final bool isSlowed;
  final bool isBoosted;
  final List<_OpponentDot> opponents;

  @override
  Widget build(BuildContext context) {
    final List<Color> fillColors;
    if (isSlowed) {
      fillColors = [Colors.red.shade700, Colors.deepOrange];
    } else if (isBoosted) {
      fillColors = [Colors.amber, Colors.yellow.shade600];
    } else {
      fillColors = [const Color(0xFF00d4ff), const Color(0xFF7c4dff)];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
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
                // Fill (local player)
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: fillColors),
                    ),
                  ),
                ),
                // Opponent dots
                for (final dot in opponents)
                  Positioned(
                    left: (dot.progress * barWidth - 5).clamp(
                      0.0,
                      barWidth - 10,
                    ),
                    top: 3,
                    child: Container(
                      width: 10,
                      height: 12,
                      decoration: BoxDecoration(
                        color: dot.color,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                // Finish flag
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
      },
    );
  }
}

// ── Ability slot button ───────────────────────────────────────────────────────

class _AbilityButton extends StatelessWidget {
  const _AbilityButton({required this.game});

  final InfiniteRunnerGame game;

  @override
  Widget build(BuildContext context) {
    final ability = game.playerHeldAbility;
    final hasAbility = ability != null;
    final abilityColor = hasAbility ? Color(ability.colorValue) : null;

    return GestureDetector(
      onTap: hasAbility ? () => game.activateAbility() : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasAbility
              ? abilityColor!.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.5),
          border: Border.all(
            color: hasAbility ? abilityColor! : Colors.white24,
            width: 2,
          ),
          boxShadow: hasAbility
              ? [
                  BoxShadow(
                    color: abilityColor!.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: hasAbility
              ? Text(ability.emoji, style: const TextStyle(fontSize: 28))
              : const Icon(
                  Icons.bolt_outlined,
                  color: Colors.white38,
                  size: 28,
                ),
        ),
      ),
    );
  }
}

// ── Ability pickup toast ──────────────────────────────────────────────────────

class _AbilityToast extends StatelessWidget {
  const _AbilityToast({required this.ability});

  final AbilityType ability;

  @override
  Widget build(BuildContext context) {
    final color = Color(ability.colorValue);
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ability.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                ability.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'PICKED UP',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slowed-by banner ──────────────────────────────────────────────────────────

class _SlowedBanner extends StatelessWidget {
  const _SlowedBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade800.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.speed, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
