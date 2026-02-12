import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A widget that displays the current score-save status for a game notifier.
///
/// Pass a [selectStatus] callback to project the relevant fields from any
/// Riverpod provider state:
///
/// ```dart
/// ScoreSaveStatusIndicator(
///   selectStatus: (ref) {
///     final s = ref.watch(game2048Provider);
///     return (isSaving: s.isSavingScore, retry: s.retryAttempt, error: s.lastError);
///   },
/// )
/// ```
typedef ScoreSaveStatus = ({bool isSaving, int retry, String? error});

class ScoreSaveStatusIndicator extends ConsumerWidget {
  final ScoreSaveStatus Function(WidgetRef ref) selectStatus;

  const ScoreSaveStatusIndicator({super.key, required this.selectStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = selectStatus(ref);

    if (!status.isSaving && status.error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: status.error != null
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.isSaving) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              status.retry > 0
                  ? 'Saving score… (Retrying ${status.retry}/3)'
                  : 'Saving score…',
              style: const TextStyle(fontSize: 14),
            ),
          ] else if (status.error != null) ...[
            const Icon(Icons.error_outline, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                status.error!,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
