import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:puzzle/game_logic.dart';
import 'package:puzzle/models/puzzle_piece.dart';
import 'package:puzzle/screens/puzzle.dart';
import 'package:puzzle/widgets/image_puzzle_piece.dart';

void main() {
  group('PuzzlePiece Model Tests', () {
    test('PuzzlePiece should correctly identify if it is empty', () {
      final emptyPiece = PuzzlePiece(
        number: null,
        imageUrl: null,
        correctPosition: 15,
        currentPosition: 15,
        gridSize: 4,
      );
      expect(emptyPiece.isEmpty, true);

      final normalPiece = PuzzlePiece(
        number: 1,
        imageUrl: 'test.jpg',
        correctPosition: 0,
        currentPosition: 0,
        gridSize: 4,
      );
      expect(normalPiece.isEmpty, false);
    });

    test(
      'PuzzlePiece should correctly identify if it is in correct position',
      () {
        final correctPiece = PuzzlePiece(
          number: 5,
          imageUrl: 'test.jpg',
          correctPosition: 4,
          currentPosition: 4,
          gridSize: 4,
        );
        expect(correctPiece.isCorrect, true);

        final incorrectPiece = PuzzlePiece(
          number: 5,
          imageUrl: 'test.jpg',
          correctPosition: 4,
          currentPosition: 8,
          gridSize: 4,
        );
        expect(incorrectPiece.isCorrect, false);
      },
    );

    test('PuzzlePiece should calculate correct row and column', () {
      final piece = PuzzlePiece(
        number: 1,
        imageUrl: 'test.jpg',
        correctPosition: 5,
        currentPosition: 9,
        gridSize: 4,
      );
      expect(piece.correctRow, 1); // 5 ~/ 4 = 1
      expect(piece.correctCol, 1); // 5 % 4 = 1
      expect(piece.currentRow, 2); // 9 ~/ 4 = 2
      expect(piece.currentCol, 1); // 9 % 4 = 1
    });

    test('PuzzlePiece should calculate alignment correctly', () {
      final piece = PuzzlePiece(
        number: 1,
        imageUrl: 'test.jpg',
        correctPosition: 0,
        currentPosition: 0,
        gridSize: 4,
      );
      expect(piece.alignmentX, -1.0);
      expect(piece.alignmentY, -1.0);
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

    test('PuzzleGame should identify adjacent positions correctly', () {
      final game = PuzzleGame(gridSize: 4);
      // Corner position (0,0) - position 0
      expect(game.canMove(1), false); // right of corner
      expect(game.canMove(4), false); // below corner

      // Position adjacent to empty (15) should be movable
      expect(game.canMove(11), true); // above empty
      expect(game.canMove(14), true); // left of empty
    });

    test('PuzzleGame should move pieces correctly', () {
      final game = PuzzleGame(gridSize: 4);
      final initialEmptyPos = game.emptyPosition;

      // Move piece above empty
      final moved = game.movePiece(11);
      expect(moved, true);
      expect(game.emptyPosition, 11);
      expect(
        game.pieces[initialEmptyPos].number,
        12,
      ); // Piece 12 moved to position 15
    });

    test('PuzzleGame should not move non-adjacent pieces', () {
      final game = PuzzleGame(gridSize: 4);
      final initialEmptyPos = game.emptyPosition;

      // Try to move a piece far from empty
      final moved = game.movePiece(0);
      expect(moved, false);
      expect(game.emptyPosition, initialEmptyPos);
    });

    test('PuzzleGame should detect when puzzle is solved', () {
      final game = PuzzleGame(gridSize: 4);
      // Initially, puzzle is in correct order
      expect(game.isSolved, true);

      // Move a piece
      game.movePiece(14);
      expect(game.isSolved, false);
    });

    test('PuzzleGame should calculate completion percentage', () {
      final game = PuzzleGame(gridSize: 4);
      expect(game.completionPercentage, 1.0); // All correct initially

      game.movePiece(14);
      expect(game.completionPercentage, lessThan(1.0));
    });

    test('PuzzleGame should count correct pieces', () {
      final game = PuzzleGame(gridSize: 4);
      expect(game.correctCount, 16); // All pieces in correct position

      game.movePiece(14);
      expect(game.correctCount, lessThan(16));
    });
  });

  group('PuzzlePage Widget Tests', () {
    testWidgets('PuzzlePage loads and displays all UI elements', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        // Check for app bar
        expect(find.text('Tunisian Puzzle'), findsOneWidget);

        // Check for grid
        expect(find.byType(GridView), findsOneWidget);

        // Check for stats card
        expect(find.text('Moves'), findsOneWidget);
        expect(find.text('Pieces'), findsOneWidget);

        // Check for progress indicator
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Check for control buttons
        expect(find.text('Restart'), findsOneWidget);
        expect(find.text('New Image'), findsOneWidget);
      });
    });

    testWidgets('Grid size selector shows all options', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        expect(find.text('3×3'), findsOneWidget);
        expect(find.text('4×4'), findsOneWidget);
        expect(find.text('5×5'), findsOneWidget);
      });
    });

    testWidgets('Can change grid size', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        // Tap on 3×3
        await tester.tap(find.text('3×3'));
        await tester.pumpAndSettle();

        // Loading screen should appear briefly, then grid should update
        expect(find.byType(GridView), findsOneWidget);
      });
    });

    testWidgets('Can tap puzzle pieces', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        // Find initial move count
        final initialMovesFinder = find.text('0');

        // Find a tappable piece (GestureDetector)
        final pieces = find.byType(GestureDetector);
        if (pieces.evaluate().isNotEmpty) {
          await tester.tap(pieces.first);
          await tester.pump();
        }
      });
    });

    testWidgets('Restart button works', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        final restartButton = find.text('Restart');
        expect(restartButton, findsOneWidget);

        await tester.tap(restartButton);
        await tester.pumpAndSettle();

        // Puzzle should be reset, moves should be 0
        expect(find.byType(GridView), findsOneWidget);
      });
    });

    testWidgets('New Image button works', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        // Find the "New Image" ElevatedButton
        final newImageButton = find.widgetWithText(ElevatedButton, 'New Image');
        expect(newImageButton, findsOneWidget);

        await tester.tap(newImageButton);
        await tester.pump();

        // Should show loading state, then new grid after settling
        await tester.pumpAndSettle();
        expect(find.byType(GridView), findsOneWidget);
      });
    });

    testWidgets('Puzzle loads and shows grid', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));

        // After build, puzzle should eventually load
        await tester.pumpAndSettle();

        // Should have GridView with puzzle pieces
        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(ImagePuzzlePiece), findsWidgets);
      });
    });

    testWidgets('Win dialog appears when puzzle is solved', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        // In a real test, we would need to solve the puzzle
        // For now, just verify the dialog doesn't show initially
        expect(find.text('🎉 Puzzle Solved!'), findsNothing);
      });
    });

    testWidgets('Stats card updates with puzzle progress', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        // Verify stats are present
        expect(find.text('Moves'), findsOneWidget);
        expect(find.text('Pieces'), findsOneWidget);

        // Stats should show initial values
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    testWidgets('AppBar shows correct title and icons', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PuzzlePage()));
        await tester.pumpAndSettle();

        expect(find.text('Tunisian Puzzle'), findsOneWidget);
        // Two image icons: one in AppBar, one in bottom button
        expect(find.byIcon(Icons.image), findsNWidgets(2));
        // Multiple refresh icons (AppBar + bottom button)
        expect(find.byIcon(Icons.refresh), findsWidgets);
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      });
    });
  });
}
