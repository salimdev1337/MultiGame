import 'dart:async';

/// Debouncer utility for rate-limiting function calls
///
/// Delays execution of a function until a specified duration has passed
/// without any new calls. Useful for reducing Firestore writes, API calls,
/// or other expensive operations.
///
/// Example:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(seconds: 2));
///
/// // This will only execute once after 2 seconds of inactivity
/// debouncer.run(() {
///   print('Executed after 2 seconds of no new calls');
/// });
/// ```
class Debouncer {
  /// Duration to wait before executing the function
  final Duration delay;

  /// Internal timer for debouncing
  Timer? _timer;

  Debouncer({required this.delay});

  /// Run function after delay, canceling any previous pending calls
  ///
  /// If this method is called multiple times in rapid succession,
  /// only the last call's action will execute after the delay.
  void run(void Function() action) {
    // Cancel any existing timer
    _timer?.cancel();

    // Start a new timer
    _timer = Timer(delay, action);
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose and cancel any pending action
  ///
  /// Call this in the dispose method of your widget or provider
  void dispose() {
    cancel();
  }

  /// Check if there's a pending action
  bool get isPending => _timer != null && _timer!.isActive;
}
