import 'package:flutter_riverpod/flutter_riverpod.dart';

class Game2048UIState {
  final bool showingObjectiveDialog;
  final bool showingGameOverDialog;
  final bool isAnimating;

  const Game2048UIState({
    this.showingObjectiveDialog = false,
    this.showingGameOverDialog = false,
    this.isAnimating = false,
  });

  Game2048UIState copyWith({
    bool? showingObjectiveDialog,
    bool? showingGameOverDialog,
    bool? isAnimating,
  }) {
    return Game2048UIState(
      showingObjectiveDialog:
          showingObjectiveDialog ?? this.showingObjectiveDialog,
      showingGameOverDialog:
          showingGameOverDialog ?? this.showingGameOverDialog,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

class Game2048UINotifier extends AutoDisposeNotifier<Game2048UIState> {
  @override
  Game2048UIState build() => const Game2048UIState();

  void setShowingObjectiveDialog(bool value) {
    if (state.showingObjectiveDialog != value) {
      state = state.copyWith(showingObjectiveDialog: value);
    }
  }

  void setShowingGameOverDialog(bool value) {
    if (state.showingGameOverDialog != value) {
      state = state.copyWith(showingGameOverDialog: value);
    }
  }

  void setAnimating(bool value) {
    if (state.isAnimating != value) {
      state = state.copyWith(isAnimating: value);
    }
  }

  void reset() => state = const Game2048UIState();
}

final game2048UIProvider =
    NotifierProvider.autoDispose<Game2048UINotifier, Game2048UIState>(
        Game2048UINotifier.new);
