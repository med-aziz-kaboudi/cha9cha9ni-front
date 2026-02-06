import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/token_storage_service.dart';
import 'pack_api_service.dart';
import 'pack_models.dart';

/// Cache keys for pack data
class _PackCacheKeys {
  static const String currentPack = 'pack_current_data';
  static const String selectedAid = 'pack_selected_aid';
  static const String adsStats = 'pack_ads_stats';
  static const String lastFetchTime = 'pack_last_fetch';
}

/// Service for managing pack data with real-time updates and caching
class PackService {
  static final PackService _instance = PackService._internal();
  factory PackService() => _instance;
  PackService._internal();

  final _apiService = PackApiService();
  final _socketService = SocketService();
  final _tokenStorage = TokenStorageService();

  CurrentPackData? _currentData;
  FamilyAdsStats? _adsStats;
  SelectedAidModel? _selectedAid;
  String? _currentUserId;

  final _dataController = StreamController<CurrentPackData>.broadcast();
  final _adsStatsController = StreamController<FamilyAdsStats>.broadcast();

  StreamSubscription<AdsStatsUpdatedData>? _adsStatsSubscription;
  StreamSubscription<AidSelectedData>? _aidSelectedSubscription;
  StreamSubscription<AidRemovedData>? _aidRemovedSubscription;
  StreamSubscription<PackUpdatedData>? _packUpdatedSubscription;
  bool _initialized = false;
  bool _hasFetchedOnce = false;

  /// Stream of pack data updates
  Stream<CurrentPackData> get dataStream => _dataController.stream;

  /// Stream of ads stats updates
  Stream<FamilyAdsStats> get adsStatsStream => _adsStatsController.stream;

  /// Current pack data (from memory or will load from cache)
  CurrentPackData? get currentData => _currentData;

  /// Current selected aid
  SelectedAidModel? get selectedAid => _selectedAid;

  /// Current ads stats
  FamilyAdsStats? get adsStats => _adsStats;

  /// Whether data has been fetched at least once this session
  bool get hasFetchedOnce => _hasFetchedOnce;

  /// Initialize the service and listen for real-time updates
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Get current user ID for matching socket events
    _currentUserId = await _tokenStorage.getUserId();

    // If userId is null, try to extract from access token
    if (_currentUserId == null) {
      _currentUserId = await _extractUserIdFromToken();
    }

    debugPrint('📦 PackService: Current user ID loaded: $_currentUserId');

    // Load cached data first for instant display
    await _loadFromCache();

    // Listen to socket events for real-time updates
    _listenToSocketEvents();

