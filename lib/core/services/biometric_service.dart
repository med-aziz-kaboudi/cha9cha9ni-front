import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'token_storage_service.dart';

/// Security settings from the backend
class SecuritySettings {
  final bool biometricEnabled;
  final bool passkeyEnabled;
  final bool hasPassword;
  final bool totpEnabled;
  final int lockoutLevel;
  final DateTime? lockedUntil;
  final bool permanentlyLocked;
  final int failedAttempts;
  final int maxAttempts;

  SecuritySettings({
    required this.biometricEnabled,
    required this.passkeyEnabled,
    required this.hasPassword,
    required this.totpEnabled,
    required this.lockoutLevel,
    this.lockedUntil,
    required this.permanentlyLocked,
    required this.failedAttempts,
    required this.maxAttempts,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      biometricEnabled: json['biometricEnabled'] ?? false,
      passkeyEnabled: json['passkeyEnabled'] ?? false,
      hasPassword: json['hasPassword'] ?? false,
      totpEnabled: json['totpEnabled'] ?? false,
      lockoutLevel: json['lockoutLevel'] ?? 0,
      lockedUntil: json['lockedUntil'] != null 
        ? DateTime.parse(json['lockedUntil']) 
        : null,
      permanentlyLocked: json['permanentlyLocked'] ?? false,
      failedAttempts: json['failedAttempts'] ?? 0,
      maxAttempts: json['maxAttempts'] ?? 3,
    );
  }

  bool get isSecurityEnabled => biometricEnabled || passkeyEnabled || totpEnabled;
  
  bool get isLocked {
    if (permanentlyLocked) return true;
    if (lockedUntil == null) return false;
    return lockedUntil!.isAfter(DateTime.now());
  }

  Duration? get remainingLockTime {
    if (lockedUntil == null || !isLocked) return null;
    return lockedUntil!.difference(DateTime.now());
  }
}

/// Unlock status from the backend
class UnlockStatus {
  final bool securityEnabled;
  final bool biometricEnabled;
  final bool passkeyEnabled;
  final bool totpEnabled;
  final bool isLocked;
  final bool permanentlyLocked;
  final DateTime? lockedUntil;
  final int remainingSeconds;
  final int lockoutLevel;
  final int failedAttempts;
  final int maxAttempts;

  UnlockStatus({
    required this.securityEnabled,
    required this.biometricEnabled,
    required this.passkeyEnabled,
    this.totpEnabled = false,
    required this.isLocked,
    required this.permanentlyLocked,
    this.lockedUntil,
    required this.remainingSeconds,
    required this.lockoutLevel,
    required this.failedAttempts,
    required this.maxAttempts,
  });

  factory UnlockStatus.fromJson(Map<String, dynamic> json) {
    return UnlockStatus(
      securityEnabled: json['securityEnabled'] ?? false,
      biometricEnabled: json['biometricEnabled'] ?? false,
      passkeyEnabled: json['passkeyEnabled'] ?? false,
      totpEnabled: json['totpEnabled'] ?? false,
      isLocked: json['isLocked'] ?? false,
      permanentlyLocked: json['permanentlyLocked'] ?? false,
      lockedUntil: json['lockedUntil'] != null 
        ? DateTime.parse(json['lockedUntil']) 
        : null,
      remainingSeconds: json['remainingSeconds'] ?? 0,
      lockoutLevel: json['lockoutLevel'] ?? 0,
      failedAttempts: json['failedAttempts'] ?? 0,
      maxAttempts: json['maxAttempts'] ?? 3,
    );
  }
}

/// Result of unlock attempt
class UnlockResult {
  final bool success;
  final String? message;
  final int? remainingAttempts;
  final bool? isLocked;
  final bool? permanentlyLocked;
  final int? remainingSeconds;
  final int? lockoutLevel;

  UnlockResult({
    required this.success,
    this.message,
    this.remainingAttempts,
    this.isLocked,
    this.permanentlyLocked,
    this.remainingSeconds,
    this.lockoutLevel,
  });
}

/// TOTP Setup response
class TotpSetupResponse {
  final String secret;
  final String qrCodeUrl;
  final String issuer;
  final String accountName;

  TotpSetupResponse({
    required this.secret,
    required this.qrCodeUrl,
    required this.issuer,
    required this.accountName,
  });

  factory TotpSetupResponse.fromJson(Map<String, dynamic> json) {
    return TotpSetupResponse(
      secret: json['secret'] ?? '',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      issuer: json['issuer'] ?? '',
      accountName: json['accountName'] ?? '',
    );
  }
}

/// Generic result for 2FA operations
class TotpResult {
  final bool success;
  final String? message;
  final String? error;
  final bool? enabled;

  TotpResult({
    required this.success,
    this.message,
    this.error,
    this.enabled,
  });
}

