import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/puzzle/providers/puzzle_notifier.dart';
import 'package:multigame/widgets/image_puzzle_piece.dart';

class PuzzleGameBoard extends ConsumerWidget {
  const PuzzleGameBoard({
    super.key,
    required this.onPieceMoved,
    required this.onDrop,
  });

  final void Function(int position) onPieceMoved;
  final void Function(int fromIndex, int toIndex) onDrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleProvider);
    return Column(
      children: [
        _buildPuzzleGridContainer(gameState),
        const SizedBox(height: 32),
        _buildProgressSection(gameState),
      ],
    );
  }

  Widget _buildPuzzleGridContainer(PuzzleState gameState) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF21242b),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05 * 255)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5 * 255),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _buildPuzzleGrid(gameState),
      ),
    );
  }

  Widget _buildPuzzleGrid(PuzzleState gameState) {
    final game = gameState.game;
    if (game == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = 10.0 * (gameState.gridSize - 1);
        final availableWidth = constraints.maxWidth - totalSpacing;
        final pieceSize = availableWidth / gameState.gridSize;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gameState.gridSize,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemCount: game.totalPieces,
          itemBuilder: (context, index) {
            final piece = game.pieces[index];
            return ImagePuzzlePiece(
              piece: piece,
              index: index,
              onTap: () => onPieceMoved(index),
              size: pieceSize,
              onDragStart: (_) {},
              onDragEnd: (draggedIndex, targetIndex) {
                onDrop(draggedIndex, targetIndex);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProgressSection(PuzzleState gameState) {
    final game = gameState.game;
    if (game == null) return const SizedBox.shrink();

    final progress = game.completionPercentage;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00d4ff),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF21242b),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05 * 255),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00d4ff), Color(0xFF00a8cc)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00d4ff,
                          ).withValues(alpha: 0.4 * 255),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
