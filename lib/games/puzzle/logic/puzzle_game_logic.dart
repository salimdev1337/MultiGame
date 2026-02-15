import '../models/puzzle_piece.dart';
import '../services/image_puzzle_generator.dart';

class PuzzleGame {
  List<PuzzlePiece> pieces = [];
  int emptyPosition;
  final int gridSize;
  final int totalPieces;
  final ImagePuzzleGenerator puzzleGenerator;

  PuzzleGame({required this.gridSize, String? initialImageUrl})
    : totalPieces = gridSize * gridSize,
      emptyPosition = gridSize * gridSize - 1,
      puzzleGenerator = ImagePuzzleGenerator(
        gridSize: gridSize,
        initialImageUrl: initialImageUrl,
      ) {
    _initializeEmptyPuzzle();
  }

  /// The URL of the image currently used by this puzzle (may be null before
  /// [loadPuzzleImages] has been called).
  String? get currentImageUrl => puzzleGenerator.currentImageUrl;

  void _initializeEmptyPuzzle() {
    pieces = List.generate(totalPieces, (index) {
      return PuzzlePiece(
        number: index == totalPieces - 1 ? null : index + 1,
        imageUrl: null,
        correctPosition: index,
        currentPosition: index,
        gridSize: gridSize,
      );
    });
  }

  Future<void> loadPuzzleImages() async {
    pieces = await puzzleGenerator.generatePuzzle();
    emptyPosition = pieces.indexWhere((piece) => piece.isEmpty);
  }

  // Get new puzzle with new image
  Future<void> loadNewPuzzle() async {
    pieces = await puzzleGenerator.generateNewPuzzle();
    emptyPosition = pieces.indexWhere((piece) => piece.isEmpty);
  }

  // Check if piece can move to empty position
  // In glide mode, any non-empty piece can move to the empty position
  bool canMove(int position) {
    // Can't move if it's the empty position itself
    if (position == emptyPosition) {
      return false;
    }
    // Any other piece can move to the empty position
    return true;
  }

  // Move piece to empty position (glide to empty space)
  bool movePiece(int position) {
    if (!canMove(position)) {
      return false;
    }
    _swapPieces(emptyPosition, position);
    return true;
  }

  void _swapPieces(int pos1, int pos2) {
    final piece1 = pieces[pos1];
    final piece2 = pieces[pos2];

    pieces[pos1] = PuzzlePiece(
      number: piece2.number,
      imageUrl: piece2.imageUrl,
      correctPosition: piece2.correctPosition,
      currentPosition: pos1,
      gridSize: gridSize,
    );

    pieces[pos2] = PuzzlePiece(
      number: piece1.number,
      imageUrl: piece1.imageUrl,
      correctPosition: piece1.correctPosition,
      currentPosition: pos2,
      gridSize: gridSize,
    );

    if (piece1.isEmpty) emptyPosition = pos2;
    if (piece2.isEmpty) emptyPosition = pos1;
  }

  //  List<int> _getAdjacentPositions(int position) {
  //     List<int> adjacent = [];
  //     int row = position ~/ gridSize;
  //     int col = position % gridSize;

  //     if (row > 0) adjacent.add(position - gridSize);
  //     if (row < gridSize - 1) adjacent.add(position + gridSize);
  //     if (col > 0) adjacent.add(position - 1);
  //     if (col < gridSize - 1) adjacent.add(position + 1);

  //     return adjacent;
  //   }

  bool get isSolved {
    for (var piece in pieces) {
      if (!piece.isCorrect) return false;
    }
    return true;
  }

  int get correctCount {
    return pieces.where((piece) => piece.isCorrect).length;
  }

  double get completionPercentage {
    return correctCount / (totalPieces - 1);
  }
}
