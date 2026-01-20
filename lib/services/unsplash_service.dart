import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:multigame/config/api_config.dart';

/// Custom exception classes for better error handling
class UnsplashApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  UnsplashApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() =>
      'UnsplashApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class UnsplashNetworkException implements Exception {
  final String message;
  final dynamic originalError;

  UnsplashNetworkException(this.message, {this.originalError});

  @override
  String toString() => 'UnsplashNetworkException: $message';
}

class UnsplashService {
  static const String _baseUrl = 'https://api.unsplash.com';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _requestTimeout = Duration(seconds: 10);

  // Cache to store images and reduce API calls
  static String? _cachedImageUrl;
  static DateTime? _cacheTime;

  /// Get a random Tunisian image with proper error handling and retry logic
  Future<String> getRandomTunisianImage() async {
    // Check cache first
    if (_cachedImageUrl != null && _cacheTime != null) {
      final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
      if (_cacheTime!.isAfter(hourAgo)) {
        if (kDebugMode) {
          debugPrint('UnsplashService: Using cached image');
        }
        return _cachedImageUrl!;
      }
    }

    // Validate API key before making request
    if (ApiConfig.unsplashAccessKey.isEmpty) {
      _logError('Unsplash API key is not configured. Using fallback image.');
      return _getFallbackImage();
    }

    // Attempt to fetch with retry logic
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint(
            'UnsplashService: Fetching image (attempt $attempt/$_maxRetries)',
          );
        }

        final imageUrl = await _fetchImageFromApi();

        // Cache successful response
        _cachedImageUrl = imageUrl;
        _cacheTime = DateTime.now();

        if (kDebugMode) {
          debugPrint('UnsplashService: Successfully fetched image: $imageUrl');
        }

        return imageUrl;
      } on UnsplashNetworkException catch (e) {
        // Network errors are retryable
        if (attempt < _maxRetries) {
          _logError(
            'Network error on attempt $attempt: ${e.message}. Retrying...',
          );
          await Future.delayed(_retryDelay * attempt); // Exponential backoff
          continue;
        } else {
          _logError(
            'Failed to fetch image after $_maxRetries attempts: ${e.message}',
          );
          return _getFallbackImage();
        }
      } on UnsplashApiException catch (e) {
        // API errors (4xx, 5xx) - only retry on 5xx errors
        if (e.statusCode != null &&
            e.statusCode! >= 500 &&
            attempt < _maxRetries) {
          _logError('API error on attempt $attempt: ${e.message}. Retrying...');
          await Future.delayed(_retryDelay * attempt);
          continue;
        } else {
          _logError('API error: ${e.message}');
          return _getFallbackImage();
        }
      } catch (e, stackTrace) {
        // Unexpected errors
        _logError(
          'Unexpected error fetching image: $e',
          stackTrace: stackTrace,
        );
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        } else {
          return _getFallbackImage();
        }
      }
    }

    // Should never reach here, but return fallback just in case
    return _getFallbackImage();
  }

  /// Internal method to fetch image from Unsplash API
  Future<String> _fetchImageFromApi() async {
    final url = Uri.parse('$_baseUrl/photos/random').replace(
      queryParameters: {
        'query': 'tunisia landmark',
        'orientation': 'square',
        'client_id': ApiConfig.unsplashAccessKey,
      },
    );

    try {
      final response = await http
          .get(url)
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Request to Unsplash API timed out after ${_requestTimeout.inSeconds} seconds',
              );
            },
          );

      // Handle different HTTP status codes
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;

          // Validate response structure
          if (!data.containsKey('urls')) {
            throw UnsplashApiException(
              'Invalid API response: missing "urls" field',
              statusCode: response.statusCode,
            );
          }

          final urls = data['urls'] as Map<String, dynamic>;
          if (!urls.containsKey('regular')) {
            throw UnsplashApiException(
              'Invalid API response: missing "urls.regular" field',
              statusCode: response.statusCode,
            );
          }

          final imageUrl = urls['regular'] as String;
          if (imageUrl.isEmpty) {
            throw UnsplashApiException(
              'Invalid API response: empty image URL',
              statusCode: response.statusCode,
            );
          }

          return imageUrl;
        } on FormatException catch (e) {
          throw UnsplashApiException(
            'Failed to parse API response: ${e.message}',
            statusCode: response.statusCode,
            originalError: e,
          );
        }
      } else if (response.statusCode == 401) {
        throw UnsplashApiException(
          'Unauthorized: Invalid or missing API key',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw UnsplashApiException(
          'Forbidden: API key does not have required permissions',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 429) {
        throw UnsplashApiException(
          'Rate limit exceeded: Too many requests',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw UnsplashApiException(
          'Server error: Unsplash API is temporarily unavailable',
          statusCode: response.statusCode,
        );
      } else {
        throw UnsplashApiException(
          'Unexpected API response: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException catch (e) {
      throw UnsplashNetworkException(
        'Request timeout: ${e.message}',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw UnsplashNetworkException(
        'Network error: ${e.message}',
        originalError: e,
      );
    } on SocketException catch (e) {
      throw UnsplashNetworkException(
        'No internet connection',
        originalError: e,
      );
    } catch (e) {
      // Re-throw known exceptions
      if (e is UnsplashApiException || e is UnsplashNetworkException) {
        rethrow;
      }
      // Wrap unknown exceptions
      throw UnsplashNetworkException(
        'Unexpected network error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Log errors with optional stack trace
  void _logError(String message, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('UnsplashService ERROR: $message');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
    // In production, you could send to crash reporting service here
    // Example: Firebase Crashlytics, Sentry, etc.
  }

  String _getFallbackImage() {
    // Using reliable placeholder image services
    final fallbackImages = [
      'https://picsum.photos/800/800?random=1',
      'https://picsum.photos/800/800?random=2',
      'https://picsum.photos/800/800/?random=3',
      'https://picsum.photos/800/800/?random=4',
    ];

    final randomIndex = DateTime.now().millisecond % fallbackImages.length;
    // debug: 'Using fallback image: ${fallbackImages[randomIndex]}'
    return fallbackImages[randomIndex];
  }

  void clearCache() {
    _cachedImageUrl = null;
    _cacheTime = null;
  }
}
