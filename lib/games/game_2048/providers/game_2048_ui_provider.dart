import 'package:flutter/foundation.dart';

/// Provider for managing 2048 game UI state
/// Separated from game logic to follow single responsibility principle
class Game2048UIProvider extends ChangeNotifier {
  bool _showingObjectiveDialog = false;
  bool _showingGameOverDialog = false;
  bool _isAnimating = false;

  // Getters
  bool get showingObjectiveDialog => _showingObjectiveDialog;
  bool get showingGameOverDialog => _showingGameOverDialog;
  bool get isAnimating => _isAnimating;

  /// Set objective dialog visibility
  void setShowingObjectiveDialog(bool value) {
    if (_showingObjectiveDialog != value) {
      _showingObjectiveDialog = value;
      notifyListeners();
    }
  }

  /// Set game over dialog visibility
  void setShowingGameOverDialog(bool value) {
    if (_showingGameOverDialog != value) {
      _showingGameOverDialog = value;
      notifyListeners();
    }
  }

  /// Set animation state
  void setAnimating(bool value) {
    if (_isAnimating != value) {
      _isAnimating = value;
      notifyListeners();
    }
  }

  /// Reset all UI state to initial values
  void reset() {
    _showingObjectiveDialog = false;
    _showingGameOverDialog = false;
    _isAnimating = false;
    notifyListeners();
  }
}
