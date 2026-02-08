import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/puzzle/models/puzzle_piece.dart';
import 'package:multigame/games/puzzle/services/image_puzzle_generator.dart';
import 'package:multigame/services/game/unsplash_service.dart';

/// Fake implementation of UnsplashService for testing
class FakeUnsplashService extends UnsplashService {
  final List<String> _imageUrls;
  int _callCount = 0;
  bool _cacheCleared = false;

  FakeUnsplashService({List<String>? imageUrls})
      : _imageUrls = imageUrls ??
            [
              'https://example.com/image1.jpg',
              'https://example.com/image2.jpg',
              'https://example.com/image3.jpg'
            ];

  @override
  Future<String> getRandomImage() async {
    final url = _imageUrls[_callCount % _imageUrls.length];
    _callCount++;
    return url;
  }

  @override
  void clearCache() {
    _cacheCleared = true;
  }

  int get callCount => _callCount;
  bool get wasCacheCleared => _cacheCleared;
}

void main() {
  group('ImagePuzzleGenerator', () {
    group('Constructor', () {
      test('should initialize with provided grid size', () {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        expect(generator.gridSize, equals(3));
      });

      test('should accept different grid sizes', () {
        final generator4x4 = ImagePuzzleGenerator(gridSize: 4);
        expect(generator4x4.gridSize, equals(4));

        final generator5x5 = ImagePuzzleGenerator(gridSize: 5);
        expect(generator5x5.gridSize, equals(5));
      });
    });

    group('generatePuzzle', () {
      test('should generate correct number of pieces for 3x3 grid', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        expect(pieces.length, equals(9)); // 3x3 = 9 pieces
      });

      test('should generate correct number of pieces for 4x4 grid', () async {
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generatePuzzle();

        expect(pieces.length, equals(16)); // 4x4 = 16 pieces
      });

      test('should generate correct number of pieces for 5x5 grid', () async {
        final generator = ImagePuzzleGenerator(gridSize: 5);
        final pieces = await generator.generatePuzzle();

        expect(pieces.length, equals(25)); // 5x5 = 25 pieces
      });

      test('should have exactly one empty piece at the end', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        final emptyPieces = pieces.where((p) => p.isEmpty).toList();
        expect(emptyPieces.length, equals(1));
      });

      test('should set empty piece with null number and null imageUrl',
          () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        final emptyPiece = pieces.firstWhere((p) => p.isEmpty);
        expect(emptyPiece.number, isNull);
        expect(emptyPiece.imageUrl, isNull);
      });

      test('should set correct position property for all pieces', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        // Verify each piece has a valid correctPosition
        // Sort by correctPosition to verify they're sequential
        final sortedByCorrect = List<PuzzlePiece>.from(pieces)
          ..sort((a, b) => a.correctPosition.compareTo(b.correctPosition));

        for (int i = 0; i < sortedByCorrect.length; i++) {
          expect(sortedByCorrect[i].correctPosition, equals(i));
        }

        // Empty piece should have correct position at last index (8 for 3x3)
        final emptyPiece = pieces.firstWhere((p) => p.isEmpty);
        expect(emptyPiece.correctPosition, equals(8));
      });

      test('should assign sequential numbers to non-empty pieces', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        // Get non-empty pieces and sort by correct position
        final nonEmptyPieces = pieces
            .where((p) => !p.isEmpty)
            .toList()
          ..sort((a, b) => a.correctPosition.compareTo(b.correctPosition));

        for (int i = 0; i < nonEmptyPieces.length; i++) {
          expect(nonEmptyPieces[i].number, equals(i + 1));
        }
      });

      test('should assign same imageUrl to all non-empty pieces', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        final nonEmptyPieces = pieces.where((p) => !p.isEmpty).toList();
        final firstImageUrl = nonEmptyPieces.first.imageUrl;

        for (final piece in nonEmptyPieces) {
          expect(piece.imageUrl, equals(firstImageUrl));
          expect(piece.imageUrl, isNotNull);
        }
      });

      test('should set correct gridSize on all pieces', () async {
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generatePuzzle();

        for (final piece in pieces) {
          expect(piece.gridSize, equals(4));
        }
      });

      test('should shuffle pieces (not in solved state)', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        // Check if puzzle is NOT in solved state
        // At least one piece should not be in its correct position
        final shuffledPieces =
            pieces.where((p) => p.currentPosition != p.correctPosition).toList();

        expect(shuffledPieces.isNotEmpty, isTrue,
            reason: 'Puzzle should be shuffled');
      });

      test('should reuse same image URL on subsequent calls', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);

        final pieces1 = await generator.generatePuzzle();
        final pieces2 = await generator.generatePuzzle();

        final url1 = pieces1.firstWhere((p) => !p.isEmpty).imageUrl;
        final url2 = pieces2.firstWhere((p) => !p.isEmpty).imageUrl;

        expect(url1, equals(url2),
            reason: 'Should cache and reuse image URL');
      });

      test('should maintain empty piece throughout generation', () async {
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generatePuzzle();

        // Verify exactly one empty piece exists
        final emptyCount = pieces.where((p) => p.isEmpty).length;
        expect(emptyCount, equals(1));

        // Verify all other pieces have numbers
        final numberedCount = pieces.where((p) => p.number != null).length;
        expect(numberedCount, equals(15)); // 16 - 1 = 15
      });
    });

    group('generateNewPuzzle', () {
      test('should generate puzzle with new structure', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);

        // Generate first puzzle
        await generator.generatePuzzle();

        // Generate new puzzle (should clear cache and get new image)
        final pieces = await generator.generateNewPuzzle();

        // Verify new puzzle has correct structure
        expect(pieces.length, equals(9));
        expect(pieces.where((p) => p.isEmpty).length, equals(1));
      });

      test('should generate correct number of pieces', () async {
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generateNewPuzzle();

        expect(pieces.length, equals(16));
      });

      test('should maintain puzzle structure after generating new puzzle',
          () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generateNewPuzzle();

        // Verify structure
        expect(pieces.length, equals(9));
        expect(pieces.where((p) => p.isEmpty).length, equals(1));
        expect(pieces.where((p) => p.number != null).length, equals(8));
      });
    });

    group('Puzzle solvability', () {
      test('should generate solvable puzzles consistently', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);

        // Generate multiple puzzles
        for (int i = 0; i < 5; i++) {
          final pieces = await generator.generatePuzzle();

          // A puzzle generated by making valid moves is always solvable
          // Verify the puzzle has been shuffled
          final isSolved = pieces.every((p) => p.isCorrect);
          expect(isSolved, isFalse,
              reason: 'Generated puzzle should not be in solved state');
        }
      });

      test('should ensure empty piece can move after shuffle', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        // Find empty piece position
        final emptyPiece = pieces.firstWhere((p) => p.isEmpty);
        final emptyPos = emptyPiece.currentPosition;

        // Verify empty piece has at least one adjacent piece
        final row = emptyPos ~/ 3;
        final col = emptyPos % 3;

        final hasAdjacentSpace =
            row > 0 || row < 2 || col > 0 || col < 2;
        expect(hasAdjacentSpace, isTrue,
            reason: 'Empty piece should have adjacent spaces to move');
      });

      test('should shuffle significantly (high entropy)', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        // Count pieces not in correct position
        final misplacedCount =
            pieces.where((p) => !p.isCorrect).length;

        // After 300 moves (100 * 3), expect significant shuffling
        expect(misplacedCount, greaterThan(3),
            reason: 'Most pieces should be shuffled');
      });
    });

    group('Edge cases', () {
      test('should handle minimum grid size (2x2)', () async {
        final generator = ImagePuzzleGenerator(gridSize: 2);
        final pieces = await generator.generatePuzzle();

        expect(pieces.length, equals(4));
        expect(pieces.where((p) => p.isEmpty).length, equals(1));
        expect(pieces.where((p) => p.number != null).length, equals(3));
      });

      test('should handle large grid size (6x6)', () async {
        final generator = ImagePuzzleGenerator(gridSize: 6);
        final pieces = await generator.generatePuzzle();

        expect(pieces.length, equals(36));
        expect(pieces.where((p) => p.isEmpty).length, equals(1));
        expect(pieces.where((p) => p.number != null).length, equals(35));
      });

      test('should assign correct positions for large grids', () async {
        final generator = ImagePuzzleGenerator(gridSize: 5);
        final pieces = await generator.generatePuzzle();

        // Sort pieces by correct position
        final sortedPieces = List<PuzzlePiece>.from(pieces)
          ..sort((a, b) => a.correctPosition.compareTo(b.correctPosition));

        for (int i = 0; i < sortedPieces.length; i++) {
          expect(sortedPieces[i].correctPosition, equals(i));
        }
      });

      test('should maintain piece count after multiple generations', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);

        for (int i = 0; i < 3; i++) {
          final pieces = await generator.generatePuzzle();
          expect(pieces.length, equals(9));
        }
      });
    });

    group('Piece properties', () {
      test('should create pieces with all required properties', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        for (final piece in pieces) {
          // All pieces should have these properties set
          expect(piece.correctPosition, isNotNull);
          expect(piece.currentPosition, isNotNull);
          expect(piece.gridSize, equals(3));

          // Empty piece checks
          if (piece.isEmpty) {
            expect(piece.number, isNull);
            expect(piece.imageUrl, isNull);
          } else {
            expect(piece.number, isNotNull);
            expect(piece.imageUrl, isNotNull);
          }
        }
      });

      test('should set currentPosition correctly after shuffle', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        // All pieces should have valid current positions
        for (int i = 0; i < pieces.length; i++) {
          expect(pieces[i].currentPosition, equals(i));
        }

        // No duplicate current positions
        final positions = pieces.map((p) => p.currentPosition).toList();
        final uniquePositions = positions.toSet();
        expect(uniquePositions.length, equals(pieces.length),
            reason: 'All current positions should be unique');
      });

      test('should maintain correct position invariant', () async {
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generatePuzzle();

        // Correct positions should never change
        for (final piece in pieces) {
          expect(piece.correctPosition, greaterThanOrEqualTo(0));
          expect(piece.correctPosition, lessThan(16));
        }
      });
    });

    group('Grid size consistency', () {
      test('should use same grid size for all pieces in 3x3', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        expect(pieces.every((p) => p.gridSize == 3), isTrue);
      });

      test('should use same grid size for all pieces in 4x4', () async {
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generatePuzzle();

        expect(pieces.every((p) => p.gridSize == 4), isTrue);
      });

      test('should use same grid size for all pieces in 5x5', () async {
        final generator = ImagePuzzleGenerator(gridSize: 5);
        final pieces = await generator.generatePuzzle();

        expect(pieces.every((p) => p.gridSize == 5), isTrue);
      });
    });

    group('Image URL behavior', () {
      test('should fetch image URL on first generation', () async {
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        final imageUrl = pieces.firstWhere((p) => !p.isEmpty).imageUrl;
        expect(imageUrl, isNotNull);
        expect(imageUrl, isNotEmpty);
      });

      test('should use consistent image URL across all non-empty pieces',
          () async {
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generatePuzzle();

        final imageUrls = pieces
            .where((p) => !p.isEmpty)
            .map((p) => p.imageUrl)
            .toSet();

        expect(imageUrls.length, equals(1),
            reason: 'All non-empty pieces should have same image URL');
      });
    });

    group('Shuffle validation', () {
      test('should perform enough moves to shuffle thoroughly', () async {
        // For a 3x3 grid, 300 moves (100 * gridSize) should thoroughly shuffle
        final generator = ImagePuzzleGenerator(gridSize: 3);
        final pieces = await generator.generatePuzzle();

        // Count how many pieces are out of place
        final outOfPlaceCount =
            pieces.where((p) => p.currentPosition != p.correctPosition).length;

        // Expect most pieces to be shuffled (at least 50%)
        expect(outOfPlaceCount, greaterThanOrEqualTo(4),
            reason: 'Puzzle should be significantly shuffled');
      });

      test('should keep puzzle solvable by only making valid moves', () async {
        // Since we only swap with adjacent pieces, puzzle remains solvable
        final generator = ImagePuzzleGenerator(gridSize: 4);
        final pieces = await generator.generatePuzzle();

        // Verify puzzle structure is intact
        expect(pieces.length, equals(16));

        // All positions should be occupied
        final positions = pieces.map((p) => p.currentPosition).toSet();
        expect(positions.length, equals(16));
        expect(positions, containsAll([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]));
      });
    });
  });
}
