import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/session_manager.dart';
import 'rewards_model.dart';

class RewardsApiService {
  final _baseUrl = ApiConfig.baseUrl;
  final _tokenStorage = TokenStorageService();
  final _sessionManager = SessionManager();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _refreshToken() async {
    try {
      final sessionToken = await _tokenStorage.getSessionToken();
      if (sessionToken == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.refreshPath}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sessionToken': sessionToken}),
      );

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
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    }
  }

  Future<http.Response> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    var headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl$path');

    http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else {
      response = await http.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
    }

    // Handle 401 - try refresh
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        if (method == 'GET') {
          response = await http.get(uri, headers: headers);
        } else {
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
        }
      }

      if (response.statusCode == 401) {
        _sessionManager.notifySessionExpired('Session expired');
        throw Exception('Session expired. Please sign in again.');
      }
    }

    return response;
  }

  /// Get rewards data for the current user
  Future<RewardsData> getRewardsData() async {
    final response = await _makeRequest('GET', '/rewards');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return RewardsData.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch rewards data');
    }
  }

  /// Claim reward after watching an ad
  Future<ClaimRewardResult> claimReward(String clientEventId) async {
    final response = await _makeRequest(
      'POST',
      '/rewards/claim',
      body: {'clientEventId': clientEventId},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return ClaimRewardResult.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to claim reward');
    }
  }

  /// Get daily check-in status
  Future<DailyCheckInStatus> getCheckInStatus() async {
    final response = await _makeRequest('GET', '/rewards/checkin/status');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DailyCheckInStatus.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get check-in status');
    }
  }

  /// Perform daily check-in
  Future<DailyCheckInResult> performCheckIn() async {
    final response = await _makeRequest('POST', '/rewards/checkin');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return DailyCheckInResult.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to check in');
    }
  }
}
