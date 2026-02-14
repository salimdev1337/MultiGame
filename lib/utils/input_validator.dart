/// Utility for validating and sanitizing user input
///
/// Prevents injection attacks, XSS, and other security issues
class InputValidator {
  /// Validate nickname input
  ///
  /// Rules:
  /// - 2-20 characters
  /// - Alphanumeric, spaces, hyphens, underscores only
  /// - No leading/trailing whitespace
  /// - No consecutive spaces
  static ValidationResult validateNickname(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return ValidationResult.error('Nickname cannot be empty');
    }

    if (trimmed.length < 2 || trimmed.length > 20) {
      return ValidationResult.error(
        'Nickname must be between 2 and 20 characters',
      );
    }

    // Only allow alphanumeric, spaces, hyphens, and underscores
    final validChars = RegExp(r'^[a-zA-Z0-9_\- ]+$');
    if (!validChars.hasMatch(trimmed)) {
      return ValidationResult.error(
        'Nickname can only contain alphanumeric characters, spaces, hyphens, and underscores',
      );
    }

    // No consecutive spaces
    if (trimmed.contains('  ')) {
      return ValidationResult.error(
        'Nickname cannot contain consecutive spaces',
      );
    }

    // No leading or trailing spaces (should already be trimmed)
    if (trimmed != input) {
      return ValidationResult.error(
        'Nickname cannot have leading or trailing whitespace',
      );
    }

    return ValidationResult.success(trimmed);
  }

  /// Sanitize string for Firestore storage
  ///
  /// Removes potentially harmful characters while preserving valid content
  static String sanitizeForFirestore(String input) {
    // Trim whitespace
    String sanitized = input.trim();

    // Remove potential HTML/script tags AND their content
    sanitized = sanitized.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      '',
    );
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Replace multiple spaces with single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    return sanitized.trim();
  }

  /// Validate score value
  ///
  /// Ensures score is within valid range for the game
  static ValidationResult validateScore(
    int score, {
    int min = 0,
    int max = 100000,
  }) {
    if (score < min || score > max) {
      // Include "maximum" in the message when above max for custom ranges
      if (score > max && max != 100000) {
        return ValidationResult.error(
          'Score must be between $min and $max (maximum: $max)',
        );
      }
      return ValidationResult.error('Score must be between $min and $max');
    }

    return ValidationResult.success(score);
  }

  /// Validate game type
  ///
  /// Ensures game type is one of the allowed values
  static ValidationResult validateGameType(String gameType) {
    const validGameTypes = ['puzzle', '2048', 'snake', 'infinite_runner'];

    if (!validGameTypes.contains(gameType)) {
      return ValidationResult.error(
        'Invalid game type. Valid game types are: ${validGameTypes.join(", ")}',
      );
    }

    return ValidationResult.success(gameType);
  }

  /// Check if string contains potentially dangerous characters
  static bool containsDangerousChars(String input) {
    // Check for script tags, SQL injection patterns, etc.
    final dangerous = RegExp(
      r"(<script|javascript:|onerror=|onclick=|<iframe|eval\(|\.\.\/|'|--|union\s+select)",
      caseSensitive: false,
    );

    return dangerous.hasMatch(input);
  }
}

/// Result of input validation
class ValidationResult {
  final bool isValid;
  final String? error;
  final dynamic value;

  ValidationResult.success(this.value) : isValid = true, error = null;

  ValidationResult.error(this.error) : isValid = false, value = null;
}
