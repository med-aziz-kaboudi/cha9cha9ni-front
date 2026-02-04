import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/analytics_service.dart';
import 'rewards_api_service.dart';
import 'rewards_model.dart';

/// Service for managing rewards with realtime updates
class RewardsService {
  static final RewardsService _instance = RewardsService._internal();
  factory RewardsService() => _instance;
  RewardsService._internal();

  final _apiService = RewardsApiService();
  final _socketService = SocketService();
  final _uuid = const Uuid();

  RewardsData? _currentData;
  final _dataController = StreamController<RewardsData>.broadcast();
  final _redemptionController = StreamController<RewardsRedeemedData>.broadcast();
  StreamSubscription<PointsEarnedData>? _socketSubscription;
  StreamSubscription<RewardsRedeemedData>? _redemptionSubscription;
  bool _isWatchingAd = false;
  String? _pendingEventId;

  /// Stream of rewards data updates
  Stream<RewardsData> get dataStream => _dataController.stream;

  /// Stream of redemption events (for showing congrats to all family members)
  Stream<RewardsRedeemedData> get redemptionStream => _redemptionController.stream;

  /// Current rewards data
  RewardsData? get currentData => _currentData;

  /// Whether an ad is currently being watched
  bool get isWatchingAd => _isWatchingAd;

  /// Initialize the service and start listening for realtime updates
  void initialize() {
    _listenToSocketEvents();
  }

  /// Reset ad session state (call if session gets corrupted)
  void resetAdSession() {
    debugPrint('🎬 resetAdSession called - was isWatching: $_isWatchingAd');
    _isWatchingAd = false;
    _pendingEventId = null;
  }

  void _listenToSocketEvents() {
    // Listen for points_earned events from the socket
    _socketSubscription?.cancel();
    _socketSubscription = _socketService.onPointsEarned.listen((data) {
      debugPrint('🎁 RewardsService: Points earned - ${data.pointsEarned} pts from ${data.memberName} (source: ${data.source}, amount: ${data.amount})');
      _handlePointsEarned({
        'earnerId': data.earnerId,
        'memberName': data.memberName,
        'pointsEarned': data.pointsEarned,
        'slotIndex': data.slotIndex,
        'newTotalPoints': data.newTotalPoints,
        'source': data.source,
        'amount': data.amount, // Include amount for topups
      });
    });

    // Listen for rewards_redeemed events from the socket
    _redemptionSubscription?.cancel();
    _redemptionSubscription = _socketService.onRewardsRedeemed.listen((data) {
      debugPrint('🎁 RewardsService: Rewards redeemed - ${data.pointsSpent} pts by ${data.memberName} for ${data.amountCredited} TND');
      _handleRewardsRedeemed(data);
    });
  }

  /// Fetch rewards data from the API
  Future<RewardsData> fetchRewardsData() async {
    try {
      final data = await _apiService.getRewardsData();
      _currentData = data;
      _dataController.add(data);
      return data;
    } catch (e) {
      debugPrint('❌ Failed to fetch rewards data: $e');
      rethrow;
    }
  }

  /// Start watching an ad
  /// Returns the clientEventId to use for claiming
  String startWatchingAd() {
    debugPrint('🎬 startWatchingAd - current: isWatching=$_isWatchingAd, pending=$_pendingEventId');
    if (_isWatchingAd) {
      throw Exception('Already watching an ad');
    }
    _isWatchingAd = true;
    _pendingEventId = _uuid.v4();
    debugPrint('🎬 startWatchingAd - new session: $_pendingEventId');
    return _pendingEventId!;
  }

  /// Cancel ad watching (ad failed/skipped)
  void cancelAdWatch() {
    debugPrint('🎬 cancelAdWatch called');
    _isWatchingAd = false;
    _pendingEventId = null;
  }

  /// Complete ad watching and claim reward
  Future<ClaimRewardResult> completeAdWatch(String clientEventId) async {
    debugPrint('🎬 completeAdWatch called - isWatching: $_isWatchingAd, pending: $_pendingEventId, received: $clientEventId');
    if (!_isWatchingAd || _pendingEventId != clientEventId) {
      debugPrint('🎬 MISMATCH! isWatching=$_isWatchingAd, pending=$_pendingEventId vs received=$clientEventId');
      throw Exception('Invalid ad session');
    }

    try {
      final result = await _apiService.claimReward(clientEventId);
      _isWatchingAd = false;
      _pendingEventId = null;

      // Track reward earned
      AnalyticsService().trackRewardEarned(
        rewardType: 'ad_watch',
        points: result.pointsEarned,
      );

      // Refresh data to get updated state
      await fetchRewardsData();

      return result;
    } catch (e) {
      _isWatchingAd = false;
      _pendingEventId = null;
      rethrow;
    }
  }

