import 'package:flutter_riverpod/flutter_riverpod.dart';

class SudokuUIState {
  final bool isLoading;
  final bool isGenerating;
  final bool showSettings;
  final bool showVictoryDialog;
  final bool showHintDialog;
  final bool cellAnimating;
  final String? animatingCell;
  final bool showErrorShake;

  const SudokuUIState({
    this.isLoading = true,
    this.isGenerating = false,
    this.showSettings = false,
    this.showVictoryDialog = false,
    this.showHintDialog = false,
    this.cellAnimating = false,
    this.animatingCell,
    this.showErrorShake = false,
  });

  SudokuUIState copyWith({
    bool? isLoading,
    bool? isGenerating,
    bool? showSettings,
    bool? showVictoryDialog,
    bool? showHintDialog,
    bool? cellAnimating,
    String? animatingCell,
    bool clearAnimatingCell = false,
    bool? showErrorShake,
  }) {
    return SudokuUIState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      showSettings: showSettings ?? this.showSettings,
      showVictoryDialog: showVictoryDialog ?? this.showVictoryDialog,
      showHintDialog: showHintDialog ?? this.showHintDialog,
      cellAnimating: cellAnimating ?? this.cellAnimating,
      animatingCell: clearAnimatingCell
          ? null
          : (animatingCell ?? this.animatingCell),
      showErrorShake: showErrorShake ?? this.showErrorShake,
    );
  }
}

class SudokuUINotifier extends AutoDisposeNotifier<SudokuUIState> {
  @override
  SudokuUIState build() => const SudokuUIState();

  void setLoading(bool v) {
    if (state.isLoading != v) {
      state = state.copyWith(isLoading: v);
    }
  }

  void setGenerating(bool v) {
    if (state.isGenerating != v) {
      state = state.copyWith(isGenerating: v);
    }
  }

  void setShowSettings(bool v) {
    if (state.showSettings != v) {
      state = state.copyWith(showSettings: v);
    }
  }

  void setShowVictoryDialog(bool v) {
    if (state.showVictoryDialog != v) {
      state = state.copyWith(showVictoryDialog: v);
    }
  }

  void setShowHintDialog(bool v) {
    if (state.showHintDialog != v) {
      state = state.copyWith(showHintDialog: v);
    }
  }

  void triggerCellAnimation(int row, int col) {
    state = state.copyWith(cellAnimating: true, animatingCell: '${row}_$col');
    Future.delayed(const Duration(milliseconds: 200), () {
      state = state.copyWith(cellAnimating: false, clearAnimatingCell: true);
    });
  }

  void triggerErrorShake() {
    state = state.copyWith(showErrorShake: true);
    Future.delayed(const Duration(milliseconds: 400), () {
      state = state.copyWith(showErrorShake: false);
    });
  }

  void reset() => state = const SudokuUIState(isLoading: false);
}

final sudokuUIProvider =
    NotifierProvider.autoDispose<SudokuUINotifier, SudokuUIState>(
      SudokuUINotifier.new,
    );
