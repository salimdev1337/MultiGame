import 'package:flutter/foundation.dart';

/// Provider for managing puzzle game UI state
/// Separated from game logic to follow single responsibility principle
class PuzzleUIProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isNewImageLoading = false;
  bool _showImagePreview = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isNewImageLoading => _isNewImageLoading;
  bool get showImagePreview => _showImagePreview;

  /// Set loading state
  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// Set new image loading state
  void setNewImageLoading(bool value) {
    if (_isNewImageLoading != value) {
      _isNewImageLoading = value;
      notifyListeners();
    }
  }

  /// Set image preview visibility
  void setShowImagePreview(bool value) {
    if (_showImagePreview != value) {
      _showImagePreview = value;
      notifyListeners();
    }
  }

  /// Reset all UI state to initial values
  void reset() {
    _isLoading = true;
    _isNewImageLoading = false;
    _showImagePreview = false;
    notifyListeners();
  }
}
