import 'package:flutter/material.dart';
import '../abilities/ability_type.dart';
import '../infinite_runner_game.dart';

/// HUD shown during a race — progress bar, pause button, speed indicator, ability slot
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
    final isBoosted = widget.game.isPlayerBoosted;
    final hasShield = widget.game.playerHasShield;

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
                          border: Border.all(
                            color: const Color(0xFF00d4ff),
                          ),
                        ),
                        child: const Text(
                          '🛡',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
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
  });

  final double progress;
  final bool isSlowed;
  final bool isBoosted;

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
                  gradient: LinearGradient(colors: fillColors),
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
              ? Text(
                  ability.emoji,
                  style: const TextStyle(fontSize: 28),
                )
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
