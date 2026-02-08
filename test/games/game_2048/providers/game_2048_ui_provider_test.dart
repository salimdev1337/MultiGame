import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/game_2048/providers/game_2048_ui_provider.dart';

void main() {
  group('Game2048UIProvider', () {
    late Game2048UIProvider provider;

    setUp(() {
      provider = Game2048UIProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should initialize with all dialogs hidden', () {
        expect(provider.showingObjectiveDialog, isFalse);
        expect(provider.showingGameOverDialog, isFalse);
      });

      test('should initialize with isAnimating as false', () {
        expect(provider.isAnimating, isFalse);
      });
    });

    group('setShowingObjectiveDialog', () {
      test('should update showingObjectiveDialog when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingObjectiveDialog(true);

        // Assert
        expect(provider.showingObjectiveDialog, isTrue);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setShowingObjectiveDialog(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingObjectiveDialog(true);

        // Assert
        expect(provider.showingObjectiveDialog, isTrue);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setShowingObjectiveDialog(true);
        expect(provider.showingObjectiveDialog, isTrue);
        expect(notificationCount, equals(1));

        provider.setShowingObjectiveDialog(false);
        expect(provider.showingObjectiveDialog, isFalse);
        expect(notificationCount, equals(2));
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
        provider.setShowingGameOverDialog(false);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingGameOverDialog(false);

        // Assert
        expect(provider.showingGameOverDialog, isFalse);
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

    group('setAnimating', () {
      test('should update isAnimating when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setAnimating(true);

        // Assert
        expect(provider.isAnimating, isTrue);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setAnimating(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setAnimating(true);

        // Assert
        expect(provider.isAnimating, isTrue);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setAnimating(true);
        expect(provider.isAnimating, isTrue);
        expect(notificationCount, equals(1));

        provider.setAnimating(false);
        expect(provider.isAnimating, isFalse);
        expect(notificationCount, equals(2));
      });
    });

    group('reset', () {
      test('should reset all UI state to initial values', () {
        // Arrange - Set all states to non-default values
        provider.setShowingObjectiveDialog(true);
        provider.setShowingGameOverDialog(true);
        provider.setAnimating(true);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();

        // Assert
        expect(provider.showingObjectiveDialog, isFalse);
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.isAnimating, isFalse);
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
        provider.setShowingObjectiveDialog(true);
        provider.setAnimating(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();
        provider.setShowingGameOverDialog(true);
        provider.reset();

        // Assert
        expect(provider.showingObjectiveDialog, isFalse);
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.isAnimating, isFalse);
        expect(notificationCount, equals(3)); // reset, setDialog, reset
      });
    });

    group('Multiple State Changes', () {
      test('should handle multiple state changes independently', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowingObjectiveDialog(true);
        provider.setShowingGameOverDialog(true);
        provider.setAnimating(true);

        // Assert
        expect(provider.showingObjectiveDialog, isTrue);
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.isAnimating, isTrue);
        expect(notificationCount, equals(3));
      });

      test('should maintain independent state for each property', () {
        // Act
        provider.setShowingObjectiveDialog(true);

        // Assert
        expect(provider.showingObjectiveDialog, isTrue);
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.isAnimating, isFalse);

        // Act
        provider.setShowingGameOverDialog(true);

        // Assert
        expect(provider.showingObjectiveDialog, isTrue);
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.isAnimating, isFalse);

        // Act
        provider.setAnimating(true);

        // Assert
        expect(provider.showingObjectiveDialog, isTrue);
        expect(provider.showingGameOverDialog, isTrue);
        expect(provider.isAnimating, isTrue);
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
        provider.setShowingObjectiveDialog(true);

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
        provider.setAnimating(true);
        expect(count, equals(1));

        provider.removeListener(listener);
        provider.setAnimating(false);

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
        provider.setShowingObjectiveDialog(true);
        provider.setShowingObjectiveDialog(false);
        provider.setShowingObjectiveDialog(true);
        provider.setShowingObjectiveDialog(false);

        // Assert
        expect(provider.showingObjectiveDialog, isFalse);
        expect(notificationCount, equals(4));
      });

      test('should not break when reset is called multiple times consecutively', () {
        // Arrange
        provider.setShowingObjectiveDialog(true);
        provider.setShowingGameOverDialog(true);
        provider.setAnimating(true);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();
        provider.reset();
        provider.reset();

        // Assert
        expect(provider.showingObjectiveDialog, isFalse);
        expect(provider.showingGameOverDialog, isFalse);
        expect(provider.isAnimating, isFalse);
        expect(notificationCount, equals(3));
      });
    });
  });
}
