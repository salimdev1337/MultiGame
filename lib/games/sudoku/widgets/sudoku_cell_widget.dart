// Sudoku cell widget - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import '../models/sudoku_cell.dart';

const _primaryCyan = Color(0xFF00d4ff);
const _surfaceLighter = Color(0xFF2a2e36);
const _errorRed = Color(0xFFff6b6b);
const _textWhite = Color(0xFFffffff);
const _textGray = Color(0xFF94a3b8);

class SudokuCellWidget extends StatefulWidget {
  final SudokuCell cell;

  final int row;

  final int col;

  final bool isSelected;

  final bool isHighlighted;

  final bool isAnimating;

  final VoidCallback onTap;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.row,
    required this.col,
    required this.isSelected,
    this.isHighlighted = false,
    this.isAnimating = false,
    required this.onTap,
  });

  @override
  State<SudokuCellWidget> createState() => _SudokuCellWidgetState();
}

class _SudokuCellWidgetState extends State<SudokuCellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(SudokuCellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: _getBorder(),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: _primaryCyan.withValues(alpha: 0.4 * 255),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.cell.hasValue
                ? _buildValueText()
                : widget.cell.hasNotes
                ? _buildNotesGrid()
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.cell.isError) {
      return _errorRed.withValues(alpha: 0.15 * 255);
    }
    if (widget.isSelected) {
      return _primaryCyan.withValues(alpha: 0.2 * 255);
    }
    if (widget.isHighlighted) {
      return Colors.white.withValues(alpha: 0.001 * 255);
    }
    return _surfaceLighter;
  }

  Border? _getBorder() {
    final isRightEdgeOfBox = widget.col % 3 == 2 && widget.col != 8;
    final isBottomEdgeOfBox = widget.row % 3 == 2 && widget.row != 8;

    if (!isRightEdgeOfBox && !isBottomEdgeOfBox) {
      return null;
    }

    return Border(
      right: isRightEdgeOfBox
          ? BorderSide(
              color: _primaryCyan.withValues(alpha: 0.6 * 255),
              width: 2,
            )
          : BorderSide.none,
      bottom: isBottomEdgeOfBox
          ? BorderSide(
              color: _primaryCyan.withValues(alpha: 0.6 * 255),
              width: 2,
            )
          : BorderSide.none,
    );
  }

  Widget _buildValueText() {
    final value = widget.cell.value.toString();
    final isGiven = widget.cell.isFixed;
    final hasError = widget.cell.isError;

    return Text(
      value,
      style: TextStyle(
        fontSize: 24,
        fontWeight: isGiven ? FontWeight.w700 : FontWeight.w500,
        color: hasError
            ? _errorRed
            : isGiven
            ? _textWhite
            : _primaryCyan,
        shadows: !isGiven && !hasError
            ? [
                Shadow(
                  color: _primaryCyan.withValues(alpha: 0.5 * 255),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildNotesGrid() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final number = index + 1;
          final hasNote = widget.cell.notes.contains(number);

          return Center(
            child: Text(
              hasNote ? number.toString() : '',
              style: const TextStyle(
                fontSize: 10,
                color: _textGray,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}
