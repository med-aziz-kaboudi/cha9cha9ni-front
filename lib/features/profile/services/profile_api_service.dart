import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/token_storage_service.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/config/api_config.dart';

class UserProfile {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phone;
  final String? profilePictureUrl;
  final String? familyId;
  final bool isOwner;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phone,
    this.profilePictureUrl,
    this.familyId,
    required this.isOwner,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      phone: json['phone'],
      profilePictureUrl: json['profilePictureUrl'],
      familyId: json['familyId'],
      isOwner: json['isOwner'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Get display name with priority: firstName+lastName > fullName > email username
  String get displayName {
    if (firstName != null && firstName!.isNotEmpty && 
        lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return email.split('@')[0];
  }

  /// Check if user has complete name info
  bool get hasCompleteName {
    return (firstName != null && firstName!.isNotEmpty && 
            lastName != null && lastName!.isNotEmpty) ||
           (fullName != null && fullName!.isNotEmpty);
  }
}

class ProfileApiService {
  final _tokenStorage = TokenStorageService();
  final _sessionManager = SessionManager();
  final _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final accessToken = await _tokenStorage.getAccessToken();
    final sessionToken = await _tokenStorage.getSessionToken();
    
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (sessionToken != null) 'x-session-token': sessionToken,
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

      debugPrint('🔄 ProfileAPI: Refreshing token...');
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshPath}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionToken': sessionToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        final newSessionToken = data['sessionToken'];
        
        if (newAccessToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            sessionToken: newSessionToken ?? sessionToken,
            expiresIn: data['expiresIn']?.toString(),
          );
          debugPrint('✅ ProfileAPI: Token refreshed successfully');
          return true;
        }
      }
      
      debugPrint('❌ ProfileAPI: Token refresh failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ ProfileAPI: Token refresh error: $e');
      return false;
    }
  }

  /// Handle 401 errors by notifying session manager
  Never _handleSessionExpired() {
    _sessionManager.notifySessionExpired('Session expired');
    throw Exception('Session expired. Please login again.');
  }

  /// Get current user profile
  Future<UserProfile> getProfile() async {
    var headers = await _getHeaders();
    
    var response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: headers,
    );

    // Handle 401 - try to refresh token once
    if (response.statusCode == 401) {
      debugPrint('🔄 ProfileAPI: 401 received, attempting token refresh');
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry with new token
        headers = await _getHeaders();
        response = await _client.get(
          Uri.parse('${ApiConfig.baseUrl}/users/me'),
          headers: headers,
        );
      }
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data);
    } else if (response.statusCode == 401) {
      _handleSessionExpired();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load profile');
    }
  }

  /// Update user profile
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? phone,
  }) async {
    var headers = await _getHeaders();
    
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    
    var response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: headers,
      body: jsonEncode(body),
    );

    // Handle 401 - try to refresh token once
    if (response.statusCode == 401) {
      debugPrint('🔄 ProfileAPI: 401 received on update, attempting token refresh');
      final refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await _client.put(
          Uri.parse('${ApiConfig.baseUrl}/users/me'),
          headers: headers,
          body: jsonEncode(body),
        );
      }
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Update local storage with new profile data
      await _tokenStorage.saveUserProfile(
        firstName: data['firstName'],
        lastName: data['lastName'],
        fullName: data['fullName'],
        email: data['email'],
        profilePictureUrl: data['profilePictureUrl'],
      );
      
      return UserProfile.fromJson(data);
    } else if (response.statusCode == 401) {
      _handleSessionExpired();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update profile');
    }
  }

  /// Send verification code to current email (step 1 of email change)
  Future<void> sendEmailChangeCode() async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/users/email-change/send-code'),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      _handleSessionExpired();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send verification code');
    }
  }

  /// Verify the code sent to current email (step 2 of email change)
  Future<void> verifyEmailChangeCode(String code) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/users/email-change/verify-code'),
      headers: headers,
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      _handleSessionExpired();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Invalid verification code');
    }
  }

  /// Send verification code to new email (step 3 of email change)
  Future<void> sendNewEmailCode(String newEmail) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/users/email-change/send-new-email-code'),
      headers: headers,
      body: jsonEncode({'newEmail': newEmail}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      _handleSessionExpired();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send verification code');
    }
  }

  /// Confirm email change with new email code (step 4 of email change)
  Future<UserProfile> confirmEmailChange(String newEmail, String code) async {
    final headers = await _getHeaders();
    
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/users/email-change/confirm'),
      headers: headers,
      body: jsonEncode({'newEmail': newEmail, 'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      
      // Update local storage with new email
      await _tokenStorage.saveUserProfile(
        firstName: data['firstName'],
        lastName: data['lastName'],
        fullName: data['fullName'],
        email: data['email'],
        profilePictureUrl: data['profilePictureUrl'],
      );
      
      return UserProfile.fromJson(data);
    } else if (response.statusCode == 401) {
      _handleSessionExpired();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to change email');
    }
  }

  /// Update profile picture URL (rate limited: 1 per day)
  Future<UserProfile> updateProfilePicture(String profilePictureUrl) async {
    var headers = await _getHeaders();
    
    var response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/users/me/profile-picture'),
      headers: headers,
      body: jsonEncode({'profilePictureUrl': profilePictureUrl}),
    );

    // Handle 401 - try to refresh token once
    if (response.statusCode == 401) {
      debugPrint('🔄 ProfileAPI: 401 received on profile picture update, attempting token refresh');
      final refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await _client.put(
          Uri.parse('${ApiConfig.baseUrl}/users/me/profile-picture'),
          headers: headers,
          body: jsonEncode({'profilePictureUrl': profilePictureUrl}),
        );
      }
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Update local storage with new profile picture
      await _tokenStorage.saveUserProfile(
        firstName: data['firstName'],
        lastName: data['lastName'],
        fullName: data['fullName'],
        email: data['email'],
        profilePictureUrl: data['profilePictureUrl'],
      );
      
      return UserProfile.fromJson(data);
    } else if (response.statusCode == 401) {
      _handleSessionExpired();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update profile picture');
    }
  }

  void dispose() {
    _client.close();
  }
}
