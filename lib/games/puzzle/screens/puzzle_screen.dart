import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/puzzle/providers/puzzle_notifier.dart';
import 'package:multigame/games/puzzle/providers/puzzle_ui_notifier.dart';
import 'package:multigame/games/puzzle/screens/puzzle_controls.dart';
import 'package:multigame/games/puzzle/screens/puzzle_dialogs.dart';
import 'package:multigame/games/puzzle/screens/puzzle_game_board.dart';
import 'package:multigame/games/puzzle/screens/puzzle_image_preview.dart';

class PuzzlePage extends ConsumerStatefulWidget {
  const PuzzlePage({super.key});

  @override
  ConsumerState<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends ConsumerState<PuzzlePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _previewAnimationController;
  late Animation<double> _previewAnimation;
  final GlobalKey _hintButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _previewAnimation = CurvedAnimation(
      parent: _previewAnimationController,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameNotifier = ref.read(puzzleProvider.notifier);
      final uiNotifier = ref.read(puzzleUIProvider.notifier);

      uiNotifier.setLoading(true);
      gameNotifier
          .initializeGame()
          .then((_) {
            uiNotifier.setLoading(false);
            if (mounted) _showImagePreviewAnimation();
          })
          .catchError((e) {
            uiNotifier.setLoading(false);
          });
    });
  }

  @override
  void dispose() {
    _previewAnimationController.dispose();
    super.dispose();
  }

  void _showImagePreviewAnimation() {
    final uiNotifier = ref.read(puzzleUIProvider.notifier);
    uiNotifier.setShowImagePreview(true);
    _previewAnimationController.reset();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _previewAnimationController.forward().then((_) {
          if (mounted) uiNotifier.setShowImagePreview(false);
        });
      }
    });
  }

  void _movePiece(int position) {
    final wasSolved = ref.read(puzzleProvider).game?.isSolved ?? false;
    if (ref.read(puzzleProvider.notifier).movePiece(position)) {
      if (!wasSolved && ref.read(puzzleProvider).game?.isSolved == true) {
        showPuzzleWinDialog(
          context: context,
          ref: ref,
          onShowPreview: _showImagePreviewAnimation,
        );
      }
    }
  }

  void _handleDrop(int fromIndex, int toIndex) {
    final game = ref.read(puzzleProvider).game;
    if (game == null) return;

    if (game.pieces[toIndex].isEmpty) {
      final wasSolved = game.isSolved;
      if (ref.read(puzzleProvider.notifier).movePiece(fromIndex)) {
        if (!wasSolved && ref.read(puzzleProvider).game?.isSolved == true) {
          showPuzzleWinDialog(
            context: context,
            ref: ref,
            onShowPreview: _showImagePreviewAnimation,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(puzzleUIProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                PuzzleTopAppBar(
                  onSettingsTap: () => showPuzzleGridSizeDialog(
                    context,
                    ref,
                    _showImagePreviewAnimation,
                  ),
                ),
                Expanded(
                  child: uiState.isLoading
                      ? const PuzzleLoadingScreen()
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                PuzzleStatsSection(
                                  hintButtonKey: _hintButtonKey,
                                  onHintTap: () {
                                    final game = ref.read(puzzleProvider).game;
                                    if (game == null) return;
                                    final imageUrl = game.pieces
                                        .firstWhere((p) => p.imageUrl != null)
                                        .imageUrl;
                                    if (imageUrl != null) {
                                      showPuzzleHintDialog(context, imageUrl);
                                    }
                                  },
                                ),
                                const SizedBox(height: 32),
                                PuzzleGameBoard(
                                  onPieceMoved: _movePiece,
                                  onDrop: _handleDrop,
                                ),
                                const SizedBox(height: 24),
                                PuzzleFooterControls(
                                  onReset: () {
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);
                                  },
                                  onPlayAgain: () {
                                    ref
                                        .read(puzzleUIProvider.notifier)
                                        .setNewImageLoading(true);
                                    ref
                                        .read(puzzleProvider.notifier)
                                        .newImageGame()
                                        .then((_) {
                                          ref
                                              .read(puzzleUIProvider.notifier)
                                              .setNewImageLoading(false);
                                          if (mounted) {
                                            _showImagePreviewAnimation();
                                          }
                                        })
                                        .catchError((_) {
                                          ref
                                              .read(puzzleUIProvider.notifier)
                                              .setNewImageLoading(false);
                                        });
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
            if (uiState.showImagePreview)
              PuzzleImagePreviewOverlay(
                animation: _previewAnimation,
                hintButtonKey: _hintButtonKey,
              ),
          ],
        ),
      ),
    );
  }
}
