/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException [$statusCode]: $message';
    }
    return 'ApiException: $message';
  }

  /// Factory constructors for common error types
  factory ApiException.fromResponse(int statusCode, dynamic data) {
    String message = 'An error occurred';

    if (data is Map<String, dynamic>) {
      // Handle message field - can be String or List<dynamic> (validation errors)
      final messageField = data['message'];
      if (messageField is String) {
        message = messageField;
      } else if (messageField is List) {
        // Join validation errors into a single message
        message = messageField.map((e) => e.toString()).join('. ');
      } else {
        // Fallback to error field
        final errorField = data['error'];
        if (errorField is String) {
          message = errorField;
        }
      }
    } else if (data is String) {
      message = data;
    }

    return ApiException(message: message, statusCode: statusCode, data: data);
  }

  factory ApiException.networkError() {
    return ApiException(
      message: 'Network error. Please check your internet connection.',
    );
  }

  factory ApiException.timeout() {
    return ApiException(message: 'Request timeout. Please try again.');
  }

  factory ApiException.unauthorized() {
    return ApiException(
      message: 'Unauthorized. Please login again.',
      statusCode: 401,
    );
  }

  factory ApiException.serverError() {
    return ApiException(
      message: 'Server error. Please try again later.',
      statusCode: 500,
    );
  }
}
