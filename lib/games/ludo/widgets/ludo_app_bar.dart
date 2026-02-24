import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../models/ludo_enums.dart';
import '../providers/ludo_notifier.dart';

class LudoAppBar extends ConsumerWidget {
  const LudoAppBar({
    super.key,
    required this.is3D,
    required this.onToggle3D,
    required this.isDark,
    required this.onToggleDark,
  });

  final bool is3D;
  final VoidCallback onToggle3D;
  final bool isDark;
  final VoidCallback onToggleDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diceMode = ref.watch(ludoProvider.select((s) => s.diceMode));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: DSColors.textPrimary,
                onPressed: () => _confirmExit(context, ref),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ludo',
                      style: DSTypography.titleLarge.copyWith(
                        color: DSColors.ludoPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (diceMode == LudoDiceMode.magic) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'MAGIC',
                          style: DSTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                color: DSColors.textPrimary,
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                onPressed: onToggleDark,
              ),
              IconButton(
                icon: Icon(
                  is3D ? Icons.view_in_ar_rounded : Icons.grid_on_rounded,
                ),
                color: DSColors.textPrimary,
                tooltip: is3D ? '2D View' : '3D View',
                onPressed: onToggle3D,
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                DSColors.ludoPrimary.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Your current game will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(ludoProvider.notifier).goToIdle();
      }
    });
  }
}
