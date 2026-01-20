import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/family_model.dart';
import '../services/token_storage_service.dart';

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
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.refreshPath}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sessionToken': sessionToken}),
      );

      debugPrint('🔄 Refresh response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
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

  /// Create a new family
  Future<FamilyModel> createFamily(CreateFamilyRequest request) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/family/create'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return FamilyModel.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to create family');
    }
  }

  /// Join an existing family using invite code
  Future<FamilyModel> joinFamily(JoinFamilyRequest request) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/family/join'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return FamilyModel.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to join family');
    }
  }

  /// Get current user's family details
  Future<FamilyModel?> getMyFamily() async {
    var headers = await _getHeaders();
    
    debugPrint('🔍 Calling GET /family/me');
    
    var response = await http.get(
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
        response = await http.get(
          Uri.parse('$_baseUrl/family/me'),
          headers: headers,
        );
        debugPrint('📡 Retry response status: ${response.statusCode}');
        
        // If still 401 after refresh, user needs to re-login
        if (response.statusCode == 401) {
          debugPrint('❌ Still 401 after token refresh - user needs to re-login');
          throw AuthenticationException('Session invalidated. Another device may have logged in.');
        }
      } else {
        debugPrint('❌ Token refresh failed - user needs to re-login');
        throw AuthenticationException('Session expired. Please sign in again.');
      }
    }

    if (response.statusCode == 200) {
      // Check if response body is empty
      if (response.body.isEmpty) {
        debugPrint('⚠️ Empty response body');
        return null;
      }
      
      final data = json.decode(response.body);
      debugPrint('📊 Decoded data: $data');
      
      // Handle backend response format
      if (data == null) {
        debugPrint('ℹ️ Data is null');
        return null;
      }
      
      // Check if backend returns { family: null } format
      if (data is Map && data.containsKey('family')) {
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
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/family/leave'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to leave family');
    }
  }

  /// Validate current session - lightweight API call to check if session is still valid
  /// Throws AuthenticationException if session is invalid
  Future<void> validateSession() async {
    var headers = await _getHeaders();
    
    debugPrint('🔐 Validating session...');
    
    // Use GET /family/me as a lightweight session check
    var response = await http.get(
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
        response = await http.get(
          Uri.parse('$_baseUrl/family/me'),
          headers: headers,
        );
        
        // If still 401 after refresh, session is definitely invalid
        if (response.statusCode == 401) {
          debugPrint('❌ Session invalidated - another device logged in');
          throw AuthenticationException('Session invalidated. Another device may have logged in.');
        }
      } else {
        debugPrint('❌ Token refresh failed - session expired');
        throw AuthenticationException('Session expired. Please sign in again.');
      }
    }
    
    debugPrint('✅ Session is valid');
  }
}
