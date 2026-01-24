import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/socket_service.dart';
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
  StreamSubscription<PointsEarnedData>? _socketSubscription;
  bool _isWatchingAd = false;
  String? _pendingEventId;

  /// Stream of rewards data updates
  Stream<RewardsData> get dataStream => _dataController.stream;

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
      debugPrint('🎁 RewardsService: Points earned - ${data.pointsEarned} pts from ${data.memberName}');
      _handlePointsEarned({
        'earnerId': data.earnerId,
        'memberName': data.memberName,
        'pointsEarned': data.pointsEarned,
        'slotIndex': data.slotIndex,
        'newTotalPoints': data.newTotalPoints,
      });
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
    if (_currentData == null) return;

    final newTotalPoints = data['newTotalPoints'] as int?;
    final memberName = data['memberName'] as String?;
    final pointsEarned = data['pointsEarned'] as int?;
    final slotIndex = data['slotIndex'] as int?;
    final source = data['source'] as String?;

    if (newTotalPoints != null) {
      // Create new activity entry
      final newActivity = RewardActivity(
        id: _uuid.v4(),
        memberName: memberName ?? 'Unknown',
        pointsEarned: pointsEarned ?? 0,
        slotIndex: slotIndex ?? 0,
        activityType: ActivityType.fromString(source),
        createdAt: DateTime.now(),
      );

      // Update data
      final updatedActivities = [newActivity, ..._currentData!.recentActivity];
      if (updatedActivities.length > 10) {
        updatedActivities.removeLast();
      }

      _currentData = _currentData!.copyWith(
        totalPoints: newTotalPoints,
        tndValue: newTotalPoints / 10000,
        recentActivity: updatedActivities,
      );

      _dataController.add(_currentData!);
    }
  }

  /// Dispose resources
  void dispose() {
    _socketSubscription?.cancel();
    _dataController.close();
  }
}
