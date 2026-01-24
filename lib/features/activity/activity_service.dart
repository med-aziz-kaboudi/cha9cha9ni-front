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
  void _mergeActivities(List<RewardActivity> newActivities) {
    final existingIds = _activities.map((a) => a.id).toSet();

    for (final activity in newActivities) {
      if (!existingIds.contains(activity.id)) {
        _activities.insert(0, activity);
        existingIds.add(activity.id);
      }
    }

    // Sort by date (newest first)
    _activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Keep only the last 100 activities
    if (_activities.length > 100) {
      _activities = _activities.sublist(0, 100);
    }

    _activitiesController.add(_activities);
    _saveToCache();
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
        _mergeActivities(data.recentActivity);
      }
    } catch (e) {
      debugPrint('📊 ActivityService: Failed to refresh - $e');
    } finally {
      _isLoading = false;
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
