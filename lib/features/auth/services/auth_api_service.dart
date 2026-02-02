import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import '../../../core/config/api_config.dart';
import '../../../core/services/api_exception.dart';
import '../models/auth_request_models.dart';
import '../models/auth_response_models.dart';

/// Service for handling authentication API calls
class AuthApiService {
  final http.Client _client;

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Register a new user
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerPath}');

      final response = await _client
          .post(
            url,
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleRegisterResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Registration failed: ${e.toString()}');
    }
  }

  /// Login with email and password
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginPath}');

      final response = await _client
          .post(
            url,
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleAuthResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Login failed: ${e.toString()}');
    }
  }

  /// Login with Supabase OAuth
  Future<AuthResponse> supabaseLogin(SupabaseLoginRequest request) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.supabaseLoginPath}',
      );

      // Get Supabase access token for authentication
      final supabaseToken = Supabase.instance.client.auth.currentSession?.accessToken;
      if (supabaseToken == null) {
        throw ApiException(message: 'No Supabase session found');
      }

      final response = await _client
          .post(
            url,
            headers: ApiConfig.getAuthHeaders(supabaseToken),
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleAuthResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Supabase login failed: ${e.toString()}');
    }
  }

  /// Verify email with code
  Future<AuthResponse> verifyEmail(VerifyEmailRequest request) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyEmailPath}');

      final response = await _client
          .post(
            url,
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleAuthResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email verification failed: ${e.toString()}');
    }
  }

  /// Resend verification code
  Future<VerificationResponse> resendVerification(
    ResendVerificationRequest request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.resendVerificationPath}',
      );

      final response = await _client
          .post(
            url,
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleVerificationResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Resend verification failed: ${e.toString()}',
      );
    }
  }

  /// Refresh access token
  Future<AuthResponse> refreshToken(RefreshTokenRequest request) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshPath}');

      final response = await _client
          .post(
            url,
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleAuthResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Token refresh failed: ${e.toString()}');
    }
  }

  /// Logout user
  Future<LogoutResponse> logout(String accessToken) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutPath}');

      final response = await _client
          .post(url, headers: ApiConfig.getAuthHeaders(accessToken))
          .timeout(ApiConfig.connectionTimeout);

      return _handleLogoutResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Logout failed: ${e.toString()}');
    }
  }

  // Response handlers

  RegisterResponse _handleRegisterResponse(http.Response response) {
    final data = _parseResponse(response);

    if (response.statusCode == 201) {
      return RegisterResponse.fromJson(data);
    } else {
      throw ApiException.fromResponse(response.statusCode, data);
    }
  }

  AuthResponse _handleAuthResponse(http.Response response) {
    final data = _parseResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponse.fromJson(data);
    } else {
      throw ApiException.fromResponse(response.statusCode, data);
    }
  }

  VerificationResponse _handleVerificationResponse(http.Response response) {
    final data = _parseResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return VerificationResponse.fromJson(data);
    } else {
      throw ApiException.fromResponse(response.statusCode, data);
    }
  }

  LogoutResponse _handleLogoutResponse(http.Response response) {
    final data = _parseResponse(response);

    if (response.statusCode == 200) {
      return LogoutResponse.fromJson(data);
    } else {
      throw ApiException.fromResponse(response.statusCode, data);
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  /// Request password reset - sends OTP to email
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/request-password-reset'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = _parseResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw ApiException.fromResponse(response.statusCode, data);
      }
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Password reset request failed: ${e.toString()}');
    }
  }

  /// Verify password reset code
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/verify-reset-code'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({'email': email, 'code': code}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = _parseResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw ApiException.fromResponse(response.statusCode, data);
      }
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Code verification failed: ${e.toString()}');
    }
  }

  /// Reset password with verified code
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({
              'email': email,
              'code': code,
              'newPassword': newPassword,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = _parseResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw ApiException.fromResponse(response.statusCode, data);
      }
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Password reset failed: ${e.toString()}');
    }
  }

  /// Dispose the client
  void dispose() {
    _client.close();
  }
}
