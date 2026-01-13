import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';

class ImagePuzzlePiece extends StatelessWidget {
  final PuzzlePiece piece;
  final VoidCallback onTap;
  final double size;

  const ImagePuzzlePiece({
    super.key,
    required this.piece,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (piece.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey, width: 1.0),
        ),
        child: const Center(
          child: Icon(Icons.drag_handle, color: Colors.grey, size: 32),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: piece.isCorrect ? Colors.green : Colors.blue[400]!,
            width: piece.isCorrect ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (piece.imageUrl == null) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Text(
            piece.number?.toString() ?? '?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      );
    }
    return ClipRect(
      child: Align(
        alignment: Alignment(piece.alignmentX, piece.alignmentY),
        widthFactor: 1.0 / piece.gridSize,
        heightFactor: 1.0 / piece.gridSize,
        child: Image.network(
          piece.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Show number if image fails to load
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_not_supported, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      piece.number?.toString() ?? '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
