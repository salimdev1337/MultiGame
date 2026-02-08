// Sudoku UI state provider - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/foundation.dart';

class SudokuUIProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isGenerating = false;

  bool _showSettings = false;
  bool _showVictoryDialog = false;
  bool _showHintDialog = false;

  bool _cellAnimating = false;
  String? _animatingCell;

  bool _showErrorShake = false;

  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get showSettings => _showSettings;
  bool get showVictoryDialog => _showVictoryDialog;
  bool get showHintDialog => _showHintDialog;
  bool get cellAnimating => _cellAnimating;
  String? get animatingCell => _animatingCell;
  bool get showErrorShake => _showErrorShake;

  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void setGenerating(bool value) {
    if (_isGenerating != value) {
      _isGenerating = value;
      notifyListeners();
    }
  }

  void setShowSettings(bool value) {
    if (_showSettings != value) {
      _showSettings = value;
      notifyListeners();
    }
  }

  void setShowVictoryDialog(bool value) {
    if (_showVictoryDialog != value) {
      _showVictoryDialog = value;
      notifyListeners();
    }
  }

  void setShowHintDialog(bool value) {
    if (_showHintDialog != value) {
      _showHintDialog = value;
      notifyListeners();
    }
  }

  void triggerCellAnimation(int row, int col) {
    _cellAnimating = true;
    _animatingCell = '${row}_$col';
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 200), () {
      _cellAnimating = false;
      _animatingCell = null;
      notifyListeners();
    });
  }

  void triggerErrorShake() {
    _showErrorShake = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 400), () {
      _showErrorShake = false;
      notifyListeners();
    });
  }

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
