import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String unsplashBaseUrl = 'https://api.unsplash.com';

  static String? get unsplashAccessKey {
    // Try to get from environment variable (for production/CI/CD)
    const envKey = String.fromEnvironment('UNSPLASH_ACCESS_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }

    // Try to get from .env file (for local development)
    final dotenvKey = dotenv.maybeGet('UNSPLASH_ACCESS_KEY');
    if (dotenvKey != null && dotenvKey.isNotEmpty) {
      return dotenvKey;
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
