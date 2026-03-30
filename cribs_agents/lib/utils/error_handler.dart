/// Utility class for handling errors and converting them to user-friendly messages
class ErrorHandler {
  /// Converts an exception to a user-friendly error message
  static String getErrorMessage(dynamic error) {
    final String errorString = error.toString();

    // Network errors
    if (_isNetworkError(errorString)) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout errors
    if (_isTimeoutError(errorString)) {
      return 'Request timed out. Please try again.';
    }

    // Server errors
    if (_isServerError(errorString)) {
      return 'Server error. Please try again later.';
    }

    // Authentication errors
    if (_isAuthError(errorString)) {
      return 'Session expired. Please log in again.';
    }

    // File size errors
    if (_isFileSizeError(errorString)) {
      return 'File is too large. Please select a smaller file.';
    }

    // Permission errors
    if (_isPermissionError(errorString)) {
      return 'Permission denied. Please grant the required permissions.';
    }

    // Validation errors
    if (_isValidationError(errorString)) {
      return 'Invalid input. Please check your information and try again.';
    }

    // Location errors
    if (_isLocationError(errorString)) {
      return 'Unable to get your location. Please enable location services.';
    }

    // User cancelled action
    if (_isCancelledError(errorString)) {
      return 'Action cancelled.';
    }

    // Duplicate entry errors
    if (_isDuplicateError(errorString)) {
      return 'This entry already exists.';
    }

    // Parse backend error messages if they exist
    final backendMessage = _extractBackendMessage(errorString);
    if (backendMessage != null) {
      return backendMessage;
    }

    // Default error message
    return 'Something went wrong. Please try again.';
  }

  /// Check if error is network-related
  static bool _isNetworkError(String error) {
    return error.contains('SocketException') ||
        error.contains('NetworkException') ||
        error.contains('Failed host lookup') ||
        error.contains('Network is unreachable');
  }

  /// Check if error is timeout-related
  static bool _isTimeoutError(String error) {
    return error.contains('TimeoutException') ||
        error.contains('timeout') ||
        error.contains('timed out');
  }

  /// Check if error is server-related
  static bool _isServerError(String error) {
    return error.contains('500') ||
        error.contains('Internal Server Error') ||
        error.contains('502') ||
        error.contains('503') ||
        error.contains('Bad Gateway') ||
        error.contains('Service Unavailable');
  }

  /// Check if error is authentication-related
  static bool _isAuthError(String error) {
    return error.contains('401') ||
        error.contains('Unauthorized') ||
        error.contains('403') ||
        error.contains('Forbidden');
  }

  /// Check if error is file size-related
  static bool _isFileSizeError(String error) {
    return error.contains('413') ||
        error.contains('too large') ||
        error.contains('file size') ||
        error.contains('Payload Too Large');
  }

  /// Check if error is permission-related
  static bool _isPermissionError(String error) {
    return error.contains('permission') || error.contains('Permission denied');
  }

  /// Check if error is validation-related
  static bool _isValidationError(String error) {
    return error.contains('validation') ||
        error.contains('invalid') ||
        error.contains('422');
  }

  /// Check if error is location-related
  static bool _isLocationError(String error) {
    return error.contains('location') ||
        error.contains('Location services') ||
        error.contains('GPS');
  }

  /// Check if user cancelled the action
  static bool _isCancelledError(String error) {
    return error.contains('cancelled') || error.contains('canceled');
  }

  /// Check if error is duplicate entry
  static bool _isDuplicateError(String error) {
    return error.contains('Duplicate entry') ||
        error.contains('duplicate') ||
        error.contains('already exists');
  }

  /// Extract backend error message if present
  static String? _extractBackendMessage(String error) {
    // Remove common error prefixes
    String cleaned = error
        .replaceFirst('Exception: ', '')
        .replaceFirst('Error: ', '')
        .replaceFirst('Failed to ', '')
        .trim();

    // If the cleaned message is user-friendly (doesn't contain technical terms), return it
    if (!_isTechnicalError(cleaned) && cleaned.length < 100) {
      return cleaned;
    }

    return null;
  }

  /// Check if error message contains technical terms
  static bool _isTechnicalError(String error) {
    final technicalTerms = [
      'Exception',
      'Error',
      'Stack trace',
      'at line',
      'null',
      'undefined',
      'RangeError',
      'TypeError',
      'FormatException',
    ];

    return technicalTerms.any((term) => error.contains(term));
  }
}
