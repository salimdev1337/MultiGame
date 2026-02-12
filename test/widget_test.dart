// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multigame/main.dart';
import 'package:multigame/providers/app_init_provider.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Override appInitProvider with a never-completing future so the router
    // stays in the loading/splash state and never calls getIt<OnboardingService>()
    // or creates the 10-second Firebase timeout timer.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appInitProvider.overrideWith((ref) => Completer<void>().future),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app loads with MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Drain the splash AnimationController (2s) — pumpAndSettle stops when
    // no more frames are dirty, but the Future.delayed(800ms) in
    // _startAnimation is a Dart timer (not a frame), so we need a final
    // pump to advance fake-async time past it.
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1)); // drains the 800ms delay
  });
}
