import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';

class ImagePuzzlePiece extends StatefulWidget {
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
  State<ImagePuzzlePiece> createState() => _ImagePuzzlePieceState();
}

class _ImagePuzzlePieceState extends State<ImagePuzzlePiece> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // debug: 'Building piece: number=${widget.piece.number}, imageUrl=${widget.piece.imageUrl}, pos=${widget.piece.currentPosition}'
    if (widget.piece.isEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFF16181d).withValues(alpha: 0.5 * 255),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1 * 255),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_circle_outline,
            color: const Color(0xFF00d4ff).withValues(alpha: 0.3 * 255),
            size: 32,
          ),
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          transform: Matrix4.identity()
            ..scaleByDouble(_isHovering ? 1.05 : 1.0, 1.0, 1.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovering
                  ? const Color(0xFF00d4ff)
                  : (widget.piece.isCorrect
                        ? Colors.green
                        : Colors.white.withValues(alpha: (0.2 * 255))),
              width: _isHovering ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovering
                    ? const Color(0xFF00d4ff).withValues(alpha: (0.4 * 255))
                    : Colors.black.withValues(alpha: (0.3 * 255)),
                blurRadius: _isHovering ? 15 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildImageContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // debug: '_buildImageContent: imageUrl is ${widget.piece.imageUrl == null ? "NULL" : "NOT NULL"}, size=${widget.size}, gridSize=${widget.piece.gridSize}'
    if (widget.piece.imageUrl == null) {
      // debug: 'Piece ${widget.piece.number} has NULL imageUrl!'
      return Container(
        color: const Color(0xFF21242b),
        child: Center(
          child: Text(
            widget.piece.number?.toString() ?? '?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00d4ff),
            ),
          ),
        ),
      );
    }
    // debug: 'Loading image: ${widget.piece.imageUrl!}'
    // debug: 'Piece position - correct: (${widget.piece.correctRow}, ${widget.piece.correctCol}), current: (${widget.piece.currentRow}, ${widget.piece.currentCol})'
    // debug: 'Image will be cropped at alignment: (${widget.piece.alignmentX}, ${widget.piece.alignmentY})'

    // Calculate the offset for this piece within the full image
    final double offsetX = -widget.piece.correctCol * widget.size;
    final double offsetY = -widget.piece.correctRow * widget.size;

    return ClipRect(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: widget.size * widget.piece.gridSize,
          maxWidth: widget.size * widget.piece.gridSize,
          minHeight: widget.size * widget.piece.gridSize,
          maxHeight: widget.size * widget.piece.gridSize,
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Image.network(
              widget.piece.imageUrl!,
              width: widget.size * widget.piece.gridSize,
              height: widget.size * widget.piece.gridSize,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  // debug: 'Image loaded successfully for piece ${widget.piece.number}'
                  return child;
                }
                // debug: 'Loading image for piece ${widget.piece.number}: ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes}'

                return Container(
                  color: const Color(0xFF21242b),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF00d4ff),
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // debug: 'ERROR loading image for piece ${widget.piece.number}: $error'
                // debug: 'Stack trace: $stackTrace'
                // Show number if image fails to load
                return Container(
                  color: const Color(0xFF21242b),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          color: Color(0xFFff5c00),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.piece.number?.toString() ?? '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00d4ff),
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
