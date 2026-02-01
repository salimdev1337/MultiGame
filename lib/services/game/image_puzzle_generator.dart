import 'dart:math';
import '../../models/puzzle_piece.dart';
import 'unsplash_service.dart';

class ImagePuzzleGenerator {
  final UnsplashService unsplashService = UnsplashService();
  final int gridSize;
  String? _currentImageUrl;

  ImagePuzzleGenerator({required this.gridSize});

  Future<List<PuzzlePiece>> generatePuzzle() async {
    // debug: 'PUZZLE GENERATOR: Generating puzzle (${gridSize}x$gridSize)'
    _currentImageUrl ??= await unsplashService.getRandomImage();
    // debug: 'Using image URL for puzzle: $_currentImageUrl'

    final List<PuzzlePiece> pieces = [];
    final int totalPieces = gridSize * gridSize;

    for (int i = 0; i < totalPieces; i++) {
      if (i == totalPieces - 1) {
        pieces.add(
          PuzzlePiece(
            number: null,
            imageUrl: null,
            correctPosition: totalPieces - 1,
            currentPosition: totalPieces - 1,
            gridSize: gridSize,
          ),
        );
      } else {
        pieces.add(
          PuzzlePiece(
            number: i + 1,
            imageUrl: _currentImageUrl,
            correctPosition: i,
            currentPosition: i,
            gridSize: gridSize,
          ),
        );
      }
    }
    // debug: 'Created $totalPieces pieces (${totalPieces - 1} with images, 1 empty)'
    // debug: 'Sample piece imageUrl: ${pieces[0].imageUrl}'

    return _shufflePuzzle(pieces);
  }

  List<PuzzlePiece> _shufflePuzzle(List<PuzzlePiece> pieces) {
    final random = Random();
    int emptyPosition = pieces.length - 1;

    // Make many random valid moves
    for (int i = 0; i < 100 * gridSize; i++) {
      final adjacent = _getAdjacentPositions(emptyPosition, gridSize);
      final moveTo = adjacent[random.nextInt(adjacent.length)];

      // Swap piece with empty space
      _swapPieces(pieces, emptyPosition, moveTo);
      emptyPosition = moveTo;
    }

    return pieces;
  }

  List<int> _getAdjacentPositions(int position, int size) {
    List<int> adjacent = [];
    int row = position ~/ size;
    int col = position % size;

    if (row > 0) adjacent.add(position - size);
    if (row < size - 1) adjacent.add(position + size);
    if (col > 0) adjacent.add(position - 1);
    if (col < size - 1) adjacent.add(position + 1);

    return adjacent;
  }

  void _swapPieces(List<PuzzlePiece> pieces, int pos1, int pos2) {
    final piece1 = pieces[pos1];
    final piece2 = pieces[pos2];

    // Swap positions
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
  }

  Future<List<PuzzlePiece>> generateNewPuzzle() async {
    unsplashService.clearCache();
    _currentImageUrl = null;

    return generatePuzzle();
  }
}