  /// Handle realtime points update from socket
  void _handlePointsEarned(Map<String, dynamic> data) {
    final newTotalPoints = data['newTotalPoints'] as int?;
    final memberName = data['memberName'] as String?;
    final pointsEarned = data['pointsEarned'] as int?;
    final slotIndex = data['slotIndex'] as int?;
    final source = data['source'] as String?;
    final amount = data['amount'] != null ? (data['amount'] as num).toDouble() : null;

    if (newTotalPoints != null) {
      // Create new activity entry
      final newActivity = RewardActivity(
        id: _uuid.v4(),
        memberName: memberName ?? 'Unknown',
        pointsEarned: pointsEarned ?? 0,
        slotIndex: slotIndex ?? 0,
        activityType: ActivityType.fromString(source),
        createdAt: DateTime.now(),
        amount: amount,
      );

      // If we don't have current data, create a minimal version
      if (_currentData == null) {
        _currentData = RewardsData(
          familyId: '',
          familyName: 'My Family',
          totalPoints: newTotalPoints,
          tndValue: newTotalPoints / 10000,
          memberCount: 1,
          user: UserRewardsProgress(
            id: '',
            adsWatchedToday: 0,
            remainingAds: 5,
            claimedSlots: [],
          ),
          slots: [],
          recentActivity: [newActivity],
        );
      } else {
        // Update existing data
        final updatedActivities = [newActivity, ..._currentData!.recentActivity];
        if (updatedActivities.length > 10) {
          updatedActivities.removeLast();
        }

        _currentData = _currentData!.copyWith(
          totalPoints: newTotalPoints,
          tndValue: newTotalPoints / 10000,
          recentActivity: updatedActivities,
        );
      }

      _dataController.add(_currentData!);
      debugPrint('📊 RewardsService: Emitted updated data with totalPoints=$newTotalPoints');
    }
  }

  /// Handle realtime rewards redeemed update from socket
  void _handleRewardsRedeemed(RewardsRedeemedData data) {
    debugPrint('📊 RewardsService: Handling rewards_redeemed event from ${data.memberName} (earnerId: ${data.earnerId})');
    
    // Update the total points in current data
    if (_currentData != null) {
      // Check if we already have a redemption activity with similar params (within 1 minute)
      // to avoid duplicates from local add + socket event
      final hasSimilarActivity = _currentData!.recentActivity.any((a) =>
          a.activityType == ActivityType.redemption &&
          a.memberName == data.memberName &&
          a.pointsEarned == -data.pointsSpent &&
          a.createdAt.difference(data.timestamp).inMinutes.abs() < 1);

      if (!hasSimilarActivity) {
        // Create redemption activity entry with memberId for proper filtering
        final redemptionActivity = RewardActivity(
          id: _uuid.v4(),
          memberId: data.earnerId, // Include memberId for "show only my activities" filter
          memberName: data.memberName,
          pointsEarned: -data.pointsSpent, // Negative to show points spent
          slotIndex: 0,
          activityType: ActivityType.redemption,
          createdAt: data.timestamp,
          amount: data.amountCredited,
        );

        // Add to activities list
        final updatedActivities = [redemptionActivity, ..._currentData!.recentActivity];
        if (updatedActivities.length > 10) {
          updatedActivities.removeLast();
        }

        _currentData = _currentData!.copyWith(
          totalPoints: data.newTotalPoints,
          tndValue: data.newTotalPoints / 10000,
          recentActivity: updatedActivities,
        );
        debugPrint('📊 RewardsService: Added redemption activity for ${data.memberName}');
      } else {
        // Just update the points without adding duplicate activity
        _currentData = _currentData!.copyWith(
          totalPoints: data.newTotalPoints,
          tndValue: data.newTotalPoints / 10000,
        );
        debugPrint('📊 RewardsService: Skipped duplicate redemption activity');
      }
      _dataController.add(_currentData!);
    }

    // Emit redemption event for congrats animation
    _redemptionController.add(data);
    debugPrint('📊 RewardsService: Emitted redemption event - ${data.memberName} redeemed ${data.pointsSpent} pts for ${data.amountCredited} TND');
  }

  /// Check if the family can redeem rewards
  Future<CanRedeemResult> canRedeem() async {
    return await _apiService.canRedeem();
  }

  /// Redeem points to balance
  /// Returns the result with new balance and points
  Future<RedeemPointsResult> redeemPoints(int points) async {
    try {
      final result = await _apiService.redeemPoints(points);

      // Track redemption
      AnalyticsService().trackRewardEarned(
        rewardType: 'redemption',
        points: -points, // Negative to indicate spent
      );

      // Update local data immediately with the redemption activity
      if (_currentData != null) {
        // Create redemption activity entry for immediate display
        final redemptionActivity = RewardActivity(
          id: _uuid.v4(),
          memberId: result.memberId, // Include memberId for proper filtering
          memberName: result.memberName,
          pointsEarned: -points, // Negative to show points spent
          slotIndex: 0,
          activityType: ActivityType.redemption,
          createdAt: DateTime.now(),
          amount: result.amountCredited,
        );

        // Add to activities list
        final updatedActivities = [redemptionActivity, ..._currentData!.recentActivity];
        if (updatedActivities.length > 10) {
          updatedActivities.removeLast();
        }

        _currentData = _currentData!.copyWith(
          totalPoints: result.newTotalPoints,
          tndValue: result.newTotalPoints / 10000,
          recentActivity: updatedActivities,
        );
        _dataController.add(_currentData!);
      }

      return result;
    } catch (e) {
      debugPrint('❌ Failed to redeem points: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _socketSubscription?.cancel();
    _redemptionSubscription?.cancel();
    _dataController.close();
    _redemptionController.close();
  }
}
