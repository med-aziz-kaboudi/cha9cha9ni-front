import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Analytics service using Aptabase for privacy-focused analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;

  /// Initialize Aptabase with the app key
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Aptabase.init('A-EU-1072599566');
      _initialized = true;
      debugPrint('✅ Aptabase Analytics initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Aptabase: $e');
    }
  }

  /// Track app open event
  void trackAppOpen() {
    _trackEvent('app_open');
  }

  /// Track user sign up
  void trackSignUp({String? method}) {
    _trackEvent('sign_up', {'method': method ?? 'email'});
  }

  /// Track user login
  void trackLogin({String? method}) {
    _trackEvent('login', {'method': method ?? 'email'});
  }

  /// Track family creation
  void trackCreateFamily({String? familyId}) {
    _trackEvent('create_family', {
      if (familyId != null) 'family_id': familyId,
    });
  }

  /// Track joining a family
  void trackJoinFamily({String? familyId}) {
    _trackEvent('join_family', {
      if (familyId != null) 'family_id': familyId,
    });
  }

  /// Track leaving a family
  void trackLeaveFamily({String? familyId}) {
    _trackEvent('leave_family', {
      if (familyId != null) 'family_id': familyId,
    });
  }

  /// Track reward earned
  void trackRewardEarned({String? rewardType, int? points}) {
    _trackEvent('reward_earned', {
      if (rewardType != null) 'reward_type': rewardType,
      if (points != null) 'points': points.toString(),
    });
  }

  /// Track user logout
  void trackLogout() {
    _trackEvent('logout');
  }

  /// Track screen view
  void trackScreenView(String screenName) {
    _trackEvent('screen_view', {'screen_name': screenName});
  }

  /// Track pack creation
  void trackPackCreated({String? packId}) {
    _trackEvent('pack_created', {
      if (packId != null) 'pack_id': packId,
    });
  }

  /// Track task completed
  void trackTaskCompleted({String? taskId, String? packId}) {
    _trackEvent('task_completed', {
      if (taskId != null) 'task_id': taskId,
      if (packId != null) 'pack_id': packId,
    });
  }

  /// Track profile updated
  void trackProfileUpdated() {
    _trackEvent('profile_updated');
  }

  /// Track statement sent successfully
  void trackStatementSent({int? month, int? year, int? activitiesCount, int? totalPoints}) {
    _trackEvent('statement_sent', {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (activitiesCount != null) 'activities_count': activitiesCount,
      if (totalPoints != null) 'total_points': totalPoints,
    });
  }

  /// Track statement error
  void trackStatementError({String? error}) {
    _trackEvent('statement_error', {
      if (error != null) 'error': error,
    });
  }

  /// Track statement rate limited
  void trackStatementRateLimited({int? emailsSentToday}) {
    _trackEvent('statement_rate_limited', {
      if (emailsSentToday != null) 'emails_sent_today': emailsSentToday,
    });
  }

  /// Generic event tracking
  void _trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    if (!_initialized) {
      debugPrint('⚠️ Analytics not initialized, skipping event: $eventName');
      return;
    }

    try {
      if (properties != null && properties.isNotEmpty) {
        // Convert all values to strings for Aptabase
        final stringProps = properties.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
        Aptabase.instance.trackEvent(eventName, stringProps);
      } else {
        Aptabase.instance.trackEvent(eventName);
      }
      debugPrint('📊 Tracked: $eventName ${properties ?? ''}');
    } catch (e) {
      debugPrint('❌ Failed to track event $eventName: $e');
    }
  }
}
