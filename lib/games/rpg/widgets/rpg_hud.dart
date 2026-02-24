import 'package:flutter/material.dart';
import 'package:multigame/games/rpg/game/rpg_flame_game.dart';

class RpgHud extends StatelessWidget {
  const RpgHud({super.key, required this.game});
  final RpgFlameGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.gameTick,
      builder: (_, value, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlayerPanel(game: game),
                const Spacer(),
                _BossPanel(game: game),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({required this.game});
  final RpgFlameGame game;

  @override
  Widget build(BuildContext context) {
    final hp = game.playerHp;
    final maxHp = game.playerMaxHp;
    final ratio = maxHp > 0 ? hp / maxHp : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HpBar(
          ratio: ratio.clamp(0.0, 1.0),
          width: 140,
          color: ratio > 0.5
              ? const Color(0xFF44DD44)
              : ratio > 0.25
                  ? const Color(0xFFDDAA00)
                  : const Color(0xFFCC2200),
          label: '$hp / $maxHp',
        ),
        const SizedBox(height: 6),
        // Stamina pips
        Row(
          children: List.generate(
            game.maxStaminaPips,
            (i) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < game.staminaPips
                      ? const Color(0xFF00AAFF)
                      : const Color(0xFF334455),
                  border: Border.all(
                    color: const Color(0xFF88AACC),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Ultimate gauge
        _UltimateBar(
          charge: game.ultimateCharge,
          width: 140,
        ),
      ],
    );
  }
}

class _BossPanel extends StatelessWidget {
  const _BossPanel({required this.game});
  final RpgFlameGame game;

  @override
  Widget build(BuildContext context) {
    final hp = game.bossHp;
    final maxHp = game.bossMaxHp;
    final ratio = maxHp > 0 ? hp / maxHp : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HpBar(
          ratio: ratio.clamp(0.0, 1.0),
          width: 140,
          color: const Color(0xFFCC2200),
          label: '$hp / $maxHp',
          reversed: true,
        ),
        if (game.bossPhase > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFCC0000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              game.bossPhase >= 2 ? 'DESPERATION' : 'ENRAGED',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.ratio,
    required this.width,
    required this.color,
    required this.label,
    this.reversed = false,
  });

  final double ratio;
  final double width;
  final Color color;
  final String label;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final bar = Stack(
      children: [
        Container(
          width: width,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: width * ratio,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );

    if (reversed) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.14159),
        child: bar,
      );
    }
    return bar;
  }
}

class _UltimateBar extends StatelessWidget {
  const _UltimateBar({required this.charge, required this.width});
  final double charge;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isReady = charge >= 1.0;
    return Stack(
      children: [
        Container(
          width: width,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: width * charge.clamp(0.0, 1.0),
          height: 8,
          decoration: BoxDecoration(
            color: isReady
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF8844CC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (isReady)
          Positioned.fill(
            child: Center(
              child: Text(
                'ULTIMATE',
                style: TextStyle(
                  color: Colors.purple.shade100,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
