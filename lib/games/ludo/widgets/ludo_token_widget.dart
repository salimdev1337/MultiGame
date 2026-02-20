import 'package:flutter/material.dart';

import '../models/ludo_enums.dart';
import '../models/ludo_token.dart';

// ── Player colours ────────────────────────────────────────────────────────

Color _tokenColor(LudoPlayerColor c) {
  switch (c) {
    case LudoPlayerColor.red:
      return const Color(0xFFE53935);
    case LudoPlayerColor.blue:
      return const Color(0xFF2196F3);
    case LudoPlayerColor.green:
      return const Color(0xFF43A047);
    case LudoPlayerColor.yellow:
      return const Color(0xFFFFD700);
  }
}

/// A single Ludo token rendered as an animated positioned widget on the board.
///
/// The parent [Stack] must have the same coordinate system as the board painter
/// (cell size = boardSize / 15).
class LudoTokenWidget extends StatefulWidget {
  const LudoTokenWidget({
    super.key,
    required this.token,
    required this.cellSize,
    required this.col,
    required this.row,
    required this.isSelected,
    required this.isMovable,
    this.onTap,
  });

  final LudoToken token;
  final double cellSize;
  final int col;
  final int row;
  final bool isSelected;
  final bool isMovable;
  final VoidCallback? onTap;

  @override
  State<LudoTokenWidget> createState() => _LudoTokenWidgetState();
}

class _LudoTokenWidgetState extends State<LudoTokenWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.cellSize * 0.72;
    final left = widget.col * widget.cellSize + (widget.cellSize - size) / 2;
    final top = widget.row * widget.cellSize + (widget.cellSize - size) / 2;

    final color = _tokenColor(widget.token.owner);
    final shielded = widget.token.shieldTurnsLeft > 0;
    final frozen = widget.token.isFrozen;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      left: left,
      top: top,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: widget.isMovable ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final scale = widget.isSelected ? _pulse.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: _TokenBody(
            color: color,
            size: size,
            isSelected: widget.isSelected,
            isMovable: widget.isMovable,
            shielded: shielded,
            frozen: frozen,
          ),
        ),
      ),
    );
  }
}

class _TokenBody extends StatelessWidget {
  const _TokenBody({
    required this.color,
    required this.size,
    required this.isSelected,
    required this.isMovable,
    required this.shielded,
    required this.frozen,
  });

  final Color color;
  final double size;
  final bool isSelected;
  final bool isMovable;
  final bool shielded;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: isSelected
              ? Colors.white
              : shielded
                  ? const Color(0xFF80DEEA)
                  : Colors.black26,
          width: shielded ? 2.5 : (isSelected ? 2.0 : 1.0),
        ),
        boxShadow: [
          if (isMovable)
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          if (shielded)
            BoxShadow(
              color: const Color(0xFF80DEEA).withValues(alpha: 0.7),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
          ],
        ),
      ),
      child: frozen
          ? const Icon(
              Icons.ac_unit_rounded,
              color: Colors.white,
              size: 14,
            )
          : null,
    );
  }
}
