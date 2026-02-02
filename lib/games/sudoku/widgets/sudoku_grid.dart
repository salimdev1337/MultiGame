import 'package:flutter/material.dart';
import '../models/sudoku_board.dart';
import 'sudoku_cell_widget.dart';

// Color constants matching the HTML design
const _primaryCyan = Color(0xFF00d4ff);
const _surfaceDark = Color(0xFF1a1d24);

/// Renders the complete 9x9 Sudoku grid.
///
/// Design specifications from HTML:
/// - Dark background (#1a1d24)
/// - Thick cyan borders (#00d4ff, 2px) between 3×3 blocks
/// - Thin dark borders (1px) between individual cells
/// - Rounded corners (16px)
/// - Aspect ratio 1:1 (square)
/// - Responsive sizing
///
/// The grid uses GridView.builder with 81 items (9×9),
/// where each item is a SudokuCellWidget.
class SudokuGrid extends StatelessWidget {
  /// The Sudoku board to display
  final SudokuBoard board;

  /// Currently selected row (0-8), null if none
  final int? selectedRow;

  /// Currently selected column (0-8), null if none
  final int? selectedCol;

  /// Callback when a cell is tapped
  final Function(int row, int col) onCellTap;

  /// Value of the selected cell (for highlighting matching numbers)
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

  /// Determines if a cell should be highlighted
  ///
  /// Highlights cells that:
  /// - Are in the same row as selected cell
  /// - Are in the same column as selected cell
  /// - Are in the same 3x3 box as selected cell
  /// - Have the same number as selected cell (if selected has a value)
  bool _shouldHighlight(int? cellValue, int row, int col) {
    // No selection, no highlight
    if (selectedRow == null || selectedCol == null) {
      return false;
    }

    // Don't highlight the selected cell itself
    if (row == selectedRow && col == selectedCol) {
      return false;
    }

    // Highlight same row, column, or box
    final sameRow = row == selectedRow;
    final sameCol = col == selectedCol;
    final sameBox = (row ~/ 3 == selectedRow! ~/ 3) &&
        (col ~/ 3 == selectedCol! ~/ 3);

    if (sameRow || sameCol || sameBox) {
      return true;
    }

    // Highlight cells with same number as selected cell
    if (selectedCellValue != null &&
        cellValue != null &&
        cellValue == selectedCellValue) {
      return true;
    }

    return false;
  }
}
