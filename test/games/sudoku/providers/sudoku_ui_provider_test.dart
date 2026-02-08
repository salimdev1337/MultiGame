import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/providers/sudoku_ui_provider.dart';

void main() {
  group('SudokuUIProvider', () {
    late SudokuUIProvider provider;

    setUp(() {
      provider = SudokuUIProvider();
    });

    group('initialization', () {
      test('initializes with correct default values', () {
        expect(provider.isLoading, true);
        expect(provider.isGenerating, false);
        expect(provider.showSettings, false);
        expect(provider.showVictoryDialog, false);
        expect(provider.showHintDialog, false);
        expect(provider.cellAnimating, false);
        expect(provider.animatingCell, isNull);
        expect(provider.showErrorShake, false);
      });
    });

    group('setLoading', () {
      test('updates loading state and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setLoading(false);

        expect(provider.isLoading, false);
        expect(notified, true);
      });

      test('does not notify if value is unchanged', () {
        provider.setLoading(true);

        var notified = false;
        provider.addListener(() => notified = true);

        provider.setLoading(true);

        expect(notified, false);
      });
    });

    group('setGenerating', () {
      test('updates generating state and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setGenerating(true);

        expect(provider.isGenerating, true);
        expect(notified, true);
      });

      test('does not notify if value is unchanged', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setGenerating(false);

        expect(notified, false);
      });
    });

    group('setShowSettings', () {
      test('updates settings visibility and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setShowSettings(true);

        expect(provider.showSettings, true);
        expect(notified, true);
      });
    });

    group('setShowVictoryDialog', () {
      test('updates victory dialog visibility and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setShowVictoryDialog(true);

        expect(provider.showVictoryDialog, true);
        expect(notified, true);
      });
    });

    group('setShowHintDialog', () {
      test('updates hint dialog visibility and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setShowHintDialog(true);

        expect(provider.showHintDialog, true);
        expect(notified, true);
      });
    });

    group('triggerCellAnimation', () {
      test('sets animation state immediately', () {
        provider.triggerCellAnimation(3, 5);

        expect(provider.cellAnimating, true);
        expect(provider.animatingCell, '3_5');
      });

      test('clears animation state after 200ms', () async {
        provider.triggerCellAnimation(4, 6);

        expect(provider.cellAnimating, true);

        await Future.delayed(const Duration(milliseconds: 250));

        expect(provider.cellAnimating, false);
        expect(provider.animatingCell, isNull);
      });
    });

    group('triggerErrorShake', () {
      test('sets error shake state immediately', () {
        provider.triggerErrorShake();

        expect(provider.showErrorShake, true);
      });

      test('clears error shake state after 400ms', () async {
        provider.triggerErrorShake();

        expect(provider.showErrorShake, true);

        await Future.delayed(const Duration(milliseconds: 450));

        expect(provider.showErrorShake, false);
      });
    });

    group('reset', () {
      test('resets all state to defaults', () {
        provider.setLoading(false);
        provider.setGenerating(true);
        provider.setShowSettings(true);
        provider.setShowVictoryDialog(true);
        provider.setShowHintDialog(true);

        provider.reset();

        expect(provider.isLoading, false);
        expect(provider.isGenerating, false);
        expect(provider.showSettings, false);
        expect(provider.showVictoryDialog, false);
        expect(provider.showHintDialog, false);
        expect(provider.cellAnimating, false);
        expect(provider.animatingCell, isNull);
        expect(provider.showErrorShake, false);
      });

      test('notifies listeners on reset', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.reset();

        expect(notified, true);
      });
    });
  });
}