/// Service for managing biometric authentication and app security
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final TokenStorageService _tokenStorage = TokenStorageService();
  
  // Local cache key for quick check
  static const String _securityEnabledKey = 'security_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _passkeyEnabledKey = 'passkey_enabled';

  // API base URL - Use the same as the rest of the app
  String get _apiBaseUrl {
    return 'https://api.cha9cha9ni.tn';
  }

  /// Check if device supports biometric authentication
  Future<bool> canUseBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types (Face ID, Touch ID, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Check if Face ID is available (iOS)
  Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if fingerprint/Touch ID is available
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Authenticate using device biometrics (Face ID / Touch ID)
  /// Returns true if authentication was successful
  Future<bool> authenticateWithBiometrics({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.code} - ${e.message}');
      if (e.code == auth_error.notEnrolled) {
        // No biometrics enrolled on device
        return false;
      } else if (e.code == auth_error.lockedOut) {
        // Too many attempts, temporarily locked
        return false;
      } else if (e.code == auth_error.permanentlyLockedOut) {
        // Permanently locked, need device passcode
        return false;
      }
      return false;
    }
  }

  /// Get security settings from backend
  Future<SecuritySettings?> getSecuritySettings() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final settings = SecuritySettings.fromJson(data);
        
        // Cache locally for quick checks
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_securityEnabledKey, settings.isSecurityEnabled);
        await prefs.setBool(_biometricEnabledKey, settings.biometricEnabled);
        await prefs.setBool(_passkeyEnabledKey, settings.passkeyEnabled);
        
        return settings;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting security settings: $e');
      return null;
    }
  }

  /// Get unlock status from backend
  Future<UnlockStatus?> getUnlockStatus() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/unlock-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UnlockStatus.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting unlock status: $e');
      return null;
    }
  }

  /// Quick check if security is enabled (from local cache)
  Future<bool> isSecurityEnabledLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_securityEnabledKey) ?? false;
  }

  /// Quick check if biometric is enabled (from local cache)
  Future<bool> isBiometricEnabledLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable biometric authentication
  Future<({bool success, String? error})> enableBiometric() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return (success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/biometric'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'enabled': true}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, true);
        await prefs.setBool(_securityEnabledKey, true);
        return (success: true, error: null);
      } else {
        final data = json.decode(response.body);
        return (success: false, error: (data['message'] as String?) ?? 'Failed to enable biometric');
      }
    } catch (e) {
      debugPrint('Error enabling biometric: $e');
      return (success: false, error: 'Network error');
    }
  }

  /// Disable biometric authentication
  Future<({bool success, String? error})> disableBiometric() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return (success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/biometric'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'enabled': false}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, false);
        return (success: true, error: null);
      } else {
        final data = json.decode(response.body);
        return (success: false, error: (data['message'] as String?) ?? 'Failed to disable biometric');
      }
    } catch (e) {
      debugPrint('Error disabling biometric: $e');
      return (success: false, error: 'Network error');
    }
  }

  /// Set up a 6-digit passkey
  Future<({bool success, String? error})> setupPasskey(String passkey) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return (success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/setup-passkey'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'passkey': passkey}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_passkeyEnabledKey, true);
        await prefs.setBool(_securityEnabledKey, true);
        return (success: true, error: null);
      } else {
        final data = json.decode(response.body);
        return (success: false, error: (data['message'] as String?) ?? 'Failed to setup passkey');
      }
    } catch (e) {
      debugPrint('Error setting up passkey: $e');
      return (success: false, error: 'Network error');
    }
  }

  /// Change passkey
  Future<({bool success, String? error})> changePasskey(String currentPasskey, String newPasskey) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return (success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/change-passkey'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPasskey': currentPasskey,
          'newPasskey': newPasskey,
        }),
      );

      if (response.statusCode == 200) {
        return (success: true, error: null);
      } else {
        final data = json.decode(response.body);
        return (success: false, error: (data['message'] as String?) ?? 'Failed to change passkey');
      }
    } catch (e) {
      debugPrint('Error changing passkey: $e');
      return (success: false, error: 'Network error');
    }
  }

  /// Remove passkey (and biometric)
  Future<({bool success, String? error})> removePasskey(String currentPasskey) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return (success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/remove-passkey'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'passkey': currentPasskey}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_passkeyEnabledKey, false);
        await prefs.setBool(_biometricEnabledKey, false);
        await prefs.setBool(_securityEnabledKey, false);
        return (success: true, error: null);
      } else {
        final data = json.decode(response.body);
        return (success: false, error: (data['message'] as String?) ?? 'Failed to remove passkey');
      }
    } catch (e) {
      debugPrint('Error removing passkey: $e');
      return (success: false, error: 'Network error');
    }
  }

  /// Verify app unlock (biometric or passkey)
  /// This should be called on app resume when security is enabled
  Future<UnlockResult> verifyAppUnlock({
    required bool useBiometric,
    String? passkey,
  }) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return UnlockResult(success: false, message: 'Not authenticated');
      }

      // If using biometric, verify locally first
      if (useBiometric) {
        final biometricSuccess = await authenticateWithBiometrics(
          reason: 'Authenticate to unlock the app',
        );
        
        if (!biometricSuccess) {
          // Biometric failed locally, don't send to server
          // User should fall back to passkey
          return UnlockResult(
            success: false,
            message: 'Biometric authentication failed',
          );
        }
      }

      // Send verification to backend
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/unlock'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'method': useBiometric ? 'biometric' : 'passkey',
          if (!useBiometric && passkey != null) 'passkey': passkey,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return UnlockResult(success: true, message: data['message']);
      } else if (response.statusCode == 401) {
        // Invalid passkey
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Invalid Pin code',
          remainingAttempts: data['remainingAttempts'],
        );
      } else if (response.statusCode == 429) {
        // Rate limited / locked
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Account locked',
          isLocked: true,
          remainingSeconds: data['remainingSeconds'],
          lockoutLevel: data['lockoutLevel'],
        );
      } else if (response.statusCode == 403) {
        // Permanently locked
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Account permanently locked',
          permanentlyLocked: true,
        );
      } else {
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Unlock failed',
        );
      }
    } catch (e) {
      debugPrint('Error verifying app unlock: $e');
      return UnlockResult(success: false, message: 'Network error');
    }
  }

  /// Clear local security cache (on logout)
  Future<void> clearSecurityCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_securityEnabledKey);
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_passkeyEnabledKey);
  }

  /// Change user password (requires current password verification)
  Future<({bool success, String? error})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return (success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return (success: true, error: null);
      } else {
        final data = json.decode(response.body);
        return (success: false, error: (data['message'] as String?) ?? 'Failed to change password');
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      return (success: false, error: 'Network error');
    }
  }

  /// Create password for OAuth users who don't have one
  Future<({bool success, String? error})> createPassword({
    required String newPassword,
  }) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return (success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/create-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return (success: true, error: null);
      } else {
        final data = json.decode(response.body);
        return (success: false, error: (data['message'] as String?) ?? 'Failed to create password');
      }
    } catch (e) {
      debugPrint('Error creating password: $e');
      return (success: false, error: 'Network error');
    }
  }

  // ==========================================
  // TWO-FACTOR AUTHENTICATION (TOTP)
  // ==========================================

  /// Set up 2FA - generates secret and QR code URL
  Future<TotpSetupResponse?> setupTotp() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/2fa/setup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TotpSetupResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error setting up TOTP: $e');
      return null;
    }
  }

  /// Verify TOTP code and enable 2FA
  Future<TotpResult> verifyAndEnableTotp(String code) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return TotpResult(success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/2fa/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_securityEnabledKey, true);
        
        return TotpResult(
          success: true,
          message: data['message'],
          enabled: data['enabled'],
        );
      } else {
        return TotpResult(
          success: false,
          error: data['message'] ?? 'Invalid verification code',
        );
      }
    } catch (e) {
      debugPrint('Error verifying TOTP: $e');
      return TotpResult(success: false, error: 'Network error');
    }
  }

  /// Disable 2FA (requires valid TOTP code)
  Future<TotpResult> disableTotp(String code) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return TotpResult(success: false, error: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/2fa/disable'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Refresh security settings
        await getSecuritySettings();
        
        return TotpResult(
          success: true,
          message: data['message'],
          enabled: false,
        );
      } else {
        return TotpResult(
          success: false,
          error: data['message'] ?? 'Invalid verification code',
        );
      }
    } catch (e) {
      debugPrint('Error disabling TOTP: $e');
      return TotpResult(success: false, error: 'Network error');
    }
  }

  /// Get 2FA status
  Future<bool> isTotpEnabled() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/2fa/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['enabled'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error getting TOTP status: $e');
      return false;
    }
  }

  /// Verify app unlock with TOTP
  Future<UnlockResult> verifyAppUnlockWithTotp(String code) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return UnlockResult(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/security/unlock'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'method': 'totp',
          'totpCode': code,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UnlockResult(success: true, message: data['message']);
      } else if (response.statusCode == 400) {
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Invalid code',
          remainingAttempts: data['remainingAttempts'],
        );
      } else if (response.statusCode == 429) {
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Account locked',
          isLocked: true,
          remainingSeconds: data['remainingSeconds'],
          lockoutLevel: data['lockoutLevel'],
        );
      } else if (response.statusCode == 403) {
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Account permanently locked',
          permanentlyLocked: true,
        );
      } else {
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Verification failed',
        );
      }
    } catch (e) {
      debugPrint('Error verifying TOTP unlock: $e');
      return UnlockResult(success: false, message: 'Network error');
    }
  }
}
