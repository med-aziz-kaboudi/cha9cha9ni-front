import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/family_model.dart';
import '../services/token_storage_service.dart';

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
    final headers = await _getHeaders();
    
    debugPrint('🔍 Calling GET /family/me');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/family/me'),
      headers: headers,
    );

    debugPrint('📡 Response status: ${response.statusCode}');
    debugPrint('📦 Response body: ${response.body}');

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
}
