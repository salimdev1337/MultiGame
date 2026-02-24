import 'package:flutter/material.dart';

class Game2048Tile extends StatelessWidget {
  final int value;
  final AnimationController animController;

  const Game2048Tile({
    super.key,
    required this.value,
    required this.animController,
  });

  int _tileFontSize(int v) {
    if (v >= 4096) return 16;
    if (v >= 1024) return 20;
    if (v >= 128) return 24;
    return 28;
  }

  Color _getTileColor(int v) {
    switch (v) {
      case 0:
        return const Color(0xFF101318).withValues(alpha: 0.4);
      case 2:
        return const Color(0xFF2d343f);
      case 4:
        return const Color(0xFF3e4a5b);
      case 8:
        return const Color(0xFF19e6a2);
      case 16:
        return const Color(0xFF14b8a6);
      case 32:
        return const Color(0xFF0ea5e9);
      case 64:
        return const Color(0xFF6366f1);
      case 128:
        return const Color(0xFFa855f7);
      case 256:
        return const Color(0xFFec4899);
      case 512:
        return const Color(0xFFf43f5e);
      case 1024:
        return const Color(0xFFf97316);
      case 2048:
        return const Color(0xFFeab308);
      case 4096:
        return const Color(0xFFe11d48);
      case 8192:
        return const Color(0xFF7c3aed);
      default:
        return const Color(0xFF19e6a2);
    }
  }

  Color _getTextColor(int v) {
    if (v == 0) {
      return Colors.transparent;
    }
    if (v <= 4) {
      return Colors.white.withValues(alpha: 0.9);
    }
    return const Color(0xFF101318);
  }

  @override
  Widget build(BuildContext context) {
    final tileColor = _getTileColor(value);
    final hasGlow = value >= 8 && value != 0;

    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) => Transform.scale(
        scale: value != 0 ? 1.0 - (animController.value * 0.1) : 1.0,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: hasGlow
              ? [
                  BoxShadow(
                    color: tileColor.withValues(alpha: 0.4),
                    blurRadius: value >= 512 ? 20 : 12,
                    spreadRadius: value >= 512 ? 2 : 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: value != 0
              ? Text(
                  '$value',
                  style: TextStyle(
                    fontSize: _tileFontSize(value).toDouble(),
                    fontWeight: FontWeight.w800,
                    color: _getTextColor(value),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
