import 'package:flutter/foundation.dart';

/// Provider for managing Snake game UI state
/// Separated from game logic to follow single responsibility principle
class SnakeUIProvider extends ChangeNotifier {
  bool _showingGameOverDialog = false;
  bool _showingPauseDialog = false;
  bool _showingModeSelectionDialog = false;

  // Getters
  bool get showingGameOverDialog => _showingGameOverDialog;
  bool get showingPauseDialog => _showingPauseDialog;
  bool get showingModeSelectionDialog => _showingModeSelectionDialog;

  /// Set game over dialog visibility
  void setShowingGameOverDialog(bool value) {
    if (_showingGameOverDialog != value) {
      _showingGameOverDialog = value;
      notifyListeners();
    }
  }

  /// Set pause dialog visibility
  void setShowingPauseDialog(bool value) {
    if (_showingPauseDialog != value) {
      _showingPauseDialog = value;
      notifyListeners();
    }
  }

  /// Set mode selection dialog visibility
  void setShowingModeSelectionDialog(bool value) {
    if (_showingModeSelectionDialog != value) {
      _showingModeSelectionDialog = value;
      notifyListeners();
    }
  }

  /// Reset all UI state to initial values
  void reset() {
    _showingGameOverDialog = false;
    _showingPauseDialog = false;
    _showingModeSelectionDialog = false;
    notifyListeners();
  }
}
