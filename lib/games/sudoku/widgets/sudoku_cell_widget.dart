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
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(SudokuCellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }
    if (widget.cell.isError && !oldWidget.cell.isError) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String get _semanticLabel {
    final row = widget.row + 1;
    final col = widget.col + 1;
    String content;
    if (widget.cell.hasValue) {
      content =
          'value ${widget.cell.value}${widget.cell.isError ? ", error" : ""}${widget.cell.isFixed ? ", given" : ""}';
    } else if (widget.cell.hasNotes) {
      final notesList = widget.cell.notes.join(', ');
      content = 'notes: $notesList';
    } else {
      content = 'empty';
    }
    final selectedText = widget.isSelected ? ', selected' : '';
    return 'Row $row, Column $col, $content$selectedText';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      hint: 'Double tap to select',
      button: true,
      selected: widget.isSelected,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          ),
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
                          color: _primaryCyan.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : widget.cell.isError
                        ? [
                            BoxShadow(
                              color: _errorRed.withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 0,
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
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.cell.isError) {
      return _errorRed.withValues(alpha: 0.18);
    }
    if (widget.isSelected) {
      return _primaryCyan.withValues(alpha: 0.2);
    }
    if (widget.isHighlighted) {
      // Visible subtle highlight for same row/col/box cells
      return Colors.white.withValues(alpha: 0.06);
    }
    return _surfaceLighter;
  }

  Border? _getBorder() {
    final isRightEdgeOfBox = widget.col % 3 == 2 && widget.col != 8;
    final isBottomEdgeOfBox = widget.row % 3 == 2 && widget.row != 8;

    if (!isRightEdgeOfBox && !isBottomEdgeOfBox) return null;

    return Border(
      right: isRightEdgeOfBox
          ? BorderSide(
              color: _primaryCyan.withValues(alpha: 0.6),
              width: 2,
            )
          : BorderSide.none,
      bottom: isBottomEdgeOfBox
          ? BorderSide(
              color: _primaryCyan.withValues(alpha: 0.6),
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
        color: hasError ? _errorRed : isGiven ? _textWhite : _primaryCyan,
        shadows: !isGiven && !hasError
            ? [
                Shadow(
                  color: _primaryCyan.withValues(alpha: 0.5),
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
