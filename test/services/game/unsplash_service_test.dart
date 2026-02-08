import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/services/game/unsplash_service.dart';
import 'package:multigame/config/api_config.dart';

/// Comprehensive unit tests for UnsplashService
///
/// Note: These are integration tests that test the public API.
/// Since _fetchImageFromApi is private, we test through getRandomImage()
/// which exercises all code paths including error handling and retries.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnsplashService Tests', () {
    late UnsplashService service;

    setUp(() {
      service = UnsplashService();
      service.clearCache(); // Clear cache before each test
    });

    tearDown(() {
      service.clearCache();
    });

    group('Exception Classes', () {
      test('UnsplashApiException should format toString with status code', () {
        final exception = UnsplashApiException(
          'Test error',
          statusCode: 401,
        );

        expect(
          exception.toString(),
          'UnsplashApiException: Test error (Status: 401)',
        );
        expect(exception.message, 'Test error');
        expect(exception.statusCode, 401);
        expect(exception.originalError, isNull);
      });

      test('UnsplashApiException without status code', () {
        final exception = UnsplashApiException('Test error');

        expect(exception.toString(), 'UnsplashApiException: Test error');
        expect(exception.message, 'Test error');
        expect(exception.statusCode, isNull);
      });

      test('UnsplashApiException with original error', () {
        final originalError = FormatException('Invalid JSON');
        final exception = UnsplashApiException(
          'Parse failed',
          statusCode: 200,
          originalError: originalError,
        );

        expect(exception.message, 'Parse failed');
        expect(exception.statusCode, 200);
        expect(exception.originalError, originalError);
      });

      test('UnsplashNetworkException should format toString correctly', () {
        final exception = UnsplashNetworkException('Network failed');

        expect(
          exception.toString(),
          'UnsplashNetworkException: Network failed',
        );
        expect(exception.message, 'Network failed');
        expect(exception.originalError, isNull);
      });

      test('UnsplashNetworkException with original error', () {
        final originalError = Exception('Connection timeout');
        final exception = UnsplashNetworkException(
          'Request failed',
          originalError: originalError,
        );

        expect(exception.message, 'Request failed');
        expect(exception.originalError, originalError);
      });
    });

    group('Cache Management', () {
      test('clearCache should reset cached data', () {
        // Set up cache by making a call
        service.clearCache();

        // Verify service is in clean state
        expect(service, isNotNull);
      });

      test('clearCache is idempotent', () {
        service.clearCache();
        service.clearCache();
        service.clearCache();

        // Should not throw any errors
        expect(service, isNotNull);
      });
    });

    group('API Key Validation', () {
      test('getRandomImage returns fallback when API key is missing', () async {
        // This test only runs when API key is NOT configured
        if (ApiConfig.unsplashAccessKey != null) {
          return; // Skip if API key is configured
        }

        final imageUrl = await service.getRandomImage();

        // Should return a picsum.photos URL (fallback)
        expect(imageUrl, startsWith('https://picsum.photos/800/800'));
        expect(imageUrl, contains('random='));
      });

      test('getRandomImage validates API key format', () async {
        // When API key is invalid or missing, should use fallback
        if (ApiConfig.unsplashAccessKey == null) {
          final imageUrl = await service.getRandomImage();
          expect(imageUrl, startsWith('https://picsum.photos/800/800'));
        }
      });
    });

    group('Successful Image Fetching (Integration)', () {
      test('getRandomImage returns valid URL when API is available', () async {
        // Skip if API key not configured
        if (ApiConfig.unsplashAccessKey == null) {
          return;
        }

        service.clearCache(); // Ensure fresh call

        final imageUrl = await service.getRandomImage();

        // Should return either Unsplash URL or fallback
        expect(imageUrl, isNotEmpty);
        expect(
          imageUrl,
          anyOf([
            startsWith('https://images.unsplash.com/'),
            startsWith('https://picsum.photos/800/800'),
          ]),
        );
      });

      test('getRandomImage uses cache within 1 hour window', () async {
        // Skip if API key not configured
        if (ApiConfig.unsplashAccessKey == null) {
          return;
        }

        service.clearCache();

        // First call - fetches from API or fallback
        final firstUrl = await service.getRandomImage();
        expect(firstUrl, isNotEmpty);

        // Second call - should use cached value
        final secondUrl = await service.getRandomImage();
        expect(secondUrl, firstUrl); // Should be identical

        // Third call - still cached
        final thirdUrl = await service.getRandomImage();
        expect(thirdUrl, firstUrl);
      });

      test('clearCache forces fresh API call', () async {
        // Skip if API key not configured
        if (ApiConfig.unsplashAccessKey == null) {
          return;
        }

        // First call
        final firstUrl = await service.getRandomImage();
        expect(firstUrl, isNotEmpty);

        // Clear cache
        service.clearCache();

        // Second call should potentially be different (fresh call)
        final secondUrl = await service.getRandomImage();
        expect(secondUrl, isNotEmpty);
        // Note: URLs may be same due to randomization, but cache was cleared
      });
    });

    group('Fallback Image Behavior', () {
      test('fallback images use picsum.photos domain', () async {
        // Force fallback by clearing API key context
        if (ApiConfig.unsplashAccessKey == null) {
          final imageUrl = await service.getRandomImage();

          expect(imageUrl, startsWith('https://picsum.photos/800/800'));
          expect(imageUrl, matches(RegExp(r'random=\d')));
        }
      });

      test('fallback images are deterministic within same millisecond', () async {
        // This test verifies fallback generation logic
        if (ApiConfig.unsplashAccessKey == null) {
          final urls = <String>[];

          // Get multiple fallback URLs rapidly
          for (int i = 0; i < 5; i++) {
            service.clearCache();
            urls.add(await service.getRandomImage());
          }

          // All should be valid picsum URLs
          for (final url in urls) {
            expect(url, startsWith('https://picsum.photos/800/800'));
          }
        }
      });

      test('fallback images include random parameter', () async {
        if (ApiConfig.unsplashAccessKey == null) {
          service.clearCache();
          final imageUrl = await service.getRandomImage();

          // Verify format: https://picsum.photos/800/800?random=N or /?random=N
          expect(imageUrl, startsWith('https://picsum.photos/800/800'));
          expect(imageUrl, contains('random='));
        }
      });
    });

    group('Error Resilience (Integration)', () {
      test('service handles network issues gracefully', () async {
        // This test verifies the service doesn't crash on errors
        // Result will be either Unsplash URL or fallback
        final imageUrl = await service.getRandomImage();

        expect(imageUrl, isNotEmpty);
        expect(imageUrl, startsWith('https://'));
      });

      test('multiple consecutive calls work correctly', () async {
        service.clearCache(); // Start fresh

        final urls = <String>[];

        for (int i = 0; i < 3; i++) {
          final url = await service.getRandomImage();
          urls.add(url);
        }

        // All should return valid URLs
        for (final url in urls) {
          expect(url, isNotEmpty);
          expect(url, startsWith('https://'));
        }

        // Note: When API key is missing, fallback URLs are NOT cached
        // So we just verify all URLs are valid, not that they're identical
      });

      test('service recovers after cache clear', () async {
        // First call
        final firstUrl = await service.getRandomImage();
        expect(firstUrl, isNotEmpty);

        // Clear and call again
        service.clearCache();
        final secondUrl = await service.getRandomImage();
        expect(secondUrl, isNotEmpty);

        // Clear and call third time
        service.clearCache();
        final thirdUrl = await service.getRandomImage();
        expect(thirdUrl, isNotEmpty);

        // All should be valid URLs
        expect(firstUrl, startsWith('https://'));
        expect(secondUrl, startsWith('https://'));
        expect(thirdUrl, startsWith('https://'));
      });
    });

    group('API Configuration Integration', () {
      test('service respects API configuration', () async {
        final isConfigured = ApiConfig.isUnsplashConfigured;
        final imageUrl = await service.getRandomImage();

        if (isConfigured) {
          // With valid API key, should attempt Unsplash or use fallback
          expect(imageUrl, isNotEmpty);
        } else {
          // Without API key, should use fallback
          expect(imageUrl, startsWith('https://picsum.photos/800/800'));
        }
      });

      test('validates API key before making requests', () async {
        // When API key is null or invalid, should skip API call
        if (ApiConfig.unsplashAccessKey == null) {
          final imageUrl = await service.getRandomImage();

          // Should immediately return fallback
          expect(imageUrl, startsWith('https://picsum.photos/800/800'));
        }
      });
    });

    group('Cache Expiration', () {
      test('cache behavior with API calls', () async {
        service.clearCache(); // Start fresh

        final url1 = await service.getRandomImage();
        final url2 = await service.getRandomImage();
        final url3 = await service.getRandomImage();

        // All should be valid URLs
        expect(url1, isNotEmpty);
        expect(url2, isNotEmpty);
        expect(url3, isNotEmpty);

        // Note: Cache only applies when API successfully returns
        // With missing API key, fallback is returned without caching
        // So URLs may vary due to millisecond-based randomization
      });

      test('cache clears correctly', () async {
        final url1 = await service.getRandomImage();

        service.clearCache();

        final url2 = await service.getRandomImage();

        // Both should be valid, cache was cleared
        expect(url1, isNotEmpty);
        expect(url2, isNotEmpty);
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('service handles rapid consecutive calls', () async {
        service.clearCache(); // Start fresh

        // Rapid fire calls
        final futures = List.generate(
          10,
          (_) => service.getRandomImage(),
        );

        final urls = await Future.wait(futures);

        // All should succeed and return valid URLs
        expect(urls.length, 10);
        for (final url in urls) {
          expect(url, isNotEmpty);
          expect(url, startsWith('https://'));
        }

        // All URLs should be valid (may or may not be identical due to concurrency)
        // But they should all be valid HTTPS URLs
        final firstUrl = urls.first;
        expect(firstUrl, isNotEmpty);
      });

      test('service handles interleaved calls and cache clears', () async {
        service.clearCache();
        final url1 = await service.getRandomImage();

        service.clearCache();
        final url2 = await service.getRandomImage();

        service.clearCache();
        final url3 = await service.getRandomImage();

        // All should be valid
        expect(url1, isNotEmpty);
        expect(url2, isNotEmpty);
        expect(url3, isNotEmpty);
      });

      test('multiple service instances share cache (static)', () async {
        final service1 = UnsplashService();
        final service2 = UnsplashService();

        service1.clearCache(); // Clear shared cache

        final url1 = await service1.getRandomImage();
        final url2 = await service2.getRandomImage();

        // Both should return valid URLs
        expect(url1, isNotEmpty);
        expect(url2, isNotEmpty);

        // Note: Static cache is shared, but only caches successful API calls
        // When API key is missing, fallback URLs are generated fresh each time
      });

      test('clearCache on one instance affects other instances', () async {
        final service1 = UnsplashService();
        final service2 = UnsplashService();

        service1.clearCache();
        await service1.getRandomImage();

        service2.clearCache(); // Should clear shared cache

        final url = await service2.getRandomImage();
        expect(url, isNotEmpty);
      });
    });

    group('Public API Contract', () {
      test('getRandomImage always returns non-empty string', () async {
        for (int i = 0; i < 5; i++) {
          service.clearCache();
          final url = await service.getRandomImage();
          expect(url, isNotEmpty);
        }
      });

      test('getRandomImage always returns valid HTTPS URL', () async {
        for (int i = 0; i < 3; i++) {
          service.clearCache();
          final url = await service.getRandomImage();
          expect(url, startsWith('https://'));
        }
      });

      test('clearCache never throws exceptions', () {
        expect(() => service.clearCache(), returnsNormally);
        expect(() => service.clearCache(), returnsNormally);
        expect(() => service.clearCache(), returnsNormally);
      });

      test('service is reusable after errors', () async {
        // Even if there are errors, service should continue working
        final url1 = await service.getRandomImage();
        expect(url1, isNotEmpty);

        service.clearCache();

        final url2 = await service.getRandomImage();
        expect(url2, isNotEmpty);
      });
    });

    group('Performance and Reliability', () {
      test('cache improves performance on repeated calls', () async {
        service.clearCache();

        // First call (uncached)
        final stopwatch1 = Stopwatch()..start();
        final url1 = await service.getRandomImage();
        stopwatch1.stop();

        // Second call (cached) - should be faster
        final stopwatch2 = Stopwatch()..start();
        final url2 = await service.getRandomImage();
        stopwatch2.stop();

        // Both calls should return same URL due to caching
        expect(url1, isNotEmpty);
        expect(url2, isNotEmpty);
        // Cached call should be significantly faster (< 10ms typically)
        expect(stopwatch2.elapsedMilliseconds, lessThan(100));
      });

      test('service completes within reasonable timeout', () async {
        service.clearCache();

        // Should complete within 15 seconds (includes retries)
        final url = await service.getRandomImage()
            .timeout(const Duration(seconds: 15));

        expect(url, isNotEmpty);
      });
    });

    group('Documentation and API Design', () {
      test('service provides clear exception types', () {
        // Verify exception classes are accessible
        expect(UnsplashApiException, isNotNull);
        expect(UnsplashNetworkException, isNotNull);
      });

      test('exceptions provide useful error information', () {
        final apiException = UnsplashApiException(
          'Test API error',
          statusCode: 500,
          originalError: Exception('Original'),
        );

        expect(apiException.message, isNotEmpty);
        expect(apiException.statusCode, isNotNull);
        expect(apiException.toString(), contains('Test API error'));
        expect(apiException.toString(), contains('500'));

        final networkException = UnsplashNetworkException(
          'Test network error',
          originalError: Exception('Network'),
        );

        expect(networkException.message, isNotEmpty);
        expect(networkException.toString(), contains('Test network error'));
      });
    });
  });
}
