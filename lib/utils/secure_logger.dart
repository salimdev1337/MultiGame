import 'package:flutter/foundation.dart';

/// Log severity levels for [SecureLogger].
///
/// Production builds should use [LogLevel.warn] or [LogLevel.error] to suppress
/// verbose output. Debug builds typically use [LogLevel.debug] or [LogLevel.verbose].
enum LogLevel {
  /// Most granular — all messages including trace-level output.
  verbose,

  /// Developer-oriented messages (default for debug builds).
  debug,

  /// Informational messages about normal application flow.
  info,

  /// Potentially harmful situations that deserve attention.
  warn,

  /// Errors and exceptional conditions only.
  error,
}

/// Secure logging utility that prevents sensitive data exposure.
///
/// Use this instead of [debugPrint] for any logging that might contain
/// sensitive information like API keys, user IDs, tokens, etc.
///
/// ## Log-level control
///
/// Set [SecureLogger.level] to filter output:
/// ```dart
/// SecureLogger.level = kReleaseMode ? LogLevel.warn : LogLevel.debug;
/// ```
///
/// All output is suppressed in non-debug builds unless [forceInRelease] is set.
class SecureLogger {
  SecureLogger._();

  /// Minimum level at or above which messages are emitted.
  ///
  /// Defaults to [LogLevel.debug] — verbose messages are suppressed unless
  /// you explicitly lower this to [LogLevel.verbose].
  static LogLevel level = LogLevel.debug;

  /// When `true`, logging bypasses the [kDebugMode] guard and writes even in
  /// release builds (useful for critical error reporting pipelines).
  /// Defaults to `false` — all output is suppressed in release builds.
  static bool forceInRelease = false;

  // ── Internal ────────────────────────────────────────────────────────────────

  static bool _shouldLog(LogLevel messageLevel) {
    if (!kDebugMode && !forceInRelease) {
      return false;
    }
    return messageLevel.index >= level.index;
  }

  static void _print(String message) => debugPrint(message);

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Logs a general informational message.
  ///
  /// Maps to [LogLevel.info]. Pass an optional [tag] to prefix the output.
  static void log(String message, {String? tag}) {
    if (!_shouldLog(LogLevel.info)) {
      return;
    }
    final prefix = tag != null ? '[$tag] ' : '';
    _print('$prefix$message');
  }

  /// Logs an error condition without exposing sensitive details.
  ///
  /// Maps to [LogLevel.error]. The error [error] object's runtime type is logged
  /// but its message is not printed to avoid leaking sensitive information.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!_shouldLog(LogLevel.error)) {
      return;
    }
    final prefix = tag != null ? '[$tag] ' : '';
    _print('$prefix❌ $message');
    if (error != null) {
      _print('  Error type: ${error.runtimeType}');
    }
  }

  /// Logs a verbose/trace-level message (suppressed unless [level] is [LogLevel.verbose]).
  static void verbose(String message, {String? tag}) {
    if (!_shouldLog(LogLevel.verbose)) {
      return;
    }
    final prefix = tag != null ? '[$tag] ' : '';
    _print('$prefix[verbose] $message');
  }

  /// Logs a warning-level message.
  static void warn(String message, {String? tag}) {
    if (!_shouldLog(LogLevel.warn)) {
      return;
    }
    final prefix = tag != null ? '[$tag] ' : '';
    _print('$prefix⚠️  $message');
  }

  /// Masks a sensitive value for logging.
  ///
  /// Examples:
  /// - `"my_secret_key_12345"` → `"my_s***45"` (first 4 + last 2 chars)
  /// - `"uid_abc123def456"` → `"uid_***456"` (prefix + last 3 chars)
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

  /// Logs API call information without exposing API keys or response bodies.
  static void api({
    required String endpoint,
    String? method,
    int? statusCode,
    String? message,
  }) {
    if (!_shouldLog(LogLevel.debug)) {
      return;
    }
    final methodStr = method ?? 'GET';
    final statusStr = statusCode != null ? ' [$statusCode]' : '';
    final messageStr = message != null ? ' - $message' : '';
    _print('🌐 API: $methodStr $endpoint$statusStr$messageStr');
  }

  /// Logs configuration key presence without exposing the value.
  static void config(String key, String? value) {
    if (!_shouldLog(LogLevel.debug)) {
      return;
    }
    if (value == null || value.isEmpty) {
      _print('⚙️  Config: $key = [NOT SET]');
    } else {
      _print('⚙️  Config: $key = [SET] (length: ${value.length})');
    }
  }

  /// Logs user-related events with a masked user ID to prevent leaking PII.
  static void user(String message, {String? userId}) {
    if (!_shouldLog(LogLevel.info)) {
      return;
    }
    final userIdStr = userId != null ? ' (ID: ${maskValue(userId)})' : '';
    _print('👤 User: $message$userIdStr');
  }

  /// Logs Firebase-related operations without exposing sensitive data.
  static void firebase(String operation, {String? details}) {
    if (!_shouldLog(LogLevel.debug)) {
      return;
    }
    final detailsStr = details != null ? ' - $details' : '';
    _print('🔥 Firebase: $operation$detailsStr');
  }
}
