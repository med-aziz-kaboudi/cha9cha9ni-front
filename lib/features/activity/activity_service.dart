import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/socket_service.dart';
import '../rewards/rewards_model.dart';
import '../rewards/rewards_service.dart';

/// Service for managing family activity feed with real-time updates and caching
class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final _rewardsService = RewardsService();
  final _socketService = SocketService();
  final _uuid = const Uuid();

  List<RewardActivity> _activities = [];
  final _activitiesController =
      StreamController<List<RewardActivity>>.broadcast();
  StreamSubscription<RewardsData>? _rewardsSubscription;
  StreamSubscription<RewardsRedeemedData>? _redemptionSubscription;
  StreamSubscription<PointsEarnedData>? _pointsEarnedSubscription;
  bool _initialized = false;
  bool _isLoading = false;

  static const String _cacheKey = 'cached_family_activities';
  static const String _cacheTimestampKey = 'cached_family_activities_timestamp';

  /// Stream of activity updates
  Stream<List<RewardActivity>> get activitiesStream =>
      _activitiesController.stream;

  /// Current list of activities
  List<RewardActivity> get activities => List.unmodifiable(_activities);

  /// Whether activities are currently being loaded
  bool get isLoading => _isLoading;

  /// Initialize the service and start listening for updates
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Load cached data first for instant display
    await _loadFromCache();
    
    // Clean up any existing duplicates from cached data
    _removeDuplicates();

    // Listen to rewards service for updates (it handles socket events internally)
    _rewardsSubscription = _rewardsService.dataStream.listen((data) {
      if (data.recentActivity.isNotEmpty) {
        _mergeActivities(data.recentActivity);
      }
    });

    // Also listen directly to socket events for real-time updates
    // This ensures we get updates even if RewardsService._currentData is null
    _redemptionSubscription = _socketService.onRewardsRedeemed.listen((data) {
      debugPrint('📊 ActivityService: Received rewards_redeemed socket event from ${data.memberName}');
      _handleRedemptionEvent(data);
    });

    _pointsEarnedSubscription = _socketService.onPointsEarned.listen((data) {
      debugPrint('📊 ActivityService: Received points_earned socket event from ${data.memberName}');
      _handlePointsEarnedEvent(data);
    });

    // Load initial data if rewards service has it
    if (_rewardsService.currentData != null &&
        _rewardsService.currentData!.recentActivity.isNotEmpty) {
      _mergeActivities(_rewardsService.currentData!.recentActivity);
    }

    debugPrint(
      '📊 ActivityService: Initialized with ${_activities.length} cached activities',
    );
  }

  /// Handle redemption event from socket directly
  void _handleRedemptionEvent(RewardsRedeemedData data) {
    // Check for duplicate (same member, points, within 1 minute)
    final hasDuplicate = _activities.any((a) =>
        a.activityType == ActivityType.redemption &&
        a.memberName == data.memberName &&
        a.pointsEarned == -data.pointsSpent &&
        a.createdAt.difference(data.timestamp).inMinutes.abs() < 1);

    if (hasDuplicate) {
      debugPrint('📊 ActivityService: Skipping duplicate redemption from ${data.memberName}');
      return;
    }

    final activity = RewardActivity(
      id: _uuid.v4(),
      memberId: data.earnerId,
      memberName: data.memberName,
      pointsEarned: -data.pointsSpent,
      slotIndex: 0,
      activityType: ActivityType.redemption,
      createdAt: data.timestamp,
      amount: data.amountCredited,
    );

    _activities.insert(0, activity);
    if (_activities.length > 100) {
      _activities = _activities.sublist(0, 100);
    }
    _activitiesController.add(_activities);
    _saveToCache();
    debugPrint('📊 ActivityService: Added redemption activity from socket for ${data.memberName}');
  }

  /// Handle points earned event from socket directly
  void _handlePointsEarnedEvent(PointsEarnedData data) {
    // Check for duplicate
    final hasDuplicate = _activities.any((a) =>
        a.memberName == data.memberName &&
        a.pointsEarned == data.pointsEarned &&
        a.activityType == ActivityType.fromString(data.source) &&
        a.createdAt.difference(data.timestamp).inMinutes.abs() < 1);

    if (hasDuplicate) {
      debugPrint('📊 ActivityService: Skipping duplicate points_earned from ${data.memberName}');
      return;
    }

    final activity = RewardActivity(
      id: _uuid.v4(),
      memberId: data.earnerId,
      memberName: data.memberName,
      pointsEarned: data.pointsEarned,
      slotIndex: data.slotIndex,
      activityType: ActivityType.fromString(data.source),
      createdAt: data.timestamp,
      amount: data.amount,
    );

    _activities.insert(0, activity);
    if (_activities.length > 100) {
      _activities = _activities.sublist(0, 100);
    }
    _activitiesController.add(_activities);
    _saveToCache();
    debugPrint('📊 ActivityService: Added ${data.source} activity from socket for ${data.memberName}');
  }

  /// Load activities from local cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);

      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        _activities = decoded.map((e) => RewardActivity.fromJson(e)).toList();
        _activitiesController.add(_activities);
        debugPrint(
          '📊 ActivityService: Loaded ${_activities.length} activities from cache',
        );
      }
    } catch (e) {
      debugPrint('📊 ActivityService: Failed to load cache - $e');
    }
  }

  /// Save activities to local cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _activities
          .map(
            (a) => {
              'id': a.id,
              'memberId': a.memberId,
              'memberName': a.memberName,
              'pointsEarned': a.pointsEarned,
              'slotIndex': a.slotIndex,
              'source': a.activityType == ActivityType.adWatched
                  ? 'ad_watch'
                  : a.activityType == ActivityType.dailyCheckIn
                  ? 'daily_checkin'
                  : a.activityType == ActivityType.topUp
                  ? 'topup'
                  : a.activityType == ActivityType.referral
                  ? 'referral'
                  : a.activityType == ActivityType.redemption
                  ? 'redemption'
                  : 'unknown',
              'createdAt': a.createdAt.toIso8601String(),
              'amount': a.amount,
            },
          )
          .toList();

      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('📊 ActivityService: Failed to save cache - $e');
    }
  }

  /// Merge new activities with existing ones (avoiding duplicates)
  /// Detects duplicates by:
  /// 1. Matching ID (for API-returned activities)
  /// 2. Matching source + memberName + pointsEarned + close timestamp (for socket vs API)
  void _mergeActivities(List<RewardActivity> newActivities) {
    bool hasChanges = false;
    
    for (final newActivity in newActivities) {
      // Check for exact ID match
      final existingByIdIndex = _activities.indexWhere((a) => a.id == newActivity.id);
      if (existingByIdIndex != -1) {
        // Update existing if new one has more info (e.g., amount)
        if (newActivity.amount != null && _activities[existingByIdIndex].amount == null) {
          _activities[existingByIdIndex] = newActivity;
          hasChanges = true;
        }
        continue;
      }

      // Check for duplicate by content (same type, member, points, within 5 minutes)
      // Use 5 minute window to catch both socket and API activities
      final existingSimilarIndex = _activities.indexWhere((a) =>
          a.activityType == newActivity.activityType &&
          a.memberName == newActivity.memberName &&
          a.pointsEarned == newActivity.pointsEarned &&
          (a.createdAt.difference(newActivity.createdAt).inMinutes.abs() < 5));
      
      if (existingSimilarIndex != -1) {
        // Replace existing with new if new has more info (amount, real ID)
        final existing = _activities[existingSimilarIndex];
        final newHasRealId = !newActivity.id.contains('-') || newActivity.id.length > 30;
        final existingHasRealId = !existing.id.contains('-') || existing.id.length > 30;
        
        if ((newActivity.amount != null && existing.amount == null) ||
            (newHasRealId && !existingHasRealId)) {
          // New has amount or real ID, prefer it
          _activities[existingSimilarIndex] = newActivity;
          hasChanges = true;
          debugPrint('📊 ActivityService: Replaced duplicate with better version');
        }
        continue;
      }

      // No duplicate found, add it
      _activities.insert(0, newActivity);
      hasChanges = true;
    }

    if (hasChanges) {
      // Sort by date (newest first)
      _activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Keep only the last 100 activities
      if (_activities.length > 100) {
        _activities = _activities.sublist(0, 100);
      }

      _activitiesController.add(_activities);
      _saveToCache();
    }
  }

  /// Get the last N activities (for home screen)
  List<RewardActivity> getRecentActivities({int count = 7}) {
    return _activities.take(count).toList();
  }

  /// Check if cache is fresh (within threshold)
  Future<bool> isCacheFresh({int thresholdSeconds = 300}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);

    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(cacheTime);

    return age.inSeconds < thresholdSeconds;
  }

  /// Refresh activities from API (only if cache is stale)
  Future<void> refresh({bool force = false}) async {
    if (_isLoading) return;

    // Skip refresh if cache is fresh (unless forced)
    if (!force && await isCacheFresh()) {
      debugPrint('📊 ActivityService: Cache is fresh, skipping refresh');
      return;
    }

    _isLoading = true;

    try {
      final data = await _rewardsService.fetchRewardsData();
      if (data.recentActivity.isNotEmpty) {
        // If force refresh, replace all activities instead of merging
        if (force) {
          _activities = List.from(data.recentActivity);
          _activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _activitiesController.add(_activities);
          _saveToCache();
        } else {
          _mergeActivities(data.recentActivity);
        }
      }
    } catch (e) {
      debugPrint('📊 ActivityService: Failed to refresh - $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Clean up any duplicate activities in the current list
  void _removeDuplicates() {
    final seen = <String>{};
    final cleaned = <RewardActivity>[];
    
    for (final activity in _activities) {
      // Create a unique key based on content (use 5-minute window = 300000ms)
      final key = '${activity.activityType}-${activity.memberName}-${activity.pointsEarned}-${activity.createdAt.millisecondsSinceEpoch ~/ 300000}';
      if (!seen.contains(key)) {
        seen.add(key);
        cleaned.add(activity);
      }
    }
    
    if (cleaned.length != _activities.length) {
      debugPrint('📊 ActivityService: Removed ${_activities.length - cleaned.length} duplicates');
      _activities = cleaned;
      _activitiesController.add(_activities);
      _saveToCache();
    }
  }

  /// Dispose resources
  void dispose() {
    _rewardsSubscription?.cancel();
    _redemptionSubscription?.cancel();
    _pointsEarnedSubscription?.cancel();
    _activitiesController.close();
    _initialized = false;
  }

  /// Clear all cached activities (call on logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      _activities.clear();
      _initialized = false;
      debugPrint('📊 ActivityService: Cache cleared');
    } catch (e) {
      debugPrint('📊 ActivityService: Failed to clear cache - $e');
    }
  }
}
