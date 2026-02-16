// Tests for the router redirect chain logic defined in app_router.dart.
//
// Rather than pumping the full MyApp (which drags in Firebase, Crashlytics,
// and animation-heavy screens), each test creates a lightweight GoRouter that
// reproduces the redirect logic verbatim with injected state.  This makes the
// tests fast, hermetic, and easy to read.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:multigame/config/app_router.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

/// Creates a [GoRouter] whose redirect chain mirrors the one in
/// [buildAppRouter] but with all async dependencies injected as plain
/// synchronous values so we don't need Firebase or GetIt.
GoRouter _buildRouter({
  required bool appReady, // false → isLoading
  bool appError = false, // true → hasError
  bool onboarded = false,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) async {
      // Mirror: if (appAsync.isLoading) return AppRoutes.splash;
      if (!appReady) {
        return AppRoutes.splash;
      }
      // Mirror: if (appAsync.hasError) return AppRoutes.splash;
      if (appError) {
        return AppRoutes.splash;
      }

      final path = state.uri.toString();

      // Mirror: if (!hasOnboarded) → onboarding gate
      if (!onboarded) {
        return path == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // Mirror: onboarded — push splash/onboarding to home
      if (path == AppRoutes.splash || path == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const _Page('splash')),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const _Page('onboarding'),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const _Page('home'),
        routes: [
          GoRoute(
            path: 'play',
            builder: (_, _) => const _Page('play'),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (_, _) => const _Page('leaderboard'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const _Page('profile'),
      ),
    ],
  );
}

/// Pumps a [MaterialApp.router] and waits for the redirect to resolve.
/// Returns the router so callers can inspect [GoRouter.routerDelegate].
Future<GoRouter> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  // First pump: triggers the async redirect future.
  // Second pump: renders the redirected destination.
  await tester.pump();
  await tester.pump();
  return router;
}

/// Returns the current location directly from the [GoRouter] instance.
String _location(GoRouter router) {
  return router.routerDelegate.currentConfiguration.uri.toString();
}

// Minimal no-op screen widget used in test routes.
class _Page extends StatelessWidget {
  const _Page(this.name);
  final String name;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(name)));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AppRouter redirect chains — loading / error state', () {
    testWidgets('stays on /splash while appInitProvider is loading',
        (tester) async {
      final r = await _pump(tester, _buildRouter(appReady: false));
      expect(_location(r), AppRoutes.splash);
    });

    testWidgets('stays on /splash when appInitProvider has an error',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(appReady: true, appError: true),
      );
      expect(_location(r), AppRoutes.splash);
    });
  });

  group('AppRouter redirect chains — onboarding gate (not onboarded)', () {
    testWidgets('redirects /splash → /onboarding when not onboarded',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(appReady: true, onboarded: false),
      );
      expect(_location(r), AppRoutes.onboarding);
    });

    testWidgets('no redirect when already on /onboarding and not onboarded',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(
          appReady: true,
          onboarded: false,
          initialLocation: AppRoutes.onboarding,
        ),
      );
      expect(_location(r), AppRoutes.onboarding);
    });

    testWidgets(
        'redirects /profile → /onboarding when not onboarded (any route)',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(
          appReady: true,
          onboarded: false,
          initialLocation: AppRoutes.profile,
        ),
      );
      expect(_location(r), AppRoutes.onboarding);
    });
  });

  group('AppRouter redirect chains — onboarded', () {
    testWidgets('redirects /splash → /home when onboarding complete',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(appReady: true, onboarded: true),
      );
      expect(_location(r), AppRoutes.home);
    });

    testWidgets('redirects /onboarding → /home when onboarding complete',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(
          appReady: true,
          onboarded: true,
          initialLocation: AppRoutes.onboarding,
        ),
      );
      expect(_location(r), AppRoutes.home);
    });

    testWidgets('no redirect for /home when onboarding complete',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(
          appReady: true,
          onboarded: true,
          initialLocation: AppRoutes.home,
        ),
      );
      expect(_location(r), AppRoutes.home);
    });

    testWidgets('no redirect for /leaderboard when onboarding complete',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(
          appReady: true,
          onboarded: true,
          initialLocation: AppRoutes.leaderboard,
        ),
      );
      expect(_location(r), AppRoutes.leaderboard);
    });

    testWidgets('no redirect for /profile when onboarding complete',
        (tester) async {
      final r = await _pump(
        tester,
        _buildRouter(
          appReady: true,
          onboarded: true,
          initialLocation: AppRoutes.profile,
        ),
      );
      expect(_location(r), AppRoutes.profile);
    });
  });
}
