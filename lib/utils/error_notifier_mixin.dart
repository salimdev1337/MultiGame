import 'package:flutter/material.dart';

/// Mixin that provides automatic error notification handling for widgets
///
/// This mixin listens for errors from providers and automatically shows
/// SnackBar notifications to the user. Use this in State classes that
/// need to display error messages from providers.
///
/// Usage:
/// ```dart
/// class MyWidgetState extends State<MyWidget> with ErrorNotifierMixin {
///   @override
///   void initState() {
///     super.initState();
///     // Listen for errors from a provider
///     listenForErrors(
///       context,
///       () => context.read<MyProvider>().lastError,
///       () => context.read<MyProvider>().clearError(),
///     );
///   }
/// }
/// ```
mixin ErrorNotifierMixin<T extends StatefulWidget> on State<T> {
  /// Show an error SnackBar with the given message
  void showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a success SnackBar with the given message
  void showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
