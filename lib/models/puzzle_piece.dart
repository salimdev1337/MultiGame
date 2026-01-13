class PuzzlePiece {
  final int? number;
  final String? imageUrl;
  final int correctPosition;
  int currentPosition;
  final int gridSize;

  PuzzlePiece({
    required this.number,
    required this.imageUrl,
    required this.correctPosition,
    required this.currentPosition,
    required this.gridSize,
  });

  bool get isCorrect => currentPosition == correctPosition;
  bool get isEmpty => number == null;

  int get correctRow => correctPosition ~/ gridSize;
  int get correctCol => correctPosition % gridSize;

  int get currentRow => currentPosition ~/ gridSize;
  int get currentCol => currentPosition % gridSize;

  double get alignmentX {
    if (gridSize == 1) return 0;
    // Convert column to -1.0 to 1.0 range
    return -1.0 + (2.0 * correctCol / (gridSize - 1));
  }

  double get alignmentY {
    if (gridSize == 1) return 0;
    // Convert row to -1.0 to 1.0 range
    return -1.0 + (2.0 * correctRow / (gridSize - 1));
  }
}
