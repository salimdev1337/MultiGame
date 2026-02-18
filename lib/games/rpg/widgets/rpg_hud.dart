import 'package:flutter/material.dart';
import 'package:multigame/games/rpg/game/rpg_flame_game.dart';

class RpgHud extends StatelessWidget {
  const RpgHud({super.key, required this.game});
  final RpgFlameGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.gameTick,
      builder: (context, tick, child) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _HpBar(
                    label: 'YOU',
                    hp: game.playerHp,
                    maxHp: game.playerMaxHp,
                    color: _playerHpColor(game.playerHp, game.playerMaxHp),
                  ),
                  const Spacer(),
                  _HpBar(
                    label: _bossLabel(game),
                    hp: game.bossHp,
                    maxHp: game.bossMaxHp,
                    color: const Color(0xFFCC2200),
                    reversed: true,
                  ),
                ],
              ),
              if (game.bossPhase > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xAACC0000),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ENRAGED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _playerHpColor(int hp, int maxHp) {
    final ratio = hp / maxHp;
    if (ratio > 0.5) {
      return const Color(0xFF19e6a2);
    }
    if (ratio > 0.25) {
      return const Color(0xFFffa502);
    }
    return const Color(0xFFff4757);
  }

  String _bossLabel(RpgFlameGame game) {
    return game.bossId == game.bossId ? 'BOSS' : 'BOSS';
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.label,
    required this.hp,
    required this.maxHp,
    required this.color,
    this.reversed = false,
  });

  final String label;
  final int hp;
  final int maxHp;
  final Color color;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final ratio = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment:
            reversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: const Color(0x88000000)),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    alignment: reversed ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$hp / $maxHp',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
