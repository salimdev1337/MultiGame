import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

class ShimmerTrophyIcon extends StatefulWidget {
  final int rank;
  final double size;

  const ShimmerTrophyIcon({
    super.key,
    required this.rank,
    this.size = 40,
  });

  @override
  State<ShimmerTrophyIcon> createState() => _ShimmerTrophyIconState();
}

class _ShimmerTrophyIconState extends State<ShimmerTrophyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getTrophyColor() {
    switch (widget.rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return DSColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              colors: [
                _getTrophyColor().withValues(alpha: 0.6),
                Colors.white,
                _getTrophyColor().withValues(alpha: 0.6),
              ],
            ).createShader(bounds);
          },
          child: Icon(
            Icons.emoji_events,
            size: widget.size,
            color: _getTrophyColor(),
          ),
        );
      },
    );
  }
}
