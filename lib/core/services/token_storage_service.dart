import 'dart:convert';
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
  static const String _userPhoneKey = 'user_phone';
  static const String _profileLastFetchedKey = 'profile_last_fetched';
  
  // Family info cache keys
  static const String _familyNameKey = 'family_name';
  static const String _familyOwnerNameKey = 'family_owner_name';
  static const String _familyMemberCountKey = 'family_member_count';
  static const String _familyIsOwnerKey = 'family_is_owner';
  static const String _familyInviteCodeKey = 'family_invite_code';
  static const String _familyMembersKey = 'family_members_json';
  static const String _familyLastFetchedKey = 'family_last_fetched';
  static const String _pendingRemovalsKey = 'pending_removals_json';

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
    String? phone,
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
    if (phone != null) {
      await prefs.setString(_userPhoneKey, phone);
    }
    // Save timestamp of when profile was fetched/saved
    await prefs.setInt(_profileLastFetchedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached user profile data
  Future<Map<String, String?>> getCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'firstName': prefs.getString(_firstNameKey),
      'lastName': prefs.getString(_lastNameKey),
      'fullName': prefs.getString(_fullNameKey),
      'email': prefs.getString(_userEmailKey),
      'phone': prefs.getString(_userPhoneKey),
    };
  }

  /// Check if profile data was fetched recently (within threshold seconds)
  Future<bool> isProfileDataFresh({int thresholdSeconds = 60}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetched = prefs.getInt(_profileLastFetchedKey);
    
    if (lastFetched == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final ageSeconds = (now - lastFetched) / 1000;
    
    return ageSeconds < thresholdSeconds;
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
    // Save timestamp of when data was fetched
    await prefs.setInt(_familyLastFetchedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if family data was fetched recently (within threshold seconds)
  Future<bool> isFamilyDataFresh({int thresholdSeconds = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetched = prefs.getInt(_familyLastFetchedKey);
    
    if (lastFetched == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final ageSeconds = (now - lastFetched) / 1000;
    
    return ageSeconds < thresholdSeconds;
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

  /// Save family members to cache
  Future<void> saveFamilyMembers(List<Map<String, dynamic>> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_familyMembersKey, jsonEncode(members));
  }

  /// Get cached family members
  Future<List<Map<String, dynamic>>> getCachedFamilyMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = prefs.getString(_familyMembersKey);
    if (membersJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(membersJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Save pending removal requests to cache
  Future<void> savePendingRemovals(List<Map<String, dynamic>> removals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRemovalsKey, jsonEncode(removals));
  }

  /// Get cached pending removal requests
  Future<List<Map<String, dynamic>>> getCachedPendingRemovals() async {
    final prefs = await SharedPreferences.getInstance();
    final removalsJson = prefs.getString(_pendingRemovalsKey);
    if (removalsJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(removalsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Update a single member's pending removal status in cache
  Future<void> updateMemberPendingStatus({
    required String memberId,
    required bool hasPendingRemoval,
    String? pendingRemovalRequestId,
    String? pendingRemovalStatus,
  }) async {
    final members = await getCachedFamilyMembers();
    final updatedMembers = members.map((m) {
      if (m['id'] == memberId) {
        return {
          ...m,
          'hasPendingRemoval': hasPendingRemoval,
          'pendingRemovalRequestId': pendingRemovalRequestId,
          'pendingRemovalStatus': pendingRemovalStatus,
        };
      }
      return m;
    }).toList();
    await saveFamilyMembers(updatedMembers);
  }

  /// Clear family info cache
  Future<void> clearFamilyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_familyNameKey);
    await prefs.remove(_familyOwnerNameKey);
    await prefs.remove(_familyMemberCountKey);
    await prefs.remove(_familyIsOwnerKey);
    await prefs.remove(_familyInviteCodeKey);
    await prefs.remove(_familyMembersKey);
    await prefs.remove(_pendingRemovalsKey);
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

  static const List<String> _persistentKeys = [
    'tutorial_completed',
    'language_code',
  ];

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final preservedValues = <String, dynamic>{};
    for (final key in _persistentKeys) {
      if (prefs.containsKey(key)) {
        preservedValues[key] = prefs.get(key);
      }
    }
    await prefs.clear();
    for (final entry in preservedValues.entries) {
      if (entry.value is bool) {
        await prefs.setBool(entry.key, entry.value);
      } else if (entry.value is String) {
        await prefs.setString(entry.key, entry.value);
      } else if (entry.value is int) {
        await prefs.setInt(entry.key, entry.value);
      } else if (entry.value is double) {
        await prefs.setDouble(entry.key, entry.value);
      }
    }
  }
}
