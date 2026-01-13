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
    final urlPreview = piece.imageUrl != null
        ? (piece.imageUrl!.length > 50
              ? piece.imageUrl!.substring(0, 50) + '...'
              : piece.imageUrl!)
        : 'null';
    print(
      'Building piece: number=${piece.number}, imageUrl=$urlPreview, pos=${piece.currentPosition}',
    );
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
    print(
      '_buildImageContent: imageUrl is ${piece.imageUrl == null ? "NULL" : "NOT NULL"}, size=$size, gridSize=${piece.gridSize}',
    );
    if (piece.imageUrl == null) {
      print('⚠️ Piece ${piece.number} has NULL imageUrl!');
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
    print('Loading image: ${piece.imageUrl!}');
    print(
      'Piece position - correct: (${piece.correctRow}, ${piece.correctCol}), current: (${piece.currentRow}, ${piece.currentCol})',
    );
    print(
      'Image will be cropped at alignment: (${piece.alignmentX}, ${piece.alignmentY})',
    );

    // Calculate the offset for this piece within the full image
    final double offsetX = -piece.correctCol * size;
    final double offsetY = -piece.correctRow * size;

    return ClipRect(
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size * piece.gridSize,
          maxWidth: size * piece.gridSize,
          minHeight: size * piece.gridSize,
          maxHeight: size * piece.gridSize,
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Image.network(
              piece.imageUrl!,
              width: size * piece.gridSize,
              height: size * piece.gridSize,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  print(
                    '✅ Image loaded successfully for piece ${piece.number}',
                  );
                  return child;
                }
                print(
                  '⏳ Loading image for piece ${piece.number}: ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes}',
                );

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
                print(
                  '❌ ERROR loading image for piece ${piece.number}: $error',
                );
                print('Stack trace: $stackTrace');
                // Show number if image fails to load
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          color: Colors.red,
                        ),
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
        ),
      ),
    );
  }
}
