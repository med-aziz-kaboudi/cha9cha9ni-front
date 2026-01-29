/// Model representing a subscription pack
class PackModel {
  final String id;
  final String name;
  final String displayName;
  final double priceMonthly;
  final double priceYearly;
  final int withdrawalsPerYear;
  final int maxAidsSelectable;
  final int maxFamilyMembers;

  PackModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.priceMonthly,
    required this.priceYearly,
    required this.withdrawalsPerYear,
    required this.maxAidsSelectable,
    required this.maxFamilyMembers,
  });

  factory PackModel.fromJson(Map<String, dynamic> json) {
    return PackModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'free',
      displayName: json['displayName'] ?? 'STARTER PACK',
      priceMonthly: (json['priceMonthly'] ?? 0).toDouble(),
      priceYearly: (json['priceYearly'] ?? 0).toDouble(),
      withdrawalsPerYear: json['withdrawalsPerYear'] ?? 1,
      maxAidsSelectable: json['maxAidsSelectable'] ?? 1,
      maxFamilyMembers: json['maxFamilyMembers'] ?? 5,
    );
  }

  bool get isFree => name == 'free';
  bool get isPlus => name == 'plus';
  bool get isPro => name == 'pro';
  bool get isPremium => name == 'premium';

  /// Get yearly discount percentage
  int get yearlyDiscountPercent {
    if (priceMonthly == 0) return 0;
    final yearlyIfMonthly = priceMonthly * 12;
    return ((1 - (priceYearly / yearlyIfMonthly)) * 100).round();
  }
}

/// Model representing a Tunisian aid/holiday for withdrawal
class AidModel {
  final String id;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final int maxWithdrawal;
  final String? windowStart; // MM-DD
  final String? windowEnd; // MM-DD
  final String? description;
  final String? icon;
  final bool isWithinWindow;
  final DateTime? windowStartDate;
  final DateTime? windowEndDate;

  AidModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    required this.maxWithdrawal,
    this.windowStart,
    this.windowEnd,
    this.description,
    this.icon,
    required this.isWithinWindow,
    this.windowStartDate,
    this.windowEndDate,
  });

  factory AidModel.fromJson(Map<String, dynamic> json) {
    DateTime? startDate;
    DateTime? endDate;
    
    if (json['windowDates'] != null) {
      final dates = json['windowDates'] as Map<String, dynamic>;
      if (dates['start'] != null) {
        startDate = DateTime.parse(dates['start']);
      }
      if (dates['end'] != null) {
        endDate = DateTime.parse(dates['end']);
      }
    }
    
    return AidModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      displayNameAr: json['displayNameAr'],
      maxWithdrawal: json['maxWithdrawal'] ?? 0,
      windowStart: json['windowStart'],
      windowEnd: json['windowEnd'],
      description: json['description'],
      icon: json['icon'],
      isWithinWindow: json['isWithinWindow'] ?? false,
      windowStartDate: startDate,
      windowEndDate: endDate,
    );
  }

  /// Get window display string (e.g., "Jun 17 - Jun 24")
  String getWindowDisplay() {
    if (windowStartDate == null || windowEndDate == null) {
      return 'Year-round';
    }
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[windowStartDate!.month - 1]} ${windowStartDate!.day} - ${months[windowEndDate!.month - 1]} ${windowEndDate!.day}';
  }
}

/// Selected aid with status
class SelectedAidModel {
  final String id;
  final String aidId;
  final String aidName;
  final String aidDisplayName;
  final int maxWithdrawal;
  final String? windowStart;
  final String? windowEnd;
  final String status; // 'selected', 'withdrawn', 'expired'
  final int? withdrawnAmount;
  final DateTime? withdrawnAt;

  SelectedAidModel({
    required this.id,
    required this.aidId,
    required this.aidName,
    required this.aidDisplayName,
    required this.maxWithdrawal,
    this.windowStart,
    this.windowEnd,
    required this.status,
    this.withdrawnAmount,
    this.withdrawnAt,
  });

  factory SelectedAidModel.fromJson(Map<String, dynamic> json) {
    return SelectedAidModel(
      id: json['id'] ?? '',
      aidId: json['aidId'] ?? '',
      aidName: json['aidName'] ?? '',
      aidDisplayName: json['aidDisplayName'] ?? '',
      maxWithdrawal: json['maxWithdrawal'] ?? 0,
      windowStart: json['windowStart'],
      windowEnd: json['windowEnd'],
      status: json['status'] ?? 'selected',
      withdrawnAmount: json['withdrawnAmount'],
      withdrawnAt: json['withdrawnAt'] != null 
          ? DateTime.parse(json['withdrawnAt']) 
          : null,
    );
  }

  bool get isWithdrawn => status == 'withdrawn';
  bool get isExpired => status == 'expired';
}

/// Family ads statistics for real-time display
class FamilyAdsStats {
  final int familyTotalAdsToday;
  final int familyMaxAdsToday;
  final int userAdsToday;
  final int userMaxAds;
  final int memberCount;

