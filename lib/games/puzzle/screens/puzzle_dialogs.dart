import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/games/puzzle/providers/puzzle_notifier.dart';
import 'package:multigame/games/puzzle/providers/puzzle_ui_notifier.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';

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
                                value:
                                    loadingProgress.expectedTotalBytes != null
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
  GameResultWidget.show(
    context,
    GameResultConfig(
      isVictory: true,
      title: 'YOU SOLVED IT!',
      titleStyle: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: -0.5,
        fontStyle: FontStyle.italic,
      ),
      icon: Container(
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
        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
      ),
      subtitle: Text(
        'MASTERPIECE COMPLETE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 3,
        ),
        textAlign: TextAlign.center,
      ),
      accentColor: const Color(0xFFffd700),
      stats: [
        GameResultStat('MOVES', '${state.moveCount}'),
        GameResultStat('TIME', state.formatTime()),
      ],
      statsLayout: GameResultStatsLayout.cards,
      statCardValueFontSize: 24,
      statCardSpacing: 16,
      extraSection: newAchievements.isNotEmpty
          ? _AchievementBadge(achievement: newAchievements.first)
          : null,
      primary: GameResultAction(
        label: 'NEXT LEVEL',
        style: GameResultButtonStyle.depth3d,
        color: const Color(0xFFff5c00),
        borderBottomColor: const Color(0xFF8B3000),
        onTap: () {
          Navigator.of(context).pop();
          uiNotifier.setNewImageLoading(true);
          gameNotifier
              .newImageGame()
              .then((_) {
                uiNotifier.setNewImageLoading(false);
                onShowPreview();
              })
              .catchError((_) {
                uiNotifier.setNewImageLoading(false);
              });
        },
      ),
      secondary: GameResultAction(
        label: 'BACK TO MENU',
        style: GameResultButtonStyle.depth3d,
        color: const Color(0xFF21242b),
        borderBottomColor: Colors.black,
        labelColor: Colors.grey[400],
        onTap: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.home);
        },
      ),
      presentation: GameResultPresentation.dialog,
      animated: false,
      containerBorderRadius: 40,
      contentPadding: const EdgeInsets.all(32),
      constraints: const BoxConstraints(maxWidth: 400),
      scrollable: true,
    ),
  );
}

class _AchievementBadge extends StatelessWidget {
  final String achievement;
  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              achievement,
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
    );
  }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                        context,
                        ref,
                        3,
                        currentSize,
                        onSizeChanged,
                      ),
                      _buildGridSizeOption(
                        context,
                        ref,
                        4,
                        currentSize,
                        onSizeChanged,
                      ),
                      _buildGridSizeOption(
                        context,
                        ref,
                        5,
                        currentSize,
                        onSizeChanged,
                      ),
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
      ref
          .read(puzzleProvider.notifier)
          .changeGridSize(size)
          .then((_) {
            ref.read(puzzleUIProvider.notifier).setLoading(false);
            onSizeChanged();
          })
          .catchError((_) {
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
