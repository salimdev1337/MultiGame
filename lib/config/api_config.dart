import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String unsplashBaseUrl = 'https://api.unsplash.com';

  static String? get unsplashAccessKey {
    // Get from dart-define (for production/CI/CD and local development)
    const envKey = String.fromEnvironment('UNSPLASH_ACCESS_KEY');

    if (kDebugMode) {
      debugPrint('🔑 UNSPLASH_ACCESS_KEY from dart-define: "$envKey"');
      debugPrint('🔑 Key length: ${envKey.length}');
      debugPrint('🔑 Is empty: ${envKey.isEmpty}');
    }

    if (envKey.isNotEmpty) {
      return envKey;
    }

    _log('Unsplash API key not configured');
    return null;
  }

  static bool get isUnsplashConfigured {
    final key = unsplashAccessKey;
    return validateUnsplashKey(key);
  }

  static bool validateUnsplashKey(String? key) {
    if (key == null || key.isEmpty) return false;

    // Unsplash keys are typically alphanumeric
    final validFormat = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validFormat.hasMatch(key)) {
      _log('Unsplash API key format looks invalid');
      return false;
    }

    return true;
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('ApiConfig: $message');
    }
  }
}
