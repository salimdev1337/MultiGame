import 'package:flutter/material.dart';

class RpgActionButtons extends StatelessWidget {
  const RpgActionButtons({
    super.key,
    required this.onAttack,
    required this.onDodge,
    required this.onUltimate,
    this.ultimateReady = false,
  });

  final VoidCallback onAttack;
  final VoidCallback onDodge;
  final VoidCallback onUltimate;
  final bool ultimateReady;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ActionBtn(
          label: 'DODGE',
          sublabel: 'Z',
          color: const Color(0xFF0088CC),
          onTap: onDodge,
        ),
        const SizedBox(width: 8),
        _ActionBtn(
          label: 'ATK',
          sublabel: 'X',
          color: const Color(0xFFCC6600),
          onTap: onAttack,
          size: 76,
        ),
        const SizedBox(width: 8),
        _ActionBtn(
          label: 'ULT',
          sublabel: 'C',
          color: ultimateReady
              ? const Color(0xFF8800CC)
              : const Color(0xFF440066),
          onTap: onUltimate,
          glowing: ultimateReady,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.size = 68,
    this.glowing = false,
  });

  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.85),
          border: Border.all(
            color: glowing
                ? Colors.white.withValues(alpha: 0.9)
                : color.withValues(alpha: 0.6),
            width: glowing ? 2.5 : 1.5,
          ),
          boxShadow: glowing
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
