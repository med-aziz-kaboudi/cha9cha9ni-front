import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing authentication tokens securely
/// For production: Consider using flutter_secure_storage for better security
class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _sessionTokenKey = 'session_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _firstNameKey = 'user_first_name';
  static const String _lastNameKey = 'user_last_name';
  static const String _fullNameKey = 'user_full_name';
  static const String _userEmailKey = 'user_email';
  
  // Family info cache keys
  static const String _familyNameKey = 'family_name';
  static const String _familyOwnerNameKey = 'family_owner_name';
  static const String _familyMemberCountKey = 'family_member_count';
  static const String _familyIsOwnerKey = 'family_is_owner';
  static const String _familyInviteCodeKey = 'family_invite_code';

  /// Save authentication tokens
  Future<void> saveTokens({
    required String accessToken,
    required String sessionToken,
    String? expiresIn,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_sessionTokenKey, sessionToken);

    if (expiresIn != null) {
      await prefs.setString(_tokenExpiryKey, expiresIn);
    }

    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
  }

  /// Save user profile data
  Future<void> saveUserProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (firstName != null) {
      await prefs.setString(_firstNameKey, firstName);
    }
    if (lastName != null) {
      await prefs.setString(_lastNameKey, lastName);
    }
    if (fullName != null) {
      await prefs.setString(_fullNameKey, fullName);
    }
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    }
  }

  /// Get user display name with priority: firstName+lastName > fullName > email
  Future<String> getUserDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    
    final firstName = prefs.getString(_firstNameKey);
    final lastName = prefs.getString(_lastNameKey);
    final fullName = prefs.getString(_fullNameKey);
    final email = prefs.getString(_userEmailKey);
    
    // Priority 1: firstName + lastName (from email/password signup)
    if (firstName != null && firstName.isNotEmpty && 
        lastName != null && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    
    // Priority 2: fullName (from Google OAuth)
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    
    // Priority 3: email username
    if (email != null && email.isNotEmpty) {
      return email.split('@')[0];
    }
    
    return 'User';
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get session token
  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// Get token expiry
  Future<String?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenExpiryKey);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Get user's last name
  Future<String?> getUserLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNameKey);
  }

  /// Get user's first name
  Future<String?> getUserFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firstNameKey);
  }

  /// Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final sessionToken = await getSessionToken();
    return accessToken != null && sessionToken != null;
  }

  /// Save family info for caching
  Future<void> saveFamilyInfo({
    String? familyName,
    String? ownerName,
    int? memberCount,
    bool? isOwner,
    String? inviteCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (familyName != null) {
      await prefs.setString(_familyNameKey, familyName);
    }
    if (ownerName != null) {
      await prefs.setString(_familyOwnerNameKey, ownerName);
    }
    if (memberCount != null) {
      await prefs.setInt(_familyMemberCountKey, memberCount);
    }
    if (isOwner != null) {
      await prefs.setBool(_familyIsOwnerKey, isOwner);
    }
    if (inviteCode != null) {
      await prefs.setString(_familyInviteCodeKey, inviteCode);
    }
  }

  /// Get cached family info
  Future<Map<String, dynamic>?> getCachedFamilyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    final familyName = prefs.getString(_familyNameKey);
    final ownerName = prefs.getString(_familyOwnerNameKey);
    final memberCount = prefs.getInt(_familyMemberCountKey);
    final isOwner = prefs.getBool(_familyIsOwnerKey);
    final inviteCode = prefs.getString(_familyInviteCodeKey);
    
    // Return null if no cached data
    if (familyName == null && ownerName == null) {
      return null;
    }
    
    return {
      'familyName': familyName,
      'ownerName': ownerName,
      'memberCount': memberCount,
      'isOwner': isOwner,
      'inviteCode': inviteCode,
    };
  }

  /// Clear family info cache
  Future<void> clearFamilyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_familyNameKey);
    await prefs.remove(_familyOwnerNameKey);
    await prefs.remove(_familyMemberCountKey);
    await prefs.remove(_familyIsOwnerKey);
    await prefs.remove(_familyInviteCodeKey);
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_userEmailKey);
    // Also clear family info on logout
    await clearFamilyInfo();
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
