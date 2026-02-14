import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multigame/design_system/design_system.dart';

/// Focus management utilities for keyboard navigation and screen readers.
///
/// Provides:
/// - Logical focus order management
/// - Visual focus indicators
/// - Arrow-key navigation for grid-based games (Sudoku)
/// - Tab / Shift+Tab traversal helpers
class AccessibleFocusManager {
  AccessibleFocusManager._();

  // ── Focus Order ─────────────────────────────────────────────────────────────

  /// Traverse to the next focusable node in the scope.
  static void moveFocusNext(BuildContext context) {
    Focus.of(context).nextFocus();
  }

  /// Traverse to the previous focusable node in the scope.
  static void moveFocusPrevious(BuildContext context) {
    Focus.of(context).previousFocus();
  }

  /// Request focus on [node], scrolling it into view if needed.
  static void requestFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  /// Move focus to first child of the nearest [FocusScope].
  static void moveFocusToFirst(BuildContext context) {
    final scope = FocusScope.of(context);
    if (scope.focusedChild != null) {
      scope.focusedChild!.unfocus();
    }
    scope.nextFocus();
  }

  // ── Focus Indicator Widget ───────────────────────────────────────────────────

  /// Wraps [child] with a visible focus ring when [focusNode] has focus.
  ///
  /// The ring uses [DSAccessibility.focusBorderWidth] and [DSColors.primary].
  static Widget buildFocusIndicator({
    required Widget child,
    required FocusNode focusNode,
    BorderRadius? borderRadius,
  }) {
    return _FocusIndicatorWidget(
      focusNode: focusNode,
      borderRadius: borderRadius ?? DSSpacing.borderRadiusMD,
      child: child,
    );
  }
}

// ── Focus Indicator Implementation ───────────────────────────────────────────

class _FocusIndicatorWidget extends StatefulWidget {
  const _FocusIndicatorWidget({
    required this.child,
    required this.focusNode,
    required this.borderRadius,
  });

  final Widget child;
  final FocusNode focusNode;
  final BorderRadius borderRadius;

  @override
  State<_FocusIndicatorWidget> createState() => _FocusIndicatorWidgetState();
}

class _FocusIndicatorWidgetState extends State<_FocusIndicatorWidget> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DSAnimations.fast,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: _hasFocus
            ? Border.all(
                color: DSColors.primary,
                width: DSAccessibility.focusBorderWidth,
              )
            : null,
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: DSColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: widget.child,
    );
  }
}

// ── Grid Navigation Handler ───────────────────────────────────────────────────

/// Handles arrow-key navigation for 2-D grids (e.g. Sudoku 9×9).
///
/// Wrap the grid widget with a [Focus] and pass [onKey] to its [onKeyEvent]:
/// ```dart
/// Focus(
///   onKeyEvent: (node, event) =>
///       GridNavigationHandler.onKeyEvent(event, row, col, 9, 9, onMove),
///   child: SudokuGrid(...),
/// )
/// ```
class GridNavigationHandler {
  GridNavigationHandler._();

  /// Handles arrow-key presses and calls [onMove] with the new (row, col).
  ///
  /// Returns [KeyEventResult.handled] when an arrow key is consumed,
  /// [KeyEventResult.ignored] otherwise.
  static KeyEventResult onKeyEvent(
    KeyEvent event,
    int currentRow,
    int currentCol,
    int rowCount,
    int colCount,
    void Function(int row, int col) onMove,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    int newRow = currentRow;
    int newCol = currentCol;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newRow = (currentRow - 1 + rowCount) % rowCount;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newRow = (currentRow + 1) % rowCount;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      newCol = (currentCol - 1 + colCount) % colCount;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      newCol = (currentCol + 1) % colCount;
    } else {
      return KeyEventResult.ignored;
    }

    onMove(newRow, newCol);
    return KeyEventResult.handled;
  }
}

// ── Keyboard Shortcuts Overlay ────────────────────────────────────────────────

/// Wraps a widget to intercept Tab / Shift+Tab for sequential focus traversal.
///
/// This is redundant on most platforms (Flutter handles Tab natively) but
/// useful in embedded WebViews or unusual host environments.
class KeyboardFocusTraversalWrapper extends StatelessWidget {
  const KeyboardFocusTraversalWrapper({
    super.key,
    required this.child,
    this.focusScopeNode,
  });

  final Widget child;
  final FocusScopeNode? focusScopeNode;

  @override
  Widget build(BuildContext context) {
    return FocusScope(node: focusScopeNode, child: child);
  }
}
