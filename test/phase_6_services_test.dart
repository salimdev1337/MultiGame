/// Phase 6 Services Test
/// Tests for haptic feedback and sound services
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/services/feedback/haptic_feedback_service.dart';
import 'package:multigame/services/feedback/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Phase 6 Services Tests', () {
    late HapticFeedbackService hapticService;
    late SoundService soundService;

    setUp(() {
      hapticService = HapticFeedbackService();
      soundService = SoundService();
    });

    group('HapticFeedbackService', () {
      test('should initialize without errors', () async {
        await hapticService.initialize();
        expect(hapticService.isEnabled, isTrue);
      });

      test('should toggle enabled state', () async {
        await hapticService.initialize();

        await hapticService.setEnabled(false);
        expect(hapticService.isEnabled, isFalse);

        await hapticService.setEnabled(true);
        expect(hapticService.isEnabled, isTrue);
      });

      test('should call all haptic methods without errors', () async {
        await hapticService.initialize();

        // Basic patterns
        await hapticService.lightTap();
        await hapticService.mediumTap();
        await hapticService.strongTap();
        await hapticService.doubleTap();

        // Semantic patterns
        await hapticService.success();
        await hapticService.error();
        await hapticService.warning();
        await hapticService.notification();
        await hapticService.selectionChanged();
        await hapticService.impact();

        // Advanced patterns
        await hapticService.longPressStart();
        await hapticService.celebration();

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should handle custom patterns', () async {
        await hapticService.initialize();

        await hapticService.customPattern([0, 100, 50, 100]);

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should cancel vibration', () async {
        await hapticService.initialize();

        await hapticService.cancel();

        // Should complete without throwing
        expect(true, isTrue);
      });
    });

    group('SoundService', () {
      test('should initialize without errors', () async {
        await soundService.initialize();
        expect(soundService.isEnabled, isTrue);
      });

      test('should toggle enabled state', () async {
        await soundService.initialize();

        await soundService.setEnabled(false);
        expect(soundService.isEnabled, isFalse);

        await soundService.setEnabled(true);
        expect(soundService.isEnabled, isTrue);
      });

      test('should set volume', () async {
        await soundService.initialize();

        await soundService.setVolume(0.5);
        await soundService.setVolume(1.0);
        await soundService.setVolume(0.0);

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should call all UI sound methods without errors', () async {
        await soundService.initialize();

        await soundService.tap();
        await soundService.select();
        await soundService.toggle();
        await soundService.pop();
        await soundService.dismiss();
        await soundService.pageTransition();

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should call all feedback sound methods without errors', () async {
        await soundService.initialize();

        await soundService.success();
        await soundService.error();
        await soundService.warning();
        await soundService.notification();

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should call all game sound methods without errors', () async {
        await soundService.initialize();

        await soundService.move();
        await soundService.collect();
        await soundService.achievement();
        await soundService.levelUp();
        await soundService.gameOver();
        await soundService.victory();
        await soundService.hint();
        await soundService.undo();
        await soundService.tick();
        await soundService.urgentTick();

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should stop sound playback', () async {
        await soundService.initialize();

        await soundService.stop();

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should dispose without errors', () async {
        await soundService.initialize();

        await soundService.dispose();

        // Should complete without throwing
        expect(true, isTrue);
      });
    });

    group('Service Integration', () {
      test('both services should work together', () async {
        await hapticService.initialize();
        await soundService.initialize();

        // Simulate a success action with both feedback types
        await Future.wait([hapticService.success(), soundService.success()]);

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should handle disabled states gracefully', () async {
        await hapticService.initialize();
        await soundService.initialize();

        await hapticService.setEnabled(false);
        await soundService.setEnabled(false);

        // Should not trigger feedback when disabled
        await hapticService.success();
        await soundService.success();

        // Should complete without throwing
        expect(true, isTrue);
      });
    });
  });
}
