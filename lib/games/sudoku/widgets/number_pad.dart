// Number pad widget - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import '../models/sudoku_board.dart';

const _primaryCyan = Color(0xFF00d4ff);
const _surfaceDark = Color(0xFF2a2e36);
const _surfaceLighter = Color(0xFF3a3e46);
const _textGray = Color(0xFF64748b);

class NumberPad extends StatelessWidget {
  final SudokuBoard board;

  final Function(int number) onNumberTap;

  final bool useCompactMode;

  const NumberPad({
    super.key,
    required this.board,
    required this.onNumberTap,
    this.useCompactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: useCompactMode ? 8 : 16,
        vertical: useCompactMode ? 6 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          final number = index + 1;
          final remaining = _calculateRemaining(number);
          final isDisabled = remaining == 0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: useCompactMode ? 2 : 4),
              child: _NumberButton(
                number: number,
                remaining: remaining,
                isDisabled: isDisabled,
                onTap: () => onNumberTap(number),
                isCompact: useCompactMode,
              ),
            ),
          );
        }),
      ),
    );
  }

  int _calculateRemaining(int number) {
    int count = 0;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cell = board.getCell(row, col);
        if (cell.value == number) {
          count++;
        }
      }
    }
    return 9 - count;
  }
}

class _NumberButton extends StatefulWidget {
  final int number;
  final int remaining;
  final bool isDisabled;
  final VoidCallback onTap;
  final bool isCompact;

  const _NumberButton({
    required this.number,
    required this.remaining,
    required this.isDisabled,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  State<_NumberButton> createState() => _NumberButtonState();
}

class _NumberButtonState extends State<_NumberButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDisabled
        ? _textGray.withValues(alpha: 0.3 * 255)
        : _primaryCyan;

    final badgeColor = widget.isDisabled
        ? _textGray.withValues(alpha: 0.5 * 255)
        : _textGray;

    final fontSize = widget.isCompact ? 16.0 : 24.0;
    final badgeFontSize = widget.isCompact ? 8.0 : 10.0;
    final borderRadius = widget.isCompact ? 8.0 : 12.0;
    final borderWidth = widget.isCompact ? 2.0 : 4.0;
    final badgeTop = widget.isCompact ? 2.0 : 4.0;
    final badgeRight = widget.isCompact ? 4.0 : 8.0;

    return Semantics(
      label: 'Number ${widget.number}, ${widget.remaining} remaining',
      hint: widget.isDisabled
          ? 'All ${widget.number}s placed'
          : 'Double tap to enter',
      button: true,
      enabled: !widget.isDisabled,
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => _setPressed(true),
        onTapUp: widget.isDisabled
            ? null
            : (_) {
                _setPressed(false);
                widget.onTap();
              },
        onTapCancel: widget.isDisabled ? null : () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? _surfaceDark.withValues(alpha: 0.5 * 255)
                : _surfaceDark,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border(
              bottom: BorderSide(
                color: _surfaceLighter,
                width: _isPressed ? 0 : borderWidth,
              ),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.number.toString(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              Positioned(
                top: badgeTop,
                right: badgeRight,
                child: Text(
                  widget.remaining.toString(),
                  style: TextStyle(
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (mounted) {
      setState(() {
        _isPressed = pressed;
      });
    }
  }
}
