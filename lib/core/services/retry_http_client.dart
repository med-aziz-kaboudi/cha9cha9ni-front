import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client wrapper with automatic retry logic for transient failures
class RetryHttpClient extends http.BaseClient {
  final http.Client _inner;
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  
  /// List of status codes that should trigger a retry
  static const Set<int> retryableStatusCodes = {
    408, // Request Timeout
    429, // Too Many Requests
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  };

  RetryHttpClient({
    http.Client? client,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
  }) : _inner = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      attempts++;
      
      try {
        // Clone the request for retry (original request can only be sent once)
        final clonedRequest = _cloneRequest(request);
        final response = await _inner.send(clonedRequest);
        
        // If successful or not retryable, return the response
        if (response.statusCode < 500 && 
            !retryableStatusCodes.contains(response.statusCode)) {
          return response;
        }
        
        // Check if we should retry
        if (attempts >= maxRetries || 
            !retryableStatusCodes.contains(response.statusCode)) {
          return response;
        }
        
        debugPrint('⚠️ Received ${response.statusCode}, attempt $attempts/$maxRetries. Retrying in ${delay.inMilliseconds}ms...');
        
        // Wait before retrying
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
        
      } on SocketException catch (e) {
        if (attempts >= maxRetries) {
          debugPrint('❌ Network error after $attempts attempts: $e');
          rethrow;
        }
        debugPrint('⚠️ Network error, attempt $attempts/$maxRetries. Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      } on http.ClientException catch (e) {
        if (attempts >= maxRetries) {
          debugPrint('❌ Client error after $attempts attempts: $e');
          rethrow;
        }
        debugPrint('⚠️ Client error, attempt $attempts/$maxRetries. Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
  }

  /// Clone a request for retry purposes
  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    if (request is http.Request) {
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..body = request.body
        ..encoding = request.encoding;
    } else if (request is http.MultipartRequest) {
      return http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    }
    throw UnsupportedError('Cannot clone request of type ${request.runtimeType}');
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Extension to add retry functionality and safe JSON parsing
extension SafeResponseParsing on http.Response {
  /// Safely parse JSON response, handling non-JSON error responses
  Map<String, dynamic> safeParseJson() {
    // Check for empty body
    if (body.isEmpty) {
      return {'message': 'Empty response from server', 'statusCode': statusCode};
    }
    
    final trimmedBody = body.trim();
    
    // Check if it looks like JSON (starts with { or [)
    if (!trimmedBody.startsWith('{') && !trimmedBody.startsWith('[')) {
      // Plain text error response (like "Service Unavailable")
      return {
        'message': trimmedBody.isNotEmpty ? trimmedBody : _getDefaultErrorMessage(statusCode),
        'statusCode': statusCode,
      };
    }
    
    // Try to parse as JSON
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      // Return a structured error for non-JSON responses
      return {
        'message': _getDefaultErrorMessage(statusCode),
        'rawBody': body.length > 200 ? '${body.substring(0, 200)}...' : body,
        'statusCode': statusCode,
      };
    }
  }
  
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized - please login again';
      case 403:
        return 'Access denied';
      case 404:
        return 'Resource not found';
      case 408:
        return 'Request timeout - please try again';
      case 429:
        return 'Too many requests - please wait and try again';
      case 500:
        return 'Server error - please try again later';
      case 502:
        return 'Server temporarily unavailable - please try again';
      case 503:
        return 'Service temporarily unavailable - please try again';
      case 504:
        return 'Gateway timeout - please try again';
      default:
        if (statusCode >= 500) {
          return 'Server error - please try again later';
        }
        return 'An error occurred';
    }
  }
  
  /// Check if this is a retryable error
  bool get isRetryable => RetryHttpClient.retryableStatusCodes.contains(statusCode);
  
  /// Check if the response was successful (2xx)
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Utility function for safe JSON parsing
Map<String, dynamic> parseJsonResponse(http.Response response) {
  if (response.body.isEmpty) {
    return {'message': 'Empty response from server', 'statusCode': response.statusCode};
  }
  
  final trimmedBody = response.body.trim();
  
  // Check if it looks like JSON
  if (!trimmedBody.startsWith('{') && !trimmedBody.startsWith('[')) {
    return {
      'message': trimmedBody.isNotEmpty ? trimmedBody : 'Server error',
      'statusCode': response.statusCode,
    };
  }
  
  try {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } catch (e) {
    return {
      'message': 'Failed to parse server response',
      'statusCode': response.statusCode,
    };
  }
}
