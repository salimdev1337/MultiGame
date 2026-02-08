import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/puzzle/providers/puzzle_ui_provider.dart';

void main() {
  group('PuzzleUIProvider', () {
    late PuzzleUIProvider provider;

    setUp(() {
      provider = PuzzleUIProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should initialize with isLoading as true', () {
        expect(provider.isLoading, isTrue);
      });

      test('should initialize with isNewImageLoading as false', () {
        expect(provider.isNewImageLoading, isFalse);
      });

      test('should initialize with showImagePreview as false', () {
        expect(provider.showImagePreview, isFalse);
      });
    });

    group('setLoading', () {
      test('should update isLoading when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setLoading(false);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setLoading(false);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setLoading(false);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setLoading(false);
        expect(provider.isLoading, isFalse);
        expect(notificationCount, equals(1));

        provider.setLoading(true);
        expect(provider.isLoading, isTrue);
        expect(notificationCount, equals(2));
      });

      test('should handle initial state correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act - Setting to same initial value
        provider.setLoading(true);

        // Assert - Should not notify since value is the same
        expect(provider.isLoading, isTrue);
        expect(notificationCount, equals(0));
      });
    });

    group('setNewImageLoading', () {
      test('should update isNewImageLoading when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setNewImageLoading(true);

        // Assert
        expect(provider.isNewImageLoading, isTrue);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setNewImageLoading(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setNewImageLoading(true);

        // Assert
        expect(provider.isNewImageLoading, isTrue);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setNewImageLoading(true);
        expect(provider.isNewImageLoading, isTrue);
        expect(notificationCount, equals(1));

        provider.setNewImageLoading(false);
        expect(provider.isNewImageLoading, isFalse);
        expect(notificationCount, equals(2));
      });
    });

    group('setShowImagePreview', () {
      test('should update showImagePreview when value changes', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowImagePreview(true);

        // Assert
        expect(provider.showImagePreview, isTrue);
        expect(notificationCount, equals(1));
      });

      test('should not notify listeners when setting same value', () {
        // Arrange
        provider.setShowImagePreview(false);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setShowImagePreview(false);

        // Assert
        expect(provider.showImagePreview, isFalse);
        expect(notificationCount, equals(0));
      });

      test('should toggle value correctly', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act & Assert
        provider.setShowImagePreview(true);
        expect(provider.showImagePreview, isTrue);
        expect(notificationCount, equals(1));

        provider.setShowImagePreview(false);
        expect(provider.showImagePreview, isFalse);
        expect(notificationCount, equals(2));
      });
    });

    group('reset', () {
      test('should reset all UI state to initial values', () {
        // Arrange - Set all states to non-default values
        provider.setLoading(false);
        provider.setNewImageLoading(true);
        provider.setShowImagePreview(true);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();

        // Assert
        expect(provider.isLoading, isTrue);
        expect(provider.isNewImageLoading, isFalse);
        expect(provider.showImagePreview, isFalse);
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
        provider.setLoading(false);
        provider.setNewImageLoading(true);
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();
        provider.setShowImagePreview(true);
        provider.reset();

        // Assert
        expect(provider.isLoading, isTrue);
        expect(provider.isNewImageLoading, isFalse);
        expect(provider.showImagePreview, isFalse);
        expect(notificationCount, equals(3)); // reset, setPreview, reset
      });

      test('should reset from partially modified state', () {
        // Arrange - Only modify some values
        provider.setLoading(false);
        provider.setShowImagePreview(true);
        // isNewImageLoading stays false

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();

        // Assert
        expect(provider.isLoading, isTrue);
        expect(provider.isNewImageLoading, isFalse);
        expect(provider.showImagePreview, isFalse);
        expect(notificationCount, equals(1));
      });
    });

    group('Multiple State Changes', () {
      test('should handle multiple state changes independently', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.setLoading(false);
        provider.setNewImageLoading(true);
        provider.setShowImagePreview(true);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.isNewImageLoading, isTrue);
        expect(provider.showImagePreview, isTrue);
        expect(notificationCount, equals(3));
      });

      test('should maintain independent state for each property', () {
        // Act
        provider.setLoading(false);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.isNewImageLoading, isFalse);
        expect(provider.showImagePreview, isFalse);

        // Act
        provider.setNewImageLoading(true);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.isNewImageLoading, isTrue);
        expect(provider.showImagePreview, isFalse);

        // Act
        provider.setShowImagePreview(true);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.isNewImageLoading, isTrue);
        expect(provider.showImagePreview, isTrue);
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
        provider.setLoading(false);

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
        provider.setNewImageLoading(true);
        expect(count, equals(1));

        provider.removeListener(listener);
        provider.setNewImageLoading(false);

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
        provider.setLoading(false);
        provider.setLoading(true);
        provider.setLoading(false);
        provider.setLoading(true);

        // Assert
        expect(provider.isLoading, isTrue);
        expect(notificationCount, equals(4));
      });

      test('should not break when reset is called multiple times consecutively', () {
        // Arrange
        provider.setLoading(false);
        provider.setNewImageLoading(true);
        provider.setShowImagePreview(true);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        provider.reset();
        provider.reset();
        provider.reset();

        // Assert
        expect(provider.isLoading, isTrue);
        expect(provider.isNewImageLoading, isFalse);
        expect(provider.showImagePreview, isFalse);
        expect(notificationCount, equals(3));
      });
    });

    group('Loading State Scenarios', () {
      test('should allow both loading states to be true simultaneously', () {
        // Act
        provider.setLoading(true);
        provider.setNewImageLoading(true);

        // Assert
        expect(provider.isLoading, isTrue);
        expect(provider.isNewImageLoading, isTrue);
      });

      test('should allow both loading states to be false simultaneously', () {
        // Arrange
        provider.setLoading(false);

        // Act
        provider.setNewImageLoading(false);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.isNewImageLoading, isFalse);
      });

      test('should allow showing preview while loading new image', () {
        // Act
        provider.setNewImageLoading(true);
        provider.setShowImagePreview(true);

        // Assert
        expect(provider.isNewImageLoading, isTrue);
        expect(provider.showImagePreview, isTrue);
      });

      test('should handle typical load sequence', () {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act - Typical sequence: initial load -> loaded -> show preview
        expect(provider.isLoading, isTrue); // Initial state
        provider.setLoading(false); // Loaded
        provider.setShowImagePreview(true); // Show preview

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.isNewImageLoading, isFalse);
        expect(provider.showImagePreview, isTrue);
        expect(notificationCount, equals(2));
      });

      test('should handle new image load sequence', () {
        // Arrange
        provider.setLoading(false);
        provider.setShowImagePreview(true); // Start with preview shown
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act - New image load sequence
        provider.setNewImageLoading(true);
        provider.setShowImagePreview(false);
        provider.setNewImageLoading(false);
        provider.setShowImagePreview(true);

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.isNewImageLoading, isFalse);
        expect(provider.showImagePreview, isTrue);
        expect(notificationCount, equals(4));
      });
    });
  });
}
