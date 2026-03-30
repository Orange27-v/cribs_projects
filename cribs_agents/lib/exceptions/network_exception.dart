/// Types of network errors that can occur
enum NetworkErrorType {
  timeout,
  noConnection,
  unauthorized,
  notFound,
  serverError,
  badRequest,
  unknown,
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;
  final int? statusCode;

  NetworkException(
    this.message,
    this.type, {
    this.statusCode,
  });

  @override
  String toString() => 'NetworkException: $message (type: $type)';

  /// Check if this is a specific error type
  bool isType(NetworkErrorType errorType) => type == errorType;

  /// Check if this is an authentication error
  bool get isAuthError => type == NetworkErrorType.unauthorized;

  /// Check if this is a connection error
  bool get isConnectionError =>
      type == NetworkErrorType.noConnection || type == NetworkErrorType.timeout;

  /// Check if this is a server error
  bool get isServerError => type == NetworkErrorType.serverError;

  /// Check if this is a client error (4xx)
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Create a NetworkErrorType from an HTTP status code
  static NetworkErrorType fromStatusCode(int statusCode) {
    if (statusCode >= 500) {
      return NetworkErrorType.serverError;
    } else if (statusCode == 401 || statusCode == 403) {
      return NetworkErrorType.unauthorized;
    } else if (statusCode == 404) {
      return NetworkErrorType.notFound;
    } else if (statusCode >= 400) {
      return NetworkErrorType.badRequest;
    }
    return NetworkErrorType.unknown;
  }
}
