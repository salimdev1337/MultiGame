import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/snake/providers/snake_ui_provider.dart';

void main() {
  group('SnakeUIProvider', () {
    late SnakeUIProvider provider;

    setUp(() {
      provider = SnakeUIProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should initialize with all dialogs hidden', () {
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.showingPauseDialog, isFalse);
        expect(provider.showingModeSelectionDialog, isFalse);
      });
    });

    group('setShowingGameOverDialog', () {
      test('should update showingGameOverDialog when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingGameOverDialog(true);

        // Assert
        expect(provider.showingGameOverDialog, isTrue);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setShowingGameOverDialog(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingGameOverDialog(true);

        // Assert
        expect(provider.showingGameOverDialog, isTrue);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setShowingGameOverDialog(true);
        expect(provider.showingGameOverDialog, isTrue);
        expect(notificationCount, equals(1));

        provider.setShowingGameOverDialog(false);
        expect(provider.showingGameOverDialog, isFalse);
        expect(notificationCount, equals(2));
      });
    });

    group('setShowingPauseDialog', () {
      test('should update showingPauseDialog when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingPauseDialog(true);

        // Assert
        expect(provider.showingPauseDialog, isTrue);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setShowingPauseDialog(false);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingPauseDialog(false);

        // Assert
        expect(provider.showingPauseDialog, isFalse);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setShowingPauseDialog(true);
        expect(provider.showingPauseDialog, isTrue);
        expect(notificationCount, equals(1));

        provider.setShowingPauseDialog(false);
        expect(provider.showingPauseDialog, isFalse);
        expect(notificationCount, equals(2));
      });
    });

    group('setShowingModeSelectionDialog', () {
      test('should update showingModeSelectionDialog when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingModeSelectionDialog(true);

        // Assert
        expect(provider.showingModeSelectionDialog, isTrue);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setShowingModeSelectionDialog(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingModeSelectionDialog(true);

        // Assert
        expect(provider.showingModeSelectionDialog, isTrue);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setShowingModeSelectionDialog(true);
        expect(provider.showingModeSelectionDialog, isTrue);
        expect(notificationCount, equals(1));

        provider.setShowingModeSelectionDialog(false);
        expect(provider.showingModeSelectionDialog, isFalse);
        expect(notificationCount, equals(2));
      });
    });

    group('reset', () {
      test('should reset all UI state to initial values', () {
        // Arrange - Set all states to non-default values
        provider.setShowingGameOverDialog(true);
        provider.setShowingPauseDialog(true);
        provider.setShowingModeSelectionDialog(true);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();

        // Assert
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.showingPauseDialog, isFalse);
        expect(provider.showingModeSelectionDialog, isFalse);
        expect(notificationCount, equals(1));
      });

      test('should notify listeners even when values are already default', () {
        // Arrange - Provider already at default state
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();

        // Assert
        expect(notificationCount, equals(1));
      });

      test('should allow multiple resets', () {
        // Arrange
        provider.setShowingGameOverDialog(true);
        provider.setShowingPauseDialog(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();
        provider.setShowingModeSelectionDialog(true);
        provider.reset();

        // Assert
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.showingPauseDialog, isFalse);
        expect(provider.showingModeSelectionDialog, isFalse);
        expect(notificationCount, equals(3)); // reset, setDialog, reset
      });
    });

    group('Multiple State Changes', () {
      test('should handle multiple state changes independently', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingGameOverDialog(true);
        provider.setShowingPauseDialog(true);
        provider.setShowingModeSelectionDialog(true);

        // Assert
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.showingPauseDialog, isTrue);
        expect(provider.showingModeSelectionDialog, isTrue);
        expect(notificationCount, equals(3));
      });

      test('should maintain independent state for each property', () {
        // Act
        provider.setShowingGameOverDialog(true);

        // Assert
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.showingPauseDialog, isFalse);
        expect(provider.showingModeSelectionDialog, isFalse);

        // Act
        provider.setShowingPauseDialog(true);

        // Assert
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.showingPauseDialog, isTrue);
        expect(provider.showingModeSelectionDialog, isFalse);

        // Act
        provider.setShowingModeSelectionDialog(true);

        // Assert
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.showingPauseDialog, isTrue);
        expect(provider.showingModeSelectionDialog, isTrue);
      });
    });

    group('Listener Notifications', () {
      test('should notify all registered listeners', () {
        // Arrange
        var listener1Count = 0;
        var listener2Count = 0;
        provider.addListener(() => listener1Count++);
        provider.addListener(() => listener2Count++);

        // Act
        provider.setShowingPauseDialog(true);

        // Assert
        expect(listener1Count, equals(1));
        expect(listener2Count, equals(1));
      });

      test('should handle listener removal correctly', () {
        // Arrange
        var count = 0;
        void listener() => count++;
        provider.addListener(listener);

        // Act
        provider.setShowingGameOverDialog(true);
        expect(count, equals(1));

        provider.removeListener(listener);
        provider.setShowingGameOverDialog(false);

        // Assert
        expect(count, equals(1)); // Should not increment after removal
      });
    });

    group('Edge Cases', () {
      test('should handle rapid successive state changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act - Rapid changes
        provider.setShowingPauseDialog(true);
        provider.setShowingPauseDialog(false);
        provider.setShowingPauseDialog(true);
        provider.setShowingPauseDialog(false);

        // Assert
        expect(provider.showingPauseDialog, isFalse);
        expect(notificationCount, equals(4));
      });

      test('should not break when reset is called multiple times consecutively', () {
        // Arrange
        provider.setShowingGameOverDialog(true);
        provider.setShowingPauseDialog(true);
        provider.setShowingModeSelectionDialog(true);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();
        provider.reset();
        provider.reset();

        // Assert
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.showingPauseDialog, isFalse);
        expect(provider.showingModeSelectionDialog, isFalse);
        expect(notificationCount, equals(3));
      });
    });

    group('Dialog State Scenarios', () {
      test('should allow showing pause dialog while game over dialog is hidden', () {
        // Act
        provider.setShowingPauseDialog(true);

        // Assert
        expect(provider.showingPauseDialog, isTrue);
        expect(provider.showingGameOverDialog, isFalse);
      });

      test('should allow showing game over dialog while pause dialog is hidden', () {
        // Act
        provider.setShowingGameOverDialog(true);

        // Assert
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.showingPauseDialog, isFalse);
      });

      test('should allow both dialogs to be shown simultaneously', () {
        // Act
        provider.setShowingPauseDialog(true);
        provider.setShowingGameOverDialog(true);

        // Assert
        expect(provider.showingPauseDialog, isTrue);
        expect(provider.showingGameOverDialog, isTrue);
      });
    });
  });
}
