import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

/// Placeholder WiFi lobby screen for Rummy.
/// Full host-authoritative WebSocket multiplayer follows the Bomberman/Wordle pattern
/// and can be wired in once the solo mode is stable.
class RummyLobbyPage extends ConsumerWidget {
  const RummyLobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DSColors.rummyFelt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: DSColors.rummyAccent,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Rummy — WiFi Lobby',
          style: DSTypography.titleMedium.copyWith(color: DSColors.rummyAccent),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi, color: DSColors.rummyAccent, size: 64),
              const SizedBox(height: 24),
              Text(
                'Local WiFi multiplayer coming soon.',
                style: DSTypography.bodyLarge.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Up to 4 players on the same network.',
                style: DSTypography.bodySmall
                    .copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DSColors.rummyPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
