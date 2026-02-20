import 'package:flutter/material.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class RpgActionButtons extends StatelessWidget {
  const RpgActionButtons({
    super.key,
    required this.unlockedAbilities,
    required this.onAttack,
    required this.onFireball,
    required this.onTimeSlow,
    required this.onDodge,
    this.fireballCooldownPct = 0,
    this.timeSlowCooldownPct = 0,
  });

  final List<AbilityType> unlockedAbilities;
  final VoidCallback onAttack;
  final VoidCallback onFireball;
  final VoidCallback onTimeSlow;
  final VoidCallback onDodge;
  final double fireballCooldownPct;
  final double timeSlowCooldownPct;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          label: 'D',
          sublabel: 'Z',
          color: const Color(0xFFAAFFCC),
          onTap: onDodge,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          label: 'A',
          sublabel: 'X',
          color: const Color(0xFFFFD700),
          onTap: onAttack,
        ),
        const SizedBox(width: 8),
        if (unlockedAbilities.contains(AbilityType.fireball))
          _ActionButton(
            label: 'F',
            sublabel: 'C',
            color: const Color(0xFFFF4400),
            onTap: onFireball,
            cooldownPct: fireballCooldownPct,
          ),
        if (unlockedAbilities.contains(AbilityType.fireball))
          const SizedBox(width: 8),
        if (unlockedAbilities.contains(AbilityType.timeSlow))
          _ActionButton(
            label: 'T',
            sublabel: 'V',
            color: const Color(0xFF00AAFF),
            onTap: onTimeSlow,
            cooldownPct: timeSlowCooldownPct,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.sublabel,
    this.cooldownPct = 0,
  });

  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;
  final double cooldownPct;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.25),
                border: Border.all(color: color, width: 2),
              ),
            ),
            if (cooldownPct > 0)
              CircularProgressIndicator(
                value: cooldownPct,
                strokeWidth: 3,
                color: Colors.white.withValues(alpha: 0.5),
                backgroundColor: Colors.transparent,
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.55),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
