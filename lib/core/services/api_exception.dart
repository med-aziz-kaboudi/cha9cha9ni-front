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
      message =
          data['message'] as String? ?? data['error'] as String? ?? message;
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
