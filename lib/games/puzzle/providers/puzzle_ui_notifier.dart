import 'package:flutter_riverpod/flutter_riverpod.dart';

class PuzzleUIState {
  final bool isLoading;
  final bool isNewImageLoading;
  final bool showImagePreview;

  const PuzzleUIState({
    this.isLoading = true,
    this.isNewImageLoading = false,
    this.showImagePreview = false,
  });

  PuzzleUIState copyWith({
    bool? isLoading,
    bool? isNewImageLoading,
    bool? showImagePreview,
  }) {
    return PuzzleUIState(
      isLoading: isLoading ?? this.isLoading,
      isNewImageLoading: isNewImageLoading ?? this.isNewImageLoading,
      showImagePreview: showImagePreview ?? this.showImagePreview,
    );
  }
}

class PuzzleUINotifier extends AutoDisposeNotifier<PuzzleUIState> {
  @override
  PuzzleUIState build() => const PuzzleUIState();

  void setLoading(bool v) {
    if (state.isLoading != v) { state = state.copyWith(isLoading: v); }
  }

  void setNewImageLoading(bool v) {
    if (state.isNewImageLoading != v) {
      state = state.copyWith(isNewImageLoading: v);
    }
  }

  void setShowImagePreview(bool v) {
    if (state.showImagePreview != v) {
      state = state.copyWith(showImagePreview: v);
    }
  }

  void reset() => state = const PuzzleUIState();
}

final puzzleUIProvider =
    NotifierProvider.autoDispose<PuzzleUINotifier, PuzzleUIState>(
        PuzzleUINotifier.new);
