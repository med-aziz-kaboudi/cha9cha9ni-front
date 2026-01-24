/// Model representing family rewards data
class RewardsData {
  final String familyId;
  final String familyName;
  final int totalPoints;
  final double tndValue;
  final int memberCount;
  final UserRewardsProgress user;
  final List<RewardSlot> slots;
  final List<RewardActivity> recentActivity;

  RewardsData({
    required this.familyId,
    required this.familyName,
    required this.totalPoints,
    required this.tndValue,
    required this.memberCount,
    required this.user,
    required this.slots,
    required this.recentActivity,
  });

  factory RewardsData.fromJson(Map<String, dynamic> json) {
    return RewardsData(
      familyId: json['familyId'] ?? '',
      familyName: json['familyName'] ?? 'My Family',
      totalPoints: json['totalPoints'] ?? 0,
      tndValue: (json['tndValue'] ?? 0).toDouble(),
      memberCount: json['memberCount'] ?? 0,
      user: UserRewardsProgress.fromJson(json['user'] ?? {}),
      slots: (json['slots'] as List<dynamic>?)
              ?.map((s) => RewardSlot.fromJson(s))
              .toList() ??
          [],
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((a) => RewardActivity.fromJson(a))
              .toList() ??
          [],
    );
  }

  RewardsData copyWith({
    String? familyId,
    String? familyName,
    int? totalPoints,
    double? tndValue,
    int? memberCount,
    UserRewardsProgress? user,
    List<RewardSlot>? slots,
    List<RewardActivity>? recentActivity,
  }) {
    return RewardsData(
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      totalPoints: totalPoints ?? this.totalPoints,
      tndValue: tndValue ?? this.tndValue,
      memberCount: memberCount ?? this.memberCount,
      user: user ?? this.user,
      slots: slots ?? this.slots,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }
}

/// User's daily ad watching progress
class UserRewardsProgress {
  final String id;
  final int adsWatchedToday;
  final int remainingAds;
  final List<int> claimedSlots;
  final int? nextSlotIndex;
  final int? nextSlotPoints;

  UserRewardsProgress({
    required this.id,
    required this.adsWatchedToday,
    required this.remainingAds,
    required this.claimedSlots,
    this.nextSlotIndex,
    this.nextSlotPoints,
  });

