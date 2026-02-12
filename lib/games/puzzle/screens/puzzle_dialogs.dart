import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/puzzle/providers/puzzle_notifier.dart';
import 'package:multigame/games/puzzle/providers/puzzle_ui_notifier.dart';

void showPuzzleHintDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF21242b),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00d4ff), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00d4ff).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Image Preview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00d4ff),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Color(0xFF00d4ff),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showPuzzleWinDialog({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onShowPreview,
}) async {
  final gameNotifier = ref.read(puzzleProvider.notifier);
  final uiNotifier = ref.read(puzzleUIProvider.notifier);
  final newAchievements = await gameNotifier.recordGameCompletion();

  if (!context.mounted) return;

  final state = ref.read(puzzleProvider);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Stack(
        children: [
          Positioned.fill(
            child: Container(
                color: const Color(0xFF0a0b0e).withValues(alpha: 0.6)),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFF21242b).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFffd700).withValues(alpha: 0.1),
                          border: Border.all(
                            color: const Color(0xFFffd700).withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFffd700).withValues(alpha: 0.3),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 48)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'YOU SOLVED IT!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MASTERPIECE COMPLETE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildWinStatCard(
                                'MOVES', '${state.moveCount}'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildWinStatCard('TIME', state.formatTime()),
                          ),
                        ],
                      ),
                      if (newAchievements.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFffd700).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFffd700).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  newAchievements.first,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFffd700),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildWinButton(
                        color: const Color(0xFFff5c00),
                        bottomBorderColor: const Color(0xFF8B3000),
                        label: 'NEXT LEVEL',
                        onTap: () {
                          Navigator.of(context).pop();
                          uiNotifier.setNewImageLoading(true);
                          gameNotifier.newImageGame().then((_) {
                            uiNotifier.setNewImageLoading(false);
                            onShowPreview();
                          }).catchError((_) {
                            uiNotifier.setNewImageLoading(false);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildWinButton(
                        color: const Color(0xFF21242b),
                        bottomBorderColor: Colors.black,
                        label: 'BACK TO MENU',
                        labelColor: Colors.grey[400],
                        onTap: () {
                          Navigator.of(context).pop();
                          gameNotifier.resetGame().then((_) => onShowPreview());
                        },
                      ),
                    ],
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

Widget _buildWinStatCard(String label, String value) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

Widget _buildWinButton({
  required Color color,
  required Color bottomBorderColor,
  required String label,
  required VoidCallback onTap,
  Color? labelColor,
}) {
  return Material(
    color: color,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            bottom: BorderSide(color: bottomBorderColor, width: 4),
          ),
          boxShadow: labelColor == null
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor ?? Colors.white,
              fontSize: labelColor != null ? 18 : 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),
  );
}

void showPuzzleGridSizeDialog(
  BuildContext context,
  WidgetRef ref,
  VoidCallback onSizeChanged,
) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF21242b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Grid Size',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00d4ff),
                ),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (ctx, ref, _) {
                  final currentSize = ref.watch(puzzleProvider).gridSize;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGridSizeOption(
                          context, ref, 3, currentSize, onSizeChanged),
                      _buildGridSizeOption(
                          context, ref, 4, currentSize, onSizeChanged),
                      _buildGridSizeOption(
                          context, ref, 5, currentSize, onSizeChanged),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(color: Color(0xFF00d4ff)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildGridSizeOption(
  BuildContext context,
  WidgetRef ref,
  int size,
  int currentSize,
  VoidCallback onSizeChanged,
) {
  final isSelected = currentSize == size;
  return GestureDetector(
    onTap: () {
      Navigator.pop(context);
      ref.read(puzzleUIProvider.notifier).setLoading(true);
      ref.read(puzzleProvider.notifier).changeGridSize(size).then((_) {
        ref.read(puzzleUIProvider.notifier).setLoading(false);
        onSizeChanged();
      }).catchError((_) {
        ref.read(puzzleUIProvider.notifier).setLoading(false);
      });
    },
    child: Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00d4ff) : const Color(0xFF16181d),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00d4ff)
              : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$size×$size',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    ),
  );
}
