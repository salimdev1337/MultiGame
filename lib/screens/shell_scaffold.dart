import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/widgets/shared/floating_nav_bar.dart';

/// Root scaffold that holds the tab navigation shell.
/// GoRouter's [StatefulNavigationShell] drives the active branch.
class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScaffold({super.key, required this.navigationShell});

  void _onTabTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hide bottom nav during any game session (any route under /play/<game>)
    final uri = GoRouterState.of(context).uri;
    final segments = uri.pathSegments; // e.g. ['play', '2048'] or ['play', 'sudoku', 'classic']
    final hideBottomNav = segments.length >= 2 && segments.first == 'play';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: hideBottomNav
          ? null
          : FloatingNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (i) => _onTabTapped(context, i),
              items: MultiGameNavItems.items,
            ),
    );
  }
}

/// Extension so any widget can navigate to a game by ID.
extension GameNavigation on BuildContext {
  void goToGame(String gameId) => go('${AppRoutes.play}/$gameId');
}
