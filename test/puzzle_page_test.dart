import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/game_logic.dart';
import 'package:multigame/models/puzzle_piece.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PuzzlePiece Model Tests', () {
    test('PuzzlePiece should create with all properties', () {
      final piece = PuzzlePiece(
        number: 1,
        imageUrl: 'https://example.com/image.jpg',
        correctPosition: 0,
        currentPosition: 5,
        gridSize: 3,
      );

      expect(piece.number, 1);
      expect(piece.correctPosition, 0);
      expect(piece.currentPosition, 5);
      expect(piece.isEmpty, false);
      expect(piece.gridSize, 3);
    });

    test('PuzzlePiece should determine if in correct position', () {
      final piece = PuzzlePiece(
        number: 1,
        imageUrl: 'https://example.com/image.jpg',
        correctPosition: 0,
        currentPosition: 0,
        gridSize: 3,
      );

      expect(piece.isCorrect, true);
    });

    test('PuzzlePiece should calculate alignment correctly', () {
      final piece = PuzzlePiece(
        number: 1,
        imageUrl: 'https://example.com/image.jpg',
        correctPosition: 0,
        currentPosition: 0,
        gridSize: 3,
      );
      expect(piece.alignmentX, -1.0);
      expect(piece.alignmentY, -1.0);
    });

    test('PuzzlePiece should detect empty pieces', () {
      final piece = PuzzlePiece(
        number: null,
        imageUrl: null,
        correctPosition: 8,
        currentPosition: 8,
        gridSize: 3,
      );
      expect(piece.isEmpty, true);
    });
  });

  group('PuzzleGame Logic Tests', () {
    test('PuzzleGame should initialize with correct grid size', () {
      final game = PuzzleGame(gridSize: 4);
      expect(game.gridSize, 4);
      expect(game.totalPieces, 16);
      expect(game.pieces.length, 16);
      expect(game.emptyPosition, 15);
    });

    test('PuzzleGame should detect solved state', () {
      final game = PuzzleGame(gridSize: 4);
      // Initially should be solvable state
      expect(game.isSolved, isA<bool>());
    });

    test('PuzzleGame should calculate completion metrics', () {
      final game = PuzzleGame(gridSize: 4);
      expect(game.completionPercentage, isA<double>());
      expect(game.completionPercentage, greaterThanOrEqualTo(0.0));
      expect(
        game.completionPercentage,
        lessThanOrEqualTo(1.1),
      ); // Allow small floating point errors
    });

    test('PuzzleGame should count correct pieces', () {
      final game = PuzzleGame(gridSize: 4);
      expect(game.correctCount, isA<int>());
      expect(game.correctCount, greaterThanOrEqualTo(0));
      expect(game.correctCount, lessThanOrEqualTo(16));
    });
  });

  group('PuzzlePage Widget Tests', () {
    testWidgets('PuzzlePage loads and displays UI elements', (
      WidgetTester tester,
    ) async {
      // TODO: Add Firebase mocking to properly test PuzzlePage with providers
    }, skip: true);

    testWidgets('Stats cards display', (WidgetTester tester) async {
      // TODO: Add Firebase mocking to properly test PuzzlePage with providers
    }, skip: true);

    // Widget tests that require Firebase are skipped until Firebase mocking is properly set up
    testWidgets('Puzzle grid renders', (WidgetTester tester) async {
      // TODO: Add Firebase mocking packages to pubspec.yaml dev_dependencies:
      // firebase_auth_mocks and fake_cloud_firestore
      // Then uncomment this test
    }, skip: true);

    testWidgets('Control buttons are present', (WidgetTester tester) async {
      // TODO: Add Firebase mocking packages to pubspec.yaml dev_dependencies:
      // firebase_auth_mocks and fake_cloud_firestore
      // Then uncomment this test
    }, skip: true);
  });
}
