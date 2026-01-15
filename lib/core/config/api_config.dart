/// API Configuration
class ApiConfig {
  // Base URL - Update this to your backend URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000', // Change for production
  );

  // API Endpoints
  static const String authEndpoint = '/auth';

  // Auth routes
  static const String registerPath = '$authEndpoint/register';
  static const String loginPath = '$authEndpoint/login';
  static const String supabaseLoginPath = '$authEndpoint/supabase-login';
  static const String verifyEmailPath = '$authEndpoint/verify-email';
  static const String resendVerificationPath =
      '$authEndpoint/resend-verification';
  static const String refreshPath = '$authEndpoint/refresh';
  static const String logoutPath = '$authEndpoint/logout';

  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
