// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:puzzle/game_logic.dart';
import 'package:puzzle/widgets/image_puzzle_piece.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late PuzzleGame game;
  int gridSize = 4;
  bool isLoading = true;
  bool isNewImageLoading = false;
  int moveCount = 0;
  // DateTime? startTime; // Timer removed

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    setState(() {
      isLoading = true;
      moveCount = 0;
      // startTime = DateTime.now(); // Timer removed
    });

    game = PuzzleGame(gridSize: gridSize);
    await game.loadPuzzleImages();

    setState(() => isLoading = false);
  }

  Future<void> _resetGame() async {
    setState(() {
      isNewImageLoading = false;
      moveCount = 0;
      // startTime = DateTime.now(); // Timer removed
    });

    await game.loadPuzzleImages();
    setState(() {});
  }

  Future<void> _newImageGame() async {
    setState(() {
      isNewImageLoading = true;
      moveCount = 0;
      // startTime = DateTime.now(); // Timer removed
    });

    await game.loadNewPuzzle();

    setState(() => isNewImageLoading = false);
  }

  Future<void> _changeGridSize(int newSize) async {
    setState(() {
      gridSize = newSize;
      isLoading = true;
      moveCount = 0;
      // startTime = DateTime.now(); // Timer removed
    });

    game = PuzzleGame(gridSize: newSize);
    await game.loadPuzzleImages();

    setState(() => isLoading = false);
  }

  void _movePiece(int position) {
    if (game.movePiece(position)) {
      setState(() {
        moveCount++;
      });

      if (game.isSolved) {
        _showWinDialog();
      }
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('🎉 Puzzle Solved!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              // Timer display removed
              Text('Moves: $moveCount', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Grid: $gridSize×$gridSize',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'Great job! 🇹🇳',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newImageGame();
              },
              child: const Text('New Image'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridSizeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.grid_view, size: 20),
        const SizedBox(width: 8),
        const Text('Grid:', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildGridSizeOption(3, '3×3'),
              _buildGridSizeOption(4, '4×4'),
              _buildGridSizeOption(5, '5×5'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridSizeOption(int size, String label) {
    bool isSelected = gridSize == size;
    return GestureDetector(
      onTap: () => _changeGridSize(size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Timer column removed
          Column(
            children: [
              const Icon(Icons.directions, color: Colors.blue, size: 20),
              const SizedBox(height: 4),
              Text(
                '$moveCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Moves', style: TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.blue, size: 20),
              const SizedBox(height: 4),
              Text(
                '${game.correctCount}/${game.totalPieces - 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Pieces', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleGrid() {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    // Calculate available space for grid
    final availableWidth = MediaQuery.of(context).size.width - 32;
    final pieceSize = (availableWidth / gridSize) - 4;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: game.totalPieces,
      itemBuilder: (context, index) {
        final piece = game.pieces[index];
        return ImagePuzzlePiece(
          piece: piece,
          onTap: () => _movePiece(index),
          size: pieceSize,
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            'Loading Tunisian Puzzle...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text('🇹🇳', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            'Grid: $gridSize×$gridSize',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tunisian Puzzle'),
        actions: [
          _buildGridSizeSelector(),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _newImageGame,
            icon: isNewImageLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.image),
            tooltip: 'New Image',
          ),
          IconButton(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart Puzzle',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats card
          if (!isLoading) _buildStatsCard(),

          // Progress indicator
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: game.completionPercentage,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

          // Puzzle grid
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildPuzzleGrid(),
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _newImageGame,
                  icon: const Icon(Icons.image),
                  label: const Text('New Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
