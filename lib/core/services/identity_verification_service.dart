import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage_service.dart';

/// Identity verification status enum
enum VerificationStatus {
  notStarted,
  inProgress,
  approved,
  declined,
  inReview,
  expired,
  abandoned,
}

/// Data class for verification status response
class VerificationStatusResponse {
  final bool isVerified;
  final String status;
  final DateTime? verifiedAt;
  final String? documentCountry;

  VerificationStatusResponse({
    required this.isVerified,
    required this.status,
    this.verifiedAt,
    this.documentCountry,
  });

  factory VerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return VerificationStatusResponse(
      isVerified: json['isVerified'] ?? false,
      status: json['status'] ?? 'not_started',
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.tryParse(json['verifiedAt']) 
          : null,
      documentCountry: json['documentCountry'],
    );
  }

  VerificationStatus get statusEnum {
    switch (status) {
      case 'approved':
        return VerificationStatus.approved;
      case 'in_progress':
        return VerificationStatus.inProgress;
      case 'declined':
        return VerificationStatus.declined;
      case 'in_review':
        return VerificationStatus.inReview;
      case 'expired':
        return VerificationStatus.expired;
      case 'abandoned':
        return VerificationStatus.abandoned;
      default:
        return VerificationStatus.notStarted;
    }
  }
}

/// Data class for starting verification response
class StartVerificationResponse {
  final bool success;
  final String sessionId;
  final String verificationUrl;

  StartVerificationResponse({
    required this.success,
    required this.sessionId,
    required this.verificationUrl,
  });

  factory StartVerificationResponse.fromJson(Map<String, dynamic> json) {
    return StartVerificationResponse(
      success: json['success'] ?? false,
      sessionId: json['sessionId'] ?? '',
      verificationUrl: json['verificationUrl'] ?? '',
    );
  }
}

/// Data class for can transfer ownership response
class CanTransferOwnershipResponse {
  final bool canTransfer;
  final String? reason;
  final bool requiresSupport;

  CanTransferOwnershipResponse({
    required this.canTransfer,
    this.reason,
    this.requiresSupport = false,
  });

  factory CanTransferOwnershipResponse.fromJson(Map<String, dynamic> json) {
    return CanTransferOwnershipResponse(
      canTransfer: json['canTransfer'] ?? false,
      reason: json['reason'],
      requiresSupport: json['requiresSupport'] ?? false,
    );
  }
}

/// Service for handling identity verification via Didit
class IdentityVerificationService {
  final TokenStorageService _tokenStorage = TokenStorageService();
  
  // Singleton
  static final IdentityVerificationService _instance = IdentityVerificationService._internal();
  factory IdentityVerificationService() => _instance;
  IdentityVerificationService._internal();

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Start identity verification process
  /// Returns a URL to open in WebView for the user to complete verification
  Future<StartVerificationResponse> startVerification({
    String? workflowId,
    String? callbackUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      
      if (workflowId != null) {
        body['workflowId'] = workflowId;
      }
      if (callbackUrl != null) {
        body['callbackUrl'] = callbackUrl;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/identity/start-verification'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return StartVerificationResponse.fromJson(data);
      } else {
        debugPrint('Failed to start verification: ${response.body}');
        throw Exception('Failed to start verification: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error starting verification: $e');
      rethrow;
    }
  }

  /// Get current verification status
  Future<VerificationStatusResponse> getVerificationStatus() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/identity/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VerificationStatusResponse.fromJson(data);
      } else {
        debugPrint('Failed to get verification status: ${response.body}');
        throw Exception('Failed to get verification status');
      }
    } catch (e) {
      debugPrint('Error getting verification status: $e');
      rethrow;
    }
  }

  /// Check session status after WebView closes
  Future<VerificationStatusResponse> checkSession({String? sessionId}) async {
    try {
      final headers = await _getHeaders();
      var url = '${ApiConfig.baseUrl}/identity/check-session';
      if (sessionId != null) {
        url += '?sessionId=$sessionId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VerificationStatusResponse.fromJson(data);
      } else {
        throw Exception('Failed to check session');
      }
    } catch (e) {
      debugPrint('Error checking session: $e');
      rethrow;
    }
  }

  /// Complete verification from app callback
  Future<VerificationStatusResponse> completeVerification({
    required String sessionId,
    required String status,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/identity/complete'),
        headers: headers,
        body: jsonEncode({
          'sessionId': sessionId,
          'status': status,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VerificationStatusResponse.fromJson(data);
      } else {
        throw Exception('Failed to complete verification');
      }
    } catch (e) {
      debugPrint('Error completing verification: $e');
      rethrow;
    }
  }

  /// Check if user can transfer ownership
  Future<CanTransferOwnershipResponse> canTransferOwnership() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/identity/can-transfer-ownership'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CanTransferOwnershipResponse.fromJson(data);
      } else {
        throw Exception('Failed to check transfer ownership eligibility');
      }
    } catch (e) {
      debugPrint('Error checking transfer ownership: $e');
      rethrow;
    }
  }
}
