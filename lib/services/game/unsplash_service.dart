import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:multigame/config/api_config.dart';
import 'package:multigame/utils/secure_logger.dart';

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

  final http.Client _client;

  UnsplashService({http.Client? client}) : _client = client ?? http.Client();

  static String? _cachedImageUrl;
  static DateTime? _cacheTime;

  Future<String> getRandomImage() async {
    if (_isCacheValid()) return _cachedImageUrl!;

    final apiKey = ApiConfig.unsplashAccessKey;
    if (apiKey == null || !ApiConfig.validateUnsplashKey(apiKey)) {
      _logError(
        'Unsplash API key is not configured or invalid. Using fallback image.',
      );
      return _getFallbackImage();
    }

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      final result = await _attemptFetch(attempt);
      if (result != null) return result;
    }
    return _getFallbackImage();
  }

  bool _isCacheValid() {
    if (_cachedImageUrl == null || _cacheTime == null) {
      return false;
    }
    return _cacheTime!.isAfter(
      DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  Future<String?> _attemptFetch(int attempt) async {
    try {
      SecureLogger.api(
        endpoint: '/photos/random',
        message: 'Fetching image (attempt $attempt/$_maxRetries)',
      );
      final imageUrl = await _fetchImageFromApi();
      _cachedImageUrl = imageUrl;
      _cacheTime = DateTime.now();
      SecureLogger.api(
        endpoint: '/photos/random',
        statusCode: 200,
        message: 'Successfully fetched image',
      );
      return imageUrl;
    } on UnsplashNetworkException catch (e) {
      if (attempt < _maxRetries) {
        _logError(
          'Network error on attempt $attempt: ${e.message}. Retrying...',
        );
        await Future.delayed(_retryDelay * attempt);
        return null;
      }
      _logError(
        'Failed to fetch image after $_maxRetries attempts: ${e.message}',
      );
      return _getFallbackImage();
    } on UnsplashApiException catch (e) {
      if (e.statusCode != null &&
          e.statusCode! >= 500 &&
          attempt < _maxRetries) {
        _logError('API error on attempt $attempt: ${e.message}. Retrying...');
        await Future.delayed(_retryDelay * attempt);
        return null;
      }
      _logError('API error: ${e.message}');
      return _getFallbackImage();
    } catch (e, stackTrace) {
      _logError('Unexpected error fetching image: $e', stackTrace: stackTrace);
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay * attempt);
        return null;
      }
      return _getFallbackImage();
    }
  }

  /// Internal method to fetch image from Unsplash API
  Future<String> _fetchImageFromApi() async {
    final apiKey = ApiConfig.unsplashAccessKey;
    if (apiKey == null) {
      throw Exception('API key not available');
    }

    final url = Uri.parse('$_baseUrl/photos/random');

    try {
      final response = await _client
          .get(url, headers: {'Authorization': 'Client-ID $apiKey'})
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Request to Unsplash API timed out after ${_requestTimeout.inSeconds} seconds',
              );
            },
          );

      return _parseHttpResponse(response);
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

  String _parseHttpResponse(http.Response response) {
    if (response.statusCode != 200) {
      final message = _httpErrorMessage(response.statusCode);
      throw UnsplashApiException(message, statusCode: response.statusCode);
    }
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (!data.containsKey('urls')) {
        throw UnsplashApiException(
          'Invalid API response: missing "urls" field',
          statusCode: 200,
        );
      }
      final urls = data['urls'] as Map<String, dynamic>;
      if (!urls.containsKey('regular')) {
        throw UnsplashApiException(
          'Invalid API response: missing "urls.regular" field',
          statusCode: 200,
        );
      }
      final imageUrl = urls['regular'] as String;
      if (imageUrl.isEmpty) {
        throw UnsplashApiException(
          'Invalid API response: empty image URL',
          statusCode: 200,
        );
      }
      return imageUrl;
    } on FormatException catch (e) {
      throw UnsplashApiException(
        'Failed to parse API response: ${e.message}',
        statusCode: 200,
        originalError: e,
      );
    }
  }

  String _httpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request - Invalid API parameters';
      case 401:
        return 'Unauthorized: Invalid or missing API key';
      case 403:
        return 'Forbidden: API key does not have required permissions';
      case 429:
        return 'Rate limit exceeded: Too many requests';
      default:
        if (statusCode >= 500) {
          return 'Server error: Unsplash API is temporarily unavailable';
        }
        return 'Unexpected API response: $statusCode';
    }
  }

  /// Log errors with optional stack trace
  void _logError(String message, {StackTrace? stackTrace}) {
    SecureLogger.error(message, tag: 'Unsplash');
    // In production, you could send to crash reporting service here
    // Example: Firebase Crashlytics, Sentry, etc.
  }

  String _getFallbackImage() {
    final fallbackImages = [
      'https://picsum.photos/800/800?random=1',
      'https://picsum.photos/800/800?random=2',
      'https://picsum.photos/800/800/?random=3',
      'https://picsum.photos/800/800/?random=4',
    ];

    final randomIndex = DateTime.now().millisecond % fallbackImages.length;
    return fallbackImages[randomIndex];
  }

  void clearCache() {
    _cachedImageUrl = null;
    _cacheTime = null;
  }

  /// Dispose the service — closes the reusable HTTP client
  void dispose() {
    _client.close();
  }
}