    debugPrint('📦 PackService: Initialized with cache');
  }

  /// Extract userId from JWT access token payload (base64 decode)
  Future<String?> _extractUserIdFromToken() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) return null;

      // JWT format: header.payload.signature
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (middle part)
      String payload = parts[1];
      // Add padding if needed for base64
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decodedPayload = utf8.decode(base64Url.decode(payload));
      final payloadMap = jsonDecode(decodedPayload) as Map<String, dynamic>;

      // The user ID is typically in 'sub' or 'userId' field
      final userId = payloadMap['sub'] ?? payloadMap['userId'];
      if (userId != null) {
        debugPrint('📦 PackService: Extracted userId from JWT: $userId');
        // Save it for future use
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          sessionToken: (await _tokenStorage.getSessionToken()) ?? '',
          userId: userId.toString(),
        );
        return userId.toString();
      }
      return null;
    } catch (e) {
      debugPrint('📦 PackService: Failed to extract userId from token: $e');
      return null;
    }
  }

  /// Load cached data from SharedPreferences
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load selected aid from cache
      final aidJson = prefs.getString(_PackCacheKeys.selectedAid);
      if (aidJson != null) {
        final aidData = jsonDecode(aidJson) as Map<String, dynamic>;
        _selectedAid = SelectedAidModel.fromJson(aidData);
        debugPrint(
          '📦 PackService: Loaded selected aid from cache: ${_selectedAid?.aidDisplayName}',
        );
      }

      // Load current pack from cache
      final packJson = prefs.getString(_PackCacheKeys.currentPack);
      if (packJson != null) {
        final packData = jsonDecode(packJson) as Map<String, dynamic>;
        _currentData = CurrentPackData.fromJson(packData);
        _adsStats = _currentData!.adsStats;
        if (_currentData!.selectedAids.isNotEmpty) {
          _selectedAid = _currentData!.selectedAids.first;
        }
        debugPrint('📦 PackService: Loaded pack data from cache');
      }
    } catch (e) {
      debugPrint('📦 PackService: Failed to load from cache - $e');
    }
  }

  /// Save current data to cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_selectedAid != null) {
        await prefs.setString(
          _PackCacheKeys.selectedAid,
          jsonEncode(_selectedAidToJson(_selectedAid!)),
        );
      } else {
        // Remove cached selected aid when null
        await prefs.remove(_PackCacheKeys.selectedAid);
      }

      if (_currentData != null) {
        await prefs.setString(
          _PackCacheKeys.currentPack,
          jsonEncode(_currentPackToJson(_currentData!)),
        );
      }

      await prefs.setInt(
        _PackCacheKeys.lastFetchTime,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('📦 PackService: Saved to cache');
    } catch (e) {
      debugPrint('📦 PackService: Failed to save to cache - $e');
    }
  }

  /// Convert SelectedAidModel to JSON for caching
  Map<String, dynamic> _selectedAidToJson(SelectedAidModel aid) {
    return {
      'id': aid.id,
      'aidId': aid.aidId,
      'aidName': aid.aidName,
      'aidDisplayName': aid.aidDisplayName,
      'maxWithdrawal': aid.maxWithdrawal,
      'aidStartDate': aid.aidStartDate,
      'aidEndDate': aid.aidEndDate,
      'withdrawalStartDate': aid.withdrawalStartDate,
      'withdrawalEndDate': aid.withdrawalEndDate,
      'status': aid.status,
      'withdrawnAmount': aid.withdrawnAmount,
      'withdrawnAt': aid.withdrawnAt?.toIso8601String(),
    };
  }

  /// Convert CurrentPackData to JSON for caching
  Map<String, dynamic> _currentPackToJson(CurrentPackData data) {
    return {
      'pack': {
        'id': data.pack.id,
        'name': data.pack.name,
        'displayName': data.pack.displayName,
        'priceMonthly': data.pack.priceMonthly,
        'priceYearly': data.pack.priceYearly,
        'withdrawalsPerYear': data.pack.withdrawalsPerYear,
        'maxAidsSelectable': data.pack.maxAidsSelectable,
        'maxFamilyMembers': data.pack.maxFamilyMembers,
      },
      'subscription': {
        'status': data.subscription.status,
        'billingCycle': data.subscription.billingCycle,
        'startDate': data.subscription.startDate.toIso8601String(),
        'endDate': data.subscription.endDate?.toIso8601String(),
        'withdrawalsUsed': data.subscription.withdrawalsUsed,
        'withdrawalsRemaining': data.subscription.withdrawalsRemaining,
      },
      'familyMembers': {
        'current': data.currentFamilyMembers,
        'max': data.maxFamilyMembers,
      },
      'withdrawAccess': {
        'canWithdraw': data.withdrawAccess.canWithdraw,
        'isOwner': data.withdrawAccess.isOwner,
        'isKycVerified': data.withdrawAccess.isKycVerified,
        'kycStatus': data.withdrawAccess.kycStatus,
      },
      'selectedAids': data.selectedAids
          .map((a) => _selectedAidToJson(a))
          .toList(),
      'adsStats': {
        'familyTotalAdsToday': data.adsStats.familyTotalAdsToday,
        'familyMaxAdsToday': data.adsStats.familyMaxAdsToday,
        'userAdsToday': data.adsStats.userAdsToday,
        'userMaxAds': data.adsStats.userMaxAds,
        'memberCount': data.adsStats.memberCount,
      },
    };
  }

  void _listenToSocketEvents() {
    // Listen for ads_stats_updated events from the socket
    _adsStatsSubscription?.cancel();
    _adsStatsSubscription = _socketService.onAdsStatsUpdated.listen((data) {
      debugPrint('📦 PackService: Received ads_stats_updated via socket');
      _handleAdsStatsUpdate(data);
    });

    // Listen for aid_selected events from socket (real-time aid selection)
    _aidSelectedSubscription?.cancel();
    _aidSelectedSubscription = _socketService.onAidSelected.listen((data) {
      debugPrint(
        '📦 PackService: Received aid_selected via socket - ${data.aidDisplayName}',
      );
      _handleAidSelectedFromSocket(data);
    });

    // Listen for aid_removed events from socket
    _aidRemovedSubscription?.cancel();
    _aidRemovedSubscription = _socketService.onAidRemoved.listen((data) {
      debugPrint(
        '📦 PackService: Received aid_removed via socket - ${data.aidDisplayName}',
      );
      _handleAidRemovedFromSocket(data);
    });

    // Listen for pack_updated events (trigger full refresh)
    _packUpdatedSubscription?.cancel();
    _packUpdatedSubscription = _socketService.onPackUpdated.listen((data) {
      debugPrint(
        '📦 PackService: Received pack_updated via socket - reason: ${data.reason}',
      );
      _handlePackUpdatedFromSocket(data);
    });
  }

  /// Handle real-time aid selection from socket
  void _handleAidSelectedFromSocket(AidSelectedData data) {
    final newAid = SelectedAidModel(
      id: data.aidId,
      aidId: data.aidId,
      aidName: data.aidName,
      aidDisplayName: data.aidDisplayName,
      maxWithdrawal: data.maxWithdrawal,
      aidStartDate: data.aidStartDate,
      aidEndDate: data.aidEndDate,
      withdrawalStartDate: data.withdrawalStartDate,
      withdrawalEndDate: data.withdrawalEndDate,
      status: 'selected',
    );

    _selectedAid = newAid;

    // Update current data if available
    if (_currentData != null) {
      // Add new aid to selected aids (or replace if it's a single selection pack)
      final updatedAids = [..._currentData!.selectedAids];
      // Check if already exists
      final existingIndex = updatedAids.indexWhere(
        (a) => a.aidId == newAid.aidId,
      );
      if (existingIndex == -1) {
        updatedAids.add(newAid);
      }

      _currentData = CurrentPackData(
        pack: _currentData!.pack,
        subscription: _currentData!.subscription,
        currentFamilyMembers: _currentData!.currentFamilyMembers,
        maxFamilyMembers: _currentData!.maxFamilyMembers,
        withdrawAccess: _currentData!.withdrawAccess,
        selectedAids: updatedAids,
        allAids: _currentData!.allAids,
        adsStats: _currentData!.adsStats,
      );
      _dataController.add(_currentData!);
      debugPrint('📦 PackService: Emitted updated data to stream (aid added)');
    }

    // Save to cache
    _saveToCache();
  }

  /// Handle real-time aid removal from socket
  void _handleAidRemovedFromSocket(AidRemovedData data) {
    debugPrint(
      '📦 PackService: Processing aid removal - ${data.aidDisplayName}',
    );

    // Update current data if available
    if (_currentData != null) {
      final updatedAids = _currentData!.selectedAids
          .where((a) => a.aidId != data.aidId)
          .toList();

      _currentData = CurrentPackData(
        pack: _currentData!.pack,
        subscription: _currentData!.subscription,
        currentFamilyMembers: _currentData!.currentFamilyMembers,
        maxFamilyMembers: _currentData!.maxFamilyMembers,
        withdrawAccess: _currentData!.withdrawAccess,
        selectedAids: updatedAids,
        allAids: _currentData!.allAids,
        adsStats: _currentData!.adsStats,
      );
      _dataController.add(_currentData!);
      debugPrint(
        '📦 PackService: Emitted updated data to stream (aid removed)',
      );
    }

    // Clear selected aid if it matches
    if (_selectedAid?.aidId == data.aidId) {
      _selectedAid = null;
    }

    // Save to cache
    _saveToCache();
  }

  /// Handle pack_updated event - trigger a full refresh
  void _handlePackUpdatedFromSocket(PackUpdatedData data) {
    debugPrint(
      '📦 PackService: Pack updated notification received, triggering refresh',
    );
    // Force refresh the pack data from API
    fetchCurrentPack(forceRefresh: true)
        .then((_) {
          debugPrint(
            '📦 PackService: Pack data refreshed after socket notification',
          );
        })
        .catchError((e) {
          debugPrint('📦 PackService: Error refreshing pack data: $e');
        });
  }

  void _handleAdsStatsUpdate(AdsStatsUpdatedData data) {
    // Determine userAdsToday: if this socket event is for the current user,
    // use the userAdsToday from the event. Otherwise, keep existing value.
    int userAdsToday = _adsStats?.userAdsToday ?? 0;

    debugPrint(
      '📦 PackService: Comparing userIds - socket: "${data.userId}", local: "$_currentUserId"',
    );

    if (data.userId != null &&
        data.userId == _currentUserId &&
        data.userAdsToday != null) {
      // This update is for the current user - use the new value
      userAdsToday = data.userAdsToday!;
      debugPrint(
        '📦 PackService: Updated userAdsToday from socket: $userAdsToday (current user matched!)',
      );
    } else if (data.userId != null && data.userId != _currentUserId) {
      // This update is for another family member - keep our personal count
      debugPrint(
        '📦 PackService: Family member ${data.userId} watched an ad, keeping local userAdsToday: $userAdsToday',
      );
    } else {
      debugPrint(
        '📦 PackService: No userId match - userId: ${data.userId}, userAdsToday: ${data.userAdsToday}',
      );
    }

    final newStats = FamilyAdsStats(
      familyTotalAdsToday: data.familyTotalAdsToday,
      familyMaxAdsToday: data.familyMaxAdsToday,
      userAdsToday: userAdsToday,
      userMaxAds: 5,
      memberCount: data.memberCount,
    );

    debugPrint(
      '📦 PackService: Emitting new stats - familyTotal: ${newStats.familyTotalAdsToday}, userAdsToday: ${newStats.userAdsToday}',
    );

    _adsStats = newStats;
    _adsStatsController.add(newStats);

    // Also update current data if available
    if (_currentData != null) {
      _currentData = CurrentPackData(
        pack: _currentData!.pack,
        subscription: _currentData!.subscription,
        currentFamilyMembers: _currentData!.currentFamilyMembers,
        maxFamilyMembers: _currentData!.maxFamilyMembers,
        withdrawAccess: _currentData!.withdrawAccess,
        selectedAids: _currentData!.selectedAids,
        allAids: _currentData!.allAids,
        adsStats: newStats,
      );
      _dataController.add(_currentData!);
      debugPrint('📦 PackService: Emitted updated CurrentPackData to stream');
    } else {
      debugPrint(
        '📦 PackService: _currentData is null, only ads stats stream updated',
      );
    }

    // Save to cache
    _saveToCache();
  }

  /// Get cached selected aid (no API call)
  SelectedAidModel? getCachedSelectedAid() {
    return _selectedAid ??
        (_currentData?.selectedAids.isNotEmpty == true
            ? _currentData!.selectedAids.first
            : null);
  }

  /// Fetch current pack data from API (call only once per session)
  Future<CurrentPackData> fetchCurrentPack({bool forceRefresh = false}) async {
    // Return cached data if already fetched and not forcing refresh
    if (_hasFetchedOnce && !forceRefresh && _currentData != null) {
      debugPrint('📦 PackService: Returning cached data (already fetched)');
      return _currentData!;
    }

    try {
      final data = await _apiService.getCurrentPack();
      _currentData = data;
      _adsStats = data.adsStats;
      // Update selected aid - set to first if available, null if empty
      _selectedAid = data.selectedAids.isNotEmpty 
          ? data.selectedAids.first 
          : null;
      _hasFetchedOnce = true;

      _dataController.add(data);
      _adsStatsController.add(data.adsStats);

      // Save to cache for next app launch
      await _saveToCache();

      debugPrint('📦 PackService: Fetched and cached pack data (selectedAid: ${_selectedAid?.aidDisplayName ?? 'none'})');
      return data;
    } catch (e) {
      debugPrint('📦 PackService: Failed to fetch pack - $e');
      // If we have cached data, return it even on error
      if (_currentData != null) {
        debugPrint('📦 PackService: Returning stale cached data');
        return _currentData!;
      }
      rethrow;
    }
  }

  /// Fetch all available packs
  Future<AllPacksData> fetchAllPacks() async {
    try {
      return await _apiService.getAllPacks();
    } catch (e) {
      debugPrint('📦 PackService: Failed to fetch all packs - $e');
      rethrow;
    }
  }

  /// Fetch all aids for selection
  Future<AllAidsData> fetchAllAids() async {
    try {
      return await _apiService.getAllAids();
    } catch (e) {
      debugPrint('📦 PackService: Failed to fetch aids - $e');
      rethrow;
    }
  }

  /// Select an aid (will trigger socket event to all family members)
  Future<void> selectAid(String aidId) async {
    try {
      await _apiService.selectAid(aidId);
      // Refresh data after selection (force refresh to get updated selectedAids)
      await fetchCurrentPack(forceRefresh: true);
    } catch (e) {
      debugPrint('📦 PackService: Failed to select aid - $e');
      rethrow;
    }
  }

  /// Refresh ads stats
  Future<void> refreshAdsStats() async {
    try {
      final stats = await _apiService.getAdsStats();
      _adsStats = stats;
      _adsStatsController.add(stats);
      await _saveToCache();
    } catch (e) {
      debugPrint('📦 PackService: Failed to refresh ads stats - $e');
    }
  }

  /// Clear all cached data (call on logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_PackCacheKeys.currentPack);
      await prefs.remove(_PackCacheKeys.selectedAid);
      await prefs.remove(_PackCacheKeys.adsStats);
      await prefs.remove(_PackCacheKeys.lastFetchTime);

      _currentData = null;
      _selectedAid = null;
      _adsStats = null;
      _hasFetchedOnce = false;

      debugPrint('📦 PackService: Cache cleared');
    } catch (e) {
      debugPrint('📦 PackService: Failed to clear cache - $e');
    }
  }

  /// Reset service state (call on logout)
  void reset() {
    _adsStatsSubscription?.cancel();
    _aidSelectedSubscription?.cancel();
    _currentData = null;
    _selectedAid = null;
    _adsStats = null;
    _currentUserId = null;
    _hasFetchedOnce = false;
    _initialized = false;
    debugPrint('📦 PackService: Reset');
  }

  /// Dispose resources
  void dispose() {
    _adsStatsSubscription?.cancel();
    _aidSelectedSubscription?.cancel();
    _dataController.close();
    _adsStatsController.close();
    _currentUserId = null;
    _initialized = false;
  }
}
