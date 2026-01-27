import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/api_exception.dart';
import 'pack_models.dart';

/// Service for pack-related API calls
class PackApiService {
  final http.Client _client;
  final _tokenStorage = TokenStorageService();

  PackApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Get current pack details
  Future<CurrentPackData> getCurrentPack() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        throw ApiException(message: 'Not authenticated');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/pack/current');
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CurrentPackData.fromJson(data);
      } else {
        throw ApiException.fromResponse(
          response.statusCode, 
          jsonDecode(response.body),
        );
      }
    } on SocketException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to get pack data: $e');
    }
  }

  /// Get all available packs
  Future<AllPacksData> getAllPacks() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        throw ApiException(message: 'Not authenticated');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/pack/all');
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AllPacksData.fromJson(data);
      } else {
        throw ApiException.fromResponse(
          response.statusCode, 
          jsonDecode(response.body),
        );
      }
    } on SocketException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to get packs: $e');
    }
  }

  /// Get all aids for selection
  Future<AllAidsData> getAllAids() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        throw ApiException(message: 'Not authenticated');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/pack/aids');
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AllAidsData.fromJson(data);
      } else {
        throw ApiException.fromResponse(
          response.statusCode, 
          jsonDecode(response.body),
        );
      }
    } on SocketException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to get aids: $e');
    }
  }

  /// Select an aid for withdrawal
  Future<Map<String, dynamic>> selectAid(String aidId) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        throw ApiException(message: 'Not authenticated');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/pack/select-aid');
      final response = await _client
          .post(
            url,
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'aidId': aidId}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException.fromResponse(
          response.statusCode, 
          jsonDecode(response.body),
        );
      }
    } on SocketException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to select aid: $e');
    }
  }

  /// Get ads statistics
  Future<FamilyAdsStats> getAdsStats() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        throw ApiException(message: 'Not authenticated');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/pack/ads-stats');
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FamilyAdsStats.fromJson(data);
      } else {
        throw ApiException.fromResponse(
          response.statusCode, 
          jsonDecode(response.body),
        );
      }
    } on SocketException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to get ads stats: $e');
    }
  }
}
