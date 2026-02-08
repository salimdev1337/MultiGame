import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multigame/providers/mixins/game_stats_mixin.dart';

/// A widget that displays the current score save status with retry information
///
/// This widget watches a provider that uses [GameStatsMixin] and displays:
/// - "Saving score..." when a save is in progress
/// - "Saving score... (Retrying X/3)" when retrying after failure
/// - An error message if all retries fail
///
/// Usage:
/// ```dart
/// ScoreSaveStatusIndicator<YourGameProvider>()
/// ```
class ScoreSaveStatusIndicator<T extends ChangeNotifier> extends StatelessWidget {
  const ScoreSaveStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a bit of a workaround since we can't directly access the mixin
    // We need to cast the provider to access GameStatsMixin properties
    final provider = context.watch<T>();

    // Try to get the mixin properties through dynamic access
    // This works because the provider has the mixin applied
    final isSaving = _getProperty<bool>(provider, 'isSavingScore') ?? false;
    final retryAttempt = _getProperty<int>(provider, 'retryAttempt') ?? 0;
    final lastError = _getProperty<String?>(provider, 'lastError');

    if (!isSaving && lastError == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: lastError != null
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              retryAttempt > 0
                  ? 'Saving score... (Retrying $retryAttempt/3)'
                  : 'Saving score...',
              style: const TextStyle(fontSize: 14),
            ),
          ] else if (lastError != null) ...[
            const Icon(Icons.error_outline, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                lastError,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper method to safely get a property from the provider
  /// Returns null if the property doesn't exist
  R? _getProperty<R>(dynamic object, String propertyName) {
    try {
      // Use reflection-like approach to get property value
      // This works because the mixin adds these as public getters
      switch (propertyName) {
        case 'isSavingScore':
          return (object as dynamic).isSavingScore as R?;
        case 'retryAttempt':
          return (object as dynamic).retryAttempt as R?;
        case 'lastError':
          return (object as dynamic).lastError as R?;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }
}
