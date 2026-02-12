import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/puzzle/providers/puzzle_notifier.dart';

class PuzzleImagePreviewOverlay extends ConsumerWidget {
  const PuzzleImagePreviewOverlay({
    super.key,
    required this.animation,
    required this.hintButtonKey,
  });

  final Animation<double> animation;
  final GlobalKey hintButtonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(puzzleProvider).game;
    if (game == null) return const SizedBox.shrink();

    final imageUrl =
        game.pieces.firstWhere((p) => p.imageUrl != null).imageUrl;
    if (imageUrl == null) return const SizedBox.shrink();

    RenderBox? hintBox;
    Offset? hintPosition;
    Size? hintSize;

    try {
      hintBox =
          hintButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (hintBox != null) {
        hintPosition = hintBox.localToGlobal(Offset.zero);
        hintSize = hintBox.size;
      }
    } catch (_) {
      hintPosition = null;
      hintSize = null;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final isAnimating = animation.value > 0;

        final startLeft = screenSize.width * 0.1;
        final startTop = screenSize.height * 0.2;
        final startWidth = screenSize.width * 0.8;
        final startHeight = screenSize.width * 0.8;

        final endLeft = hintPosition?.dx ?? screenSize.width - 100;
        final endTop = hintPosition?.dy ?? 150;
        final endWidth = hintSize?.width ?? 64;
        final endHeight = hintSize?.height ?? 64;

        final currentLeft =
            startLeft + (endLeft - startLeft) * animation.value;
        final currentTop =
            startTop + (endTop - startTop) * animation.value;
        final currentWidth =
            startWidth + (endWidth - startWidth) * animation.value;
        final currentHeight =
            startHeight + (endHeight - startHeight) * animation.value;
        final currentOpacity = 1.0 - (animation.value * 0.7);

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.8 * (1 - animation.value),
                ),
              ),
            ),
            Positioned(
              left: currentLeft,
              top: currentTop,
              child: IgnorePointer(
                ignoring: isAnimating,
                child: Container(
                  width: currentWidth,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      24 - (animation.value * 8),
                    ),
                    border: Border.all(
                      color: const Color(0xFF00d4ff)
                          .withValues(alpha: currentOpacity),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00d4ff)
                            .withValues(alpha: 0.5 * currentOpacity),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      22 - (animation.value * 8),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF21242b),
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress
                                              .cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: const Color(0xFF00d4ff),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (!isAnimating)
              Positioned(
                left: 0,
                right: 0,
                bottom: screenSize.height * 0.15,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21242b),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00d4ff),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'Memorize this image! 💡',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00d4ff),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
