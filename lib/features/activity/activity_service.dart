import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../rewards/rewards_model.dart';
import '../rewards/rewards_service.dart';

/// Service for managing family activity feed with real-time updates and caching
class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final _rewardsService = RewardsService();

  List<RewardActivity> _activities = [];
  final _activitiesController =
      StreamController<List<RewardActivity>>.broadcast();
  StreamSubscription<RewardsData>? _rewardsSubscription;
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

    // Load initial data if rewards service has it
    if (_rewardsService.currentData != null &&
        _rewardsService.currentData!.recentActivity.isNotEmpty) {
      _mergeActivities(_rewardsService.currentData!.recentActivity);
    }

    debugPrint(
      '📊 ActivityService: Initialized with ${_activities.length} cached activities',
    );
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
