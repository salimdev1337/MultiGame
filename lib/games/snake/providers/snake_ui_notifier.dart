import 'package:flutter_riverpod/flutter_riverpod.dart';

class SnakeUIState {
  final bool showingGameOverDialog;
  final bool showingPauseDialog;
  final bool showingModeSelectionDialog;

  const SnakeUIState({
    this.showingGameOverDialog = false,
    this.showingPauseDialog = false,
    this.showingModeSelectionDialog = false,
  });

  SnakeUIState copyWith({
    bool? showingGameOverDialog,
    bool? showingPauseDialog,
    bool? showingModeSelectionDialog,
  }) {
    return SnakeUIState(
      showingGameOverDialog:
          showingGameOverDialog ?? this.showingGameOverDialog,
      showingPauseDialog: showingPauseDialog ?? this.showingPauseDialog,
      showingModeSelectionDialog:
          showingModeSelectionDialog ?? this.showingModeSelectionDialog,
    );
  }
}

class SnakeUINotifier extends AutoDisposeNotifier<SnakeUIState> {
  @override
  SnakeUIState build() => const SnakeUIState();

  void setShowingGameOverDialog(bool v) {
    if (state.showingGameOverDialog != v) {
      state = state.copyWith(showingGameOverDialog: v);
    }
  }

  void setShowingPauseDialog(bool v) {
    if (state.showingPauseDialog != v) {
      state = state.copyWith(showingPauseDialog: v);
    }
  }

  void setShowingModeSelectionDialog(bool v) {
    if (state.showingModeSelectionDialog != v) {
      state = state.copyWith(showingModeSelectionDialog: v);
    }
  }

  void reset() => state = const SnakeUIState();
}

final snakeUIProvider =
    NotifierProvider.autoDispose<SnakeUINotifier, SnakeUIState>(
      SnakeUINotifier.new,
    );
