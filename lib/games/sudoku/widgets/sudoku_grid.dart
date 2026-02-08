// Sudoku grid widget - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import '../models/sudoku_board.dart';
import 'sudoku_cell_widget.dart';

const _primaryCyan = Color(0xFF00d4ff);
const _surfaceDark = Color(0xFF1a1d24);

class SudokuGrid extends StatelessWidget {
  final SudokuBoard board;

  final int? selectedRow;

  final int? selectedCol;

  final Function(int row, int col) onCellTap;

  final int? selectedCellValue;

  const SudokuGrid({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    this.selectedCellValue,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _primaryCyan.withValues(alpha: 0.3 * 255),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryCyan.withValues(alpha: 0.2 * 255),
              blurRadius: 15,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final row = index ~/ 9;
              final col = index % 9;
              final cell = board.getCell(row, col);
              final isSelected = selectedRow == row && selectedCol == col;
              final isHighlighted = _shouldHighlight(cell.value, row, col);

              return SudokuCellWidget(
                cell: cell,
                row: row,
                col: col,
                isSelected: isSelected,
                isHighlighted: isHighlighted,
                onTap: () => onCellTap(row, col),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _shouldHighlight(int? cellValue, int row, int col) {
    if (selectedRow == null || selectedCol == null) {
      return false;
    }

    if (row == selectedRow && col == selectedCol) {
      return false;
    }

    final sameRow = row == selectedRow;
    final sameCol = col == selectedCol;
    final sameBox =
        (row ~/ 3 == selectedRow! ~/ 3) && (col ~/ 3 == selectedCol! ~/ 3);

    if (sameRow || sameCol || sameBox) {
      return true;
    }

    if (selectedCellValue != null &&
        cellValue != null &&
        cellValue == selectedCellValue) {
      return true;
    }

    return false;
  }
}
