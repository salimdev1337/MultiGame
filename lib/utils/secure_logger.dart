import 'package:flutter/foundation.dart';

/// Secure logging utility that prevents sensitive data exposure
///
/// Use this instead of debugPrint for any logging that might contain
/// sensitive information like API keys, user IDs, tokens, etc.
class SecureLogger {
  /// Logs a message without exposing sensitive data
  ///
  /// Sensitive values are replaced with [REDACTED] or masked versions
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  /// Logs an error without exposing sensitive details
  static void error(String message, {Object? error, String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix❌ $message');
      if (error != null) {
        // Log error type but not potentially sensitive error details
        debugPrint('  Error type: ${error.runtimeType}');
      }
    }
  }

  /// Masks a sensitive value for logging
  ///
  /// Examples:
  /// - "my_secret_key_12345" → "my_s***45" (first 4 + last 2)
  /// - "uid_abc123def456" → "uid_***456" (prefix + last 3)
  static String maskValue(
    String? value, {
    int visibleStart = 4,
    int visibleEnd = 2,
  }) {
    if (value == null || value.isEmpty) {
      return '[EMPTY]';
    }

    if (value.length <= visibleStart + visibleEnd) {
      return '[REDACTED]';
    }

    final start = value.substring(0, visibleStart);
    final end = value.substring(value.length - visibleEnd);
    return '$start***$end';
  }

  /// Logs API-related information without exposing keys
  static void api({
    required String endpoint,
    String? method,
    int? statusCode,
    String? message,
  }) {
    if (kDebugMode) {
      final methodStr = method ?? 'GET';
      final statusStr = statusCode != null ? ' [$statusCode]' : '';
      final messageStr = message != null ? ' - $message' : '';
      debugPrint('🌐 API: $methodStr $endpoint$statusStr$messageStr');
    }
  }

  /// Logs configuration information without exposing sensitive values
  static void config(String key, String? value) {
    if (kDebugMode) {
      if (value == null || value.isEmpty) {
        debugPrint('⚙️  Config: $key = [NOT SET]');
      } else {
        debugPrint('⚙️  Config: $key = [SET] (length: ${value.length})');
      }
    }
  }

  /// Logs user-related information with ID masking
  static void user(String message, {String? userId}) {
    if (kDebugMode) {
      final userIdStr = userId != null ? ' (ID: ${maskValue(userId)})' : '';
      debugPrint('👤 User: $message$userIdStr');
    }
  }

  /// Logs Firebase-related operations without exposing sensitive data
  static void firebase(String operation, {String? details}) {
    if (kDebugMode) {
      final detailsStr = details != null ? ' - $details' : '';
      debugPrint('🔥 Firebase: $operation$detailsStr');
    }
  }
}