  FamilyAdsStats({
    required this.familyTotalAdsToday,
    required this.familyMaxAdsToday,
    required this.userAdsToday,
    required this.userMaxAds,
    required this.memberCount,
  });

  factory FamilyAdsStats.fromJson(Map<String, dynamic> json) {
    return FamilyAdsStats(
      familyTotalAdsToday: json['familyTotalAdsToday'] ?? 0,
      familyMaxAdsToday: json['familyMaxAdsToday'] ?? 25,
      userAdsToday: json['userAdsToday'] ?? 0,
      userMaxAds: json['userMaxAds'] ?? 5,
      memberCount: json['memberCount'] ?? 1,
    );
  }

  double get familyProgress => familyMaxAdsToday > 0 
      ? familyTotalAdsToday / familyMaxAdsToday 
      : 0;
      
  double get userProgress => userMaxAds > 0 
      ? userAdsToday / userMaxAds 
      : 0;
}

/// Subscription status info
class SubscriptionInfo {
  final String status;
  final String billingCycle;
  final DateTime startDate;
  final DateTime? endDate;
  final int withdrawalsUsed;
  final int withdrawalsRemaining;

  SubscriptionInfo({
    required this.status,
    required this.billingCycle,
    required this.startDate,
    this.endDate,
    required this.withdrawalsUsed,
    required this.withdrawalsRemaining,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      status: json['status'] ?? 'active',
      billingCycle: json['billingCycle'] ?? 'yearly',
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      withdrawalsUsed: json['withdrawalsUsed'] ?? 0,
      withdrawalsRemaining: json['withdrawalsRemaining'] ?? 1,
    );
  }
}

/// Withdraw access info
class WithdrawAccessInfo {
  final bool canWithdraw;
  final bool isOwner;
  final bool isKycVerified;
  final String? kycStatus;

  WithdrawAccessInfo({
    required this.canWithdraw,
    required this.isOwner,
    required this.isKycVerified,
    this.kycStatus,
  });

  factory WithdrawAccessInfo.fromJson(Map<String, dynamic> json) {
    return WithdrawAccessInfo(
      canWithdraw: json['canWithdraw'] ?? false,
      isOwner: json['isOwner'] ?? false,
      isKycVerified: json['isKycVerified'] ?? false,
      kycStatus: json['kycStatus'],
    );
  }
}

/// Complete current pack response
class CurrentPackData {
  final PackModel pack;
  final SubscriptionInfo subscription;
  final int currentFamilyMembers;
  final int maxFamilyMembers;
  final WithdrawAccessInfo withdrawAccess;
  final List<SelectedAidModel> selectedAids;
  final List<AidModel> allAids; // All available aids for selection
  final FamilyAdsStats adsStats;

  CurrentPackData({
    required this.pack,
    required this.subscription,
    required this.currentFamilyMembers,
    required this.maxFamilyMembers,
    required this.withdrawAccess,
    required this.selectedAids,
    required this.allAids,
    required this.adsStats,
  });

  factory CurrentPackData.fromJson(Map<String, dynamic> json) {
    final familyMembers = json['familyMembers'] as Map<String, dynamic>? ?? {};
    
    return CurrentPackData(
      pack: PackModel.fromJson(json['pack'] ?? {}),
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      currentFamilyMembers: familyMembers['current'] ?? 1,
      maxFamilyMembers: familyMembers['max'] ?? 5,
      withdrawAccess: WithdrawAccessInfo.fromJson(json['withdrawAccess'] ?? {}),
      selectedAids: (json['selectedAids'] as List<dynamic>?)
          ?.map((a) => SelectedAidModel.fromJson(a))
          .toList() ?? [],
      allAids: (json['allAids'] as List<dynamic>?)
          ?.map((a) => AidModel.fromJson(a))
          .toList() ?? [],
      adsStats: FamilyAdsStats.fromJson(json['adsStats'] ?? {}),
    );
  }
}

/// All packs response
class AllPacksData {
  final List<PackModel> packs;
  final String currentPackName;

  AllPacksData({
    required this.packs,
    required this.currentPackName,
  });

  factory AllPacksData.fromJson(Map<String, dynamic> json) {
    return AllPacksData(
      packs: (json['packs'] as List<dynamic>?)
          ?.map((p) => PackModel.fromJson(p))
          .toList() ?? [],
      currentPackName: json['currentPackName'] ?? 'free',
    );
  }
}

/// All aids response for selection
class AllAidsData {
  final List<AidModel> aids;
  final List<String> selectedAidIds;
  final int maxSelectable;
  final int remainingSelections;

  AllAidsData({
    required this.aids,
    required this.selectedAidIds,
    required this.maxSelectable,
    required this.remainingSelections,
  });

  factory AllAidsData.fromJson(Map<String, dynamic> json) {
    return AllAidsData(
      aids: (json['aids'] as List<dynamic>?)
          ?.map((a) => AidModel.fromJson(a))
          .toList() ?? [],
      selectedAidIds: (json['selectedAidIds'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toList() ?? [],
      maxSelectable: json['maxSelectable'] ?? 1,
      remainingSelections: json['remainingSelections'] ?? 0,
    );
  }
}
