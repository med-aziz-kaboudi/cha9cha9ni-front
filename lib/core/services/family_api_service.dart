import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/family_model.dart';
import '../services/token_storage_service.dart';
import '../services/session_manager.dart';
import '../services/retry_http_client.dart';

/// Exception thrown when authentication fails and user should be logged out
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException([this.message = 'Session expired. Please sign in again.']);
  
  @override
  String toString() => message;
}

class FamilyApiService {
  final _baseUrl = ApiConfig.baseUrl;
  final _tokenStorage = TokenStorageService();
  final _sessionManager = SessionManager();
  final http.Client _client = RetryHttpClient();

  /// Safely parse JSON response, handling non-JSON error responses
  Map<String, dynamic> _safeJsonDecode(http.Response response) {
    return response.safeParseJson();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Refresh access token using session token
  Future<bool> _refreshToken() async {
    try {
      final sessionToken = await _tokenStorage.getSessionToken();
      if (sessionToken == null) {
        debugPrint('❌ No session token available for refresh');
        return false;
      }

      debugPrint('🔄 Refreshing token...');
      final response = await _client.post(
        Uri.parse('$_baseUrl${ApiConfig.refreshPath}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sessionToken': sessionToken}),
      );

      debugPrint('🔄 Refresh response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response);
        final newAccessToken = data['accessToken'];
        final newSessionToken = data['sessionToken'];
        
        if (newAccessToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            sessionToken: newSessionToken ?? sessionToken,
            expiresIn: data['expiresIn']?.toString(),
          );
          debugPrint('✅ Token refreshed successfully');
          return true;
        }
      }
      
      debugPrint('❌ Token refresh failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    }
  }

  /// Force token refresh - useful after operations that change user state (like leaving a family)
  Future<bool> forceTokenRefresh() async {
    debugPrint('🔄 Forcing token refresh...');
    return await _refreshToken();
  }

  /// Create a new family
  Future<FamilyModel> createFamily(CreateFamilyRequest request) async {
    var headers = await _getHeaders();
    
    debugPrint('🏠 API: Creating family...');
    
    var response = await _client.post(
      Uri.parse('$_baseUrl/family/create'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    // Handle 401 - try to refresh token
    if (response.statusCode == 401) {
      debugPrint('🔒 401: Unauthorized - attempting token refresh for createFamily');
      final refreshed = await _refreshToken();
      if (refreshed) {
        debugPrint('✅ Token refreshed, retrying createFamily request');
        // Retry with new token
        headers = await _getHeaders();
        response = await _client.post(
          Uri.parse('$_baseUrl/family/create'),
          headers: headers,
          body: json.encode(request.toJson()),
        );
        
        // If still 401 after refresh, user needs to re-login
        if (response.statusCode == 401) {
          debugPrint('❌ Still 401 after token refresh - user needs to re-login');
          _sessionManager.notifySessionExpired('Session expired');
          throw AuthenticationException('Session expired. Please sign in again.');
        }
      } else {
        debugPrint('❌ Token refresh failed - user needs to re-login');
        _sessionManager.notifySessionExpired('Session expired');
        throw AuthenticationException('Session expired. Please sign in again.');
      }
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = _safeJsonDecode(response);
      return FamilyModel.fromJson(data);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to create family');
    }
  }

  /// Join an existing family using invite code
  Future<FamilyModel> joinFamily(JoinFamilyRequest request) async {
    var headers = await _getHeaders();
    
    debugPrint('🎫 API: Joining family...');
    
    var response = await _client.post(
      Uri.parse('$_baseUrl/family/join'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    // Handle 401 - try to refresh token
    if (response.statusCode == 401) {
      debugPrint('🔒 401: Unauthorized - attempting token refresh for joinFamily');
      final refreshed = await _refreshToken();
      if (refreshed) {
        debugPrint('✅ Token refreshed, retrying joinFamily request');
        // Retry with new token
        headers = await _getHeaders();
        response = await _client.post(
          Uri.parse('$_baseUrl/family/join'),
          headers: headers,
          body: json.encode(request.toJson()),
        );
        
        // If still 401 after refresh, user needs to re-login
        if (response.statusCode == 401) {
          debugPrint('❌ Still 401 after token refresh - user needs to re-login');
          _sessionManager.notifySessionExpired('Session expired');
          throw AuthenticationException('Session expired. Please sign in again.');
        }
      } else {
        debugPrint('❌ Token refresh failed - user needs to re-login');
        _sessionManager.notifySessionExpired('Session expired');
        throw AuthenticationException('Session expired. Please sign in again.');
      }
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = _safeJsonDecode(response);
      return FamilyModel.fromJson(data);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to join family');
    }
  }

  /// Get current user's family details
  Future<FamilyModel?> getMyFamily() async {
    var headers = await _getHeaders();
    
    debugPrint('🔍 Calling GET /family/me');
    
    var response = await _client.get(
      Uri.parse('$_baseUrl/family/me'),
      headers: headers,
    );

    debugPrint('📡 Response status: ${response.statusCode}');
    debugPrint('📦 Response body: ${response.body}');

    // Handle 401 - try to refresh token
    if (response.statusCode == 401) {
      debugPrint('🔒 401: Unauthorized - attempting token refresh');
      final refreshed = await _refreshToken();
      if (refreshed) {
        debugPrint('✅ Token refreshed, retrying request');
        // Retry with new token
        headers = await _getHeaders();
        response = await _client.get(
          Uri.parse('$_baseUrl/family/me'),
          headers: headers,
        );
        debugPrint('📡 Retry response status: ${response.statusCode}');
        
        // If still 401 after refresh, user needs to re-login
        if (response.statusCode == 401) {
          debugPrint('❌ Still 401 after token refresh - user needs to re-login');
          _sessionManager.notifySessionExpired('Another device may have logged in');
          throw AuthenticationException('Session invalidated. Another device may have logged in.');
        }
      } else {
        debugPrint('❌ Token refresh failed - user needs to re-login');
        _sessionManager.notifySessionExpired('Session expired');
        throw AuthenticationException('Session expired. Please sign in again.');
      }
    }

    if (response.statusCode == 200) {
      // Check if response body is empty
      if (response.body.isEmpty) {
        debugPrint('⚠️ Empty response body');
        return null;
      }
      
      final data = _safeJsonDecode(response);
      debugPrint('📊 Decoded data: $data');
      
      // Handle backend response format
      if (data.isEmpty) {
        debugPrint('ℹ️ Data is empty');
        return null;
      }
      
      // Check if backend returns { family: null } format
      if (data.containsKey('family')) {
        if (data['family'] == null) {
          debugPrint('ℹ️ Family property is null');
          return null;
        }
        // If family key exists and has data, use it
        debugPrint('✅ Parsing family from nested object');
        return FamilyModel.fromJson(data['family']);
      }
      
      // Otherwise, treat the data as the family object directly
      debugPrint('✅ Parsing family from direct object');
      return FamilyModel.fromJson(data);
    } else if (response.statusCode == 404) {
      // User has no family
      debugPrint('ℹ️ 404: User has no family');
      return null;
    } else {
      debugPrint('❌ Error: ${response.statusCode}');
      throw Exception('Failed to fetch family details');
    }
  }

  /// Leave current family
  Future<void> leaveFamily() async {
    final headers = await _getHeaders();
    
    final response = await _client.delete(
      Uri.parse('$_baseUrl/family/leave'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to leave family');
    }
  }

  // ==================== Member Removal Methods ====================

  /// Owner initiates member removal - sends confirmation email to owner
  Future<Map<String, dynamic>> initiateRemoval(String memberId) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/removal/initiate'),
      headers: headers,
      body: json.encode({'memberId': memberId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to initiate removal');
    }
  }

  /// Owner confirms removal with verification code
  Future<Map<String, dynamic>> confirmOwnerRemoval(String requestId, String code) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/removal/confirm-owner'),
      headers: headers,
      body: json.encode({'requestId': requestId, 'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to confirm removal');
    }
  }

  /// Get pending removal requests initiated by owner
  Future<List<Map<String, dynamic>>> getOwnerRemovalRequests() async {
    final headers = await _getHeaders();
    
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/removal/owner-requests'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      try {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      } catch (e) {
        // Ignore parsing errors
      }
      return [];
    } else {
      return [];
    }
  }

  /// Cancel a pending removal request (by owner)
  Future<void> cancelRemoval(String requestId) async {
    final headers = await _getHeaders();
    
    final response = await _client.delete(
      Uri.parse('$_baseUrl/family/removal/$requestId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to cancel removal');
    }
  }

  /// Get removal requests for a member
  Future<List<RemovalRequest>> getMemberRemovalRequests() async {
    final headers = await _getHeaders();
    
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/removal/member-requests'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      if (body.isEmpty) return [];
      try {
        final data = json.decode(body) as List;
        return data.map((r) => RemovalRequest.fromJson(r)).toList();
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }
  }

  /// Member accepts removal - triggers verification code
  Future<Map<String, dynamic>> acceptRemoval(String requestId) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/removal/accept'),
      headers: headers,
      body: json.encode({'requestId': requestId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to accept removal');
    }
  }

  /// Member confirms removal with verification code - removes from family
  Future<Map<String, dynamic>> confirmMemberRemoval(String requestId, String code) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/removal/confirm-member'),
      headers: headers,
      body: json.encode({'requestId': requestId, 'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to confirm removal');
    }
  }

  // ==================== Member Self-Leave Methods ====================

  /// Member initiates leaving the family - sends confirmation email
  Future<Map<String, dynamic>> initiateSelfLeave() async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/leave/initiate'),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to initiate leave request');
    }
  }

  /// Member confirms leaving with verification code
  Future<Map<String, dynamic>> confirmSelfLeave(String code) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/leave/confirm'),
      headers: headers,
      body: json.encode({'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to confirm leaving family');
    }
  }

  // ==================== Ownership Transfer Methods ====================

  /// Check if ownership can be transferred (not blocked by withdrawals)
  Future<Map<String, dynamic>> canTransferOwnership() async {
    final headers = await _getHeaders();
    
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/transfer/can-transfer'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to check transfer eligibility');
    }
  }

  /// Owner initiates ownership transfer to another member
  Future<Map<String, dynamic>> initiateTransfer(String newOwnerId) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/transfer/initiate'),
      headers: headers,
      body: json.encode({'newOwnerId': newOwnerId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to initiate ownership transfer');
    }
  }

  /// Owner confirms transfer with verification code
  Future<Map<String, dynamic>> confirmTransfer(String requestId, String code) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/transfer/confirm'),
      headers: headers,
      body: json.encode({'requestId': requestId, 'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _safeJsonDecode(response);
    } else {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to confirm ownership transfer');
    }
  }

  /// Get pending transfer request
  Future<Map<String, dynamic>?> getPendingTransfer() async {
    final headers = await _getHeaders();
    
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/transfer/pending'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      if (body.isEmpty || body == 'null') return null;
      return _safeJsonDecode(response);
    } else {
      return null;
    }
  }

  /// Cancel a pending transfer request
  Future<void> cancelTransfer(String requestId) async {
    final headers = await _getHeaders();
    
    final response = await _client.delete(
      Uri.parse('$_baseUrl/family/transfer/$requestId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = _safeJsonDecode(response);
      throw Exception(error['message'] ?? 'Failed to cancel transfer');
    }
  }

  /// Validate current session - lightweight API call to check if session is still valid
  /// Throws AuthenticationException if session is invalid
  Future<void> validateSession() async {
    var headers = await _getHeaders();
    
    debugPrint('🔐 Validating session...');
    
    // Use GET /family/me as a lightweight session check
    var response = await _client.get(
      Uri.parse('$_baseUrl/family/me'),
      headers: headers,
    );

    // Handle 401 - try to refresh token
    if (response.statusCode == 401) {
      debugPrint('🔒 401: Session may be invalidated - attempting token refresh');
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry with new token
        headers = await _getHeaders();
        response = await _client.get(
          Uri.parse('$_baseUrl/family/me'),
          headers: headers,
        );
        
        // If still 401 after refresh, session is definitely invalid
        if (response.statusCode == 401) {
          debugPrint('❌ Session invalidated - another device logged in');
          _sessionManager.notifySessionExpired('Another device may have logged in');
          throw AuthenticationException('Session invalidated. Another device may have logged in.');
        }
      } else {
        debugPrint('❌ Token refresh failed - session expired');
        _sessionManager.notifySessionExpired('Session expired');
        throw AuthenticationException('Session expired. Please sign in again.');
      }
    }
    
    debugPrint('✅ Session is valid');
  }
}
