import 'package:flutter/foundation.dart';

/// Provider for Sudoku UI state (presentation layer only).
///
/// This provider manages UI-specific state that is separate from game logic:
/// - Loading and generation states
/// - Dialog visibility
/// - Animation states
/// - Error feedback states
///
/// Following the MultiGame architecture pattern of separating:
/// - Game state logic → SudokuProvider
/// - UI presentation state → SudokuUIProvider
class SudokuUIProvider extends ChangeNotifier {
  // Loading states
  bool _isLoading = true;
  bool _isGenerating = false;

  // Dialog states
  bool _showSettings = false;
  bool _showVictoryDialog = false;
  bool _showHintDialog = false;

  // Animation states
  bool _cellAnimating = false;
  String? _animatingCell; // Format: "row_col"

  // Error feedback
  bool _showErrorShake = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get showSettings => _showSettings;
  bool get showVictoryDialog => _showVictoryDialog;
  bool get showHintDialog => _showHintDialog;
  bool get cellAnimating => _cellAnimating;
  String? get animatingCell => _animatingCell;
  bool get showErrorShake => _showErrorShake;

  /// Sets the loading state
  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// Sets the generating state (for puzzle generation)
  void setGenerating(bool value) {
    if (_isGenerating != value) {
      _isGenerating = value;
      notifyListeners();
    }
  }

  /// Shows or hides the settings dialog
  void setShowSettings(bool value) {
    if (_showSettings != value) {
      _showSettings = value;
      notifyListeners();
    }
  }

  /// Shows or hides the victory dialog
  void setShowVictoryDialog(bool value) {
    if (_showVictoryDialog != value) {
      _showVictoryDialog = value;
      notifyListeners();
    }
  }

  /// Shows or hides the hint dialog
  void setShowHintDialog(bool value) {
    if (_showHintDialog != value) {
      _showHintDialog = value;
      notifyListeners();
    }
  }

  /// Triggers a cell animation at the specified position
  ///
  /// Used for visual feedback when placing numbers
  void triggerCellAnimation(int row, int col) {
    _cellAnimating = true;
    _animatingCell = '${row}_$col';
    notifyListeners();

    // Clear animation after duration
    Future.delayed(const Duration(milliseconds: 200), () {
      _cellAnimating = false;
      _animatingCell = null;
      notifyListeners();
    });
  }

  /// Triggers an error shake animation
  ///
  /// Used for visual feedback when player makes invalid move
  void triggerErrorShake() {
    _showErrorShake = true;
    notifyListeners();

    // Clear shake after animation completes
    Future.delayed(const Duration(milliseconds: 400), () {
      _showErrorShake = false;
      notifyListeners();
    });
  }

  /// Resets all UI state to initial values
  void reset() {
    _isLoading = false;
    _isGenerating = false;
    _showSettings = false;
    _showVictoryDialog = false;
    _showHintDialog = false;
    _cellAnimating = false;
    _animatingCell = null;
    _showErrorShake = false;
    notifyListeners();
  }
}