  factory UserRewardsProgress.fromJson(Map<String, dynamic> json) {
    return UserRewardsProgress(
      id: json['id'] ?? '',
      adsWatchedToday: json['adsWatchedToday'] ?? 0,
      remainingAds: json['remainingAds'] ?? 5,
      claimedSlots: (json['claimedSlots'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      nextSlotIndex: json['nextSlotIndex'],
      nextSlotPoints: json['nextSlotPoints'],
    );
  }
}

/// Individual reward slot (1-5)
class RewardSlot {
  final int index;
  final int points;
  final bool claimed;

  RewardSlot({
    required this.index,
    required this.points,
    required this.claimed,
  });

  factory RewardSlot.fromJson(Map<String, dynamic> json) {
    return RewardSlot(
      index: json['index'] ?? 0,
      points: json['points'] ?? 0,
      claimed: json['claimed'] ?? false,
    );
  }
}

/// Activity type enum for rewards
enum ActivityType {
  adWatched,
  dailyCheckIn,
  topUp,
  referral,
  unknown;

  static ActivityType fromString(String? source) {
    switch (source) {
      case 'ad_watch':
      case 'ad_watched':
        return ActivityType.adWatched;
      case 'daily_checkin':
      case 'daily_check_in':
        return ActivityType.dailyCheckIn;
      case 'topup':
      case 'top_up':
        return ActivityType.topUp;
      case 'referral':
        return ActivityType.referral;
      default:
        return ActivityType.unknown;
    }
  }

  String get displayKey {
    switch (this) {
      case ActivityType.adWatched:
        return 'activityWatchedAd';
      case ActivityType.dailyCheckIn:
        return 'activityDailyCheckIn';
      case ActivityType.topUp:
        return 'activityTopUp';
      case ActivityType.referral:
        return 'activityReferral';
      case ActivityType.unknown:
        return 'activityEarnedPoints';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityType.adWatched:
        return '📺';
      case ActivityType.dailyCheckIn:
        return '☀️';
      case ActivityType.topUp:
        return '💰';
      case ActivityType.referral:
        return '🎁';
      case ActivityType.unknown:
        return '⭐';
    }
  }
}

/// Recent reward activity entry
class RewardActivity {
  final String id;
  final String memberName;
  final int pointsEarned;
  final int slotIndex;
  final ActivityType activityType;
  final DateTime createdAt;

  RewardActivity({
    required this.id,
    required this.memberName,
    required this.pointsEarned,
    required this.slotIndex,
    required this.activityType,
    required this.createdAt,
  });

  factory RewardActivity.fromJson(Map<String, dynamic> json) {
    return RewardActivity(
      id: json['id'] ?? '',
      memberName: json['memberName'] ?? 'Unknown',
      pointsEarned: json['pointsEarned'] ?? 0,
      slotIndex: json['slotIndex'] ?? 0,
      activityType: ActivityType.fromString(json['source'] ?? json['activityType']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Result of claiming a reward
class ClaimRewardResult {
  final bool success;
  final bool alreadyClaimed;
  final int pointsEarned;
  final int slotIndex;
  final int? newTotalPoints;
  final int? remainingAds;

  ClaimRewardResult({
    required this.success,
    required this.alreadyClaimed,
    required this.pointsEarned,
    required this.slotIndex,
    this.newTotalPoints,
    this.remainingAds,
  });

  factory ClaimRewardResult.fromJson(Map<String, dynamic> json) {
    return ClaimRewardResult(
      success: json['success'] ?? false,
      alreadyClaimed: json['alreadyClaimed'] ?? false,
      pointsEarned: json['pointsEarned'] ?? 0,
      slotIndex: json['slotIndex'] ?? 0,
      newTotalPoints: json['newTotalPoints'],
      remainingAds: json['remainingAds'],
    );
  }
}

/// Redemption tier configuration
class RedemptionTier {
  final int tndValue;
  final int requiredPoints;
  final int depositGate;

  const RedemptionTier({
    required this.tndValue,
    required this.requiredPoints,
    required this.depositGate,
  });

  static const List<RedemptionTier> tiers = [
    RedemptionTier(tndValue: 1, requiredPoints: 10000, depositGate: 10),
    RedemptionTier(tndValue: 5, requiredPoints: 50000, depositGate: 50),
    RedemptionTier(tndValue: 10, requiredPoints: 100000, depositGate: 100),
    RedemptionTier(tndValue: 50, requiredPoints: 500000, depositGate: 500),
    RedemptionTier(tndValue: 100, requiredPoints: 1000000, depositGate: 1000),
  ];
}

/// Daily check-in status
class DailyCheckInStatus {
  final bool canCheckIn;
  final int currentStreak;
  final String? lastCheckInDate;
  final int totalCheckIns;
  final int nextRewardPoints;
  final int streakDay;

  DailyCheckInStatus({
    required this.canCheckIn,
    required this.currentStreak,
    this.lastCheckInDate,
    required this.totalCheckIns,
    required this.nextRewardPoints,
    required this.streakDay,
  });

  factory DailyCheckInStatus.fromJson(Map<String, dynamic> json) {
    return DailyCheckInStatus(
      canCheckIn: json['canCheckIn'] ?? false,
      currentStreak: json['currentStreak'] ?? 0,
      lastCheckInDate: json['lastCheckInDate'],
      totalCheckIns: json['totalCheckIns'] ?? 0,
      nextRewardPoints: json['nextRewardPoints'] ?? 10,
      streakDay: json['streakDay'] ?? 1,
    );
  }
}

/// Daily check-in result
class DailyCheckInResult {
  final bool success;
  final int pointsEarned;
  final int currentStreak;
  final int totalCheckIns;
  final int newTotalPoints;

  DailyCheckInResult({
    required this.success,
    required this.pointsEarned,
    required this.currentStreak,
    required this.totalCheckIns,
    required this.newTotalPoints,
  });

  factory DailyCheckInResult.fromJson(Map<String, dynamic> json) {
    return DailyCheckInResult(
      success: json['success'] ?? false,
      pointsEarned: json['pointsEarned'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      totalCheckIns: json['totalCheckIns'] ?? 0,
      newTotalPoints: json['newTotalPoints'] ?? 0,
    );
  }
}
