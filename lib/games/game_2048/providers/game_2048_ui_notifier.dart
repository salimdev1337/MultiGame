import 'package:flutter_riverpod/flutter_riverpod.dart';

class Game2048UIState {
  final bool showingGameOverDialog;
  final bool isAnimating;

  /// Index of the milestone just unlocked (-1 = none pending).
  /// Set when a new milestone is crossed; cleared after the banner is shown.
  final int milestoneJustUnlocked;

  const Game2048UIState({
    this.showingGameOverDialog = false,
    this.isAnimating = false,
    this.milestoneJustUnlocked = -1,
  });

  Game2048UIState copyWith({
    bool? showingGameOverDialog,
    bool? isAnimating,
    int? milestoneJustUnlocked,
  }) {
    return Game2048UIState(
      showingGameOverDialog:
          showingGameOverDialog ?? this.showingGameOverDialog,
      isAnimating: isAnimating ?? this.isAnimating,
      milestoneJustUnlocked:
          milestoneJustUnlocked ?? this.milestoneJustUnlocked,
    );
  }
}

class Game2048UINotifier extends AutoDisposeNotifier<Game2048UIState> {
  @override
  Game2048UIState build() => const Game2048UIState();

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

  void notifyMilestoneUnlocked(int milestoneIndex) {
    state = state.copyWith(milestoneJustUnlocked: milestoneIndex);
  }

  void clearMilestone() {
    if (state.milestoneJustUnlocked >= 0) {
      state = state.copyWith(milestoneJustUnlocked: -1);
    }
  }

  void reset() => state = const Game2048UIState();
}

final game2048UIProvider =
    NotifierProvider.autoDispose<Game2048UINotifier, Game2048UIState>(
        Game2048UINotifier.new);
