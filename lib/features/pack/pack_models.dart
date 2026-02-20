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
  final double yearlyWithdrawalMultiplier;

  PackModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.priceMonthly,
    required this.priceYearly,
    required this.withdrawalsPerYear,
    required this.maxAidsSelectable,
    required this.maxFamilyMembers,
    this.yearlyWithdrawalMultiplier = 1.0,
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
      yearlyWithdrawalMultiplier: (json['yearlyWithdrawalMultiplier'] ?? 1.0).toDouble(),
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
  final String? description;
  final String? descriptionAr;
  final String? icon;
  final bool isWithinWindow;
  final bool canSelect; // Whether user can still select (based on minDaysBeforeSelection)
  final DateTime? windowStartDate;
  final DateTime? windowEndDate;
  // New date fields
  final String? aidStartDate; // YYYY-MM-DD
  final String? aidEndDate;
  final String? withdrawalStartDate;
  final String? withdrawalEndDate;
  final int minDaysBeforeSelection;
  final int? daysUntilAid;
  final int? daysUntilWithdrawalOpen;
  final String? selectionDeadline; // YYYY-MM-DD

  AidModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    required this.maxWithdrawal,
    this.description,
    this.descriptionAr,
    this.icon,
    required this.isWithinWindow,
    this.canSelect = true,
    this.windowStartDate,
    this.windowEndDate,
    this.aidStartDate,
    this.aidEndDate,
    this.withdrawalStartDate,
    this.withdrawalEndDate,
    this.minDaysBeforeSelection = 7,
    this.daysUntilAid,
    this.daysUntilWithdrawalOpen,
    this.selectionDeadline,
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
      description: json['description'],
      descriptionAr: json['descriptionAr'],
      icon: json['icon'],
      isWithinWindow: json['isWithinWindow'] ?? false,
      canSelect: json['canSelect'] ?? true,
      windowStartDate: startDate,
      windowEndDate: endDate,
      aidStartDate: json['aidStartDate'],
      aidEndDate: json['aidEndDate'],
      withdrawalStartDate: json['withdrawalStartDate'],
      withdrawalEndDate: json['withdrawalEndDate'],
      minDaysBeforeSelection: json['minDaysBeforeSelection'] ?? 7,
      daysUntilAid: json['daysUntilAid'],
      daysUntilWithdrawalOpen: json['daysUntilWithdrawalOpen'],
      selectionDeadline: json['selectionDeadline'],
    );
  }

  /// Get aid date as DateTime
  DateTime? get aidStart => aidStartDate != null ? DateTime.parse(aidStartDate!) : null;
  DateTime? get aidEnd => aidEndDate != null ? DateTime.parse(aidEndDate!) : null;
  DateTime? get withdrawalStart => withdrawalStartDate != null ? DateTime.parse(withdrawalStartDate!) : null;
  DateTime? get withdrawalEnd => withdrawalEndDate != null ? DateTime.parse(withdrawalEndDate!) : null;
  DateTime? get selectionDeadlineDate => selectionDeadline != null ? DateTime.parse(selectionDeadline!) : null;

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

  /// Get aid dates display (e.g., "May 26 - May 28, 2026")
  String getAidDatesDisplay() {
    if (aidStart == null) return 'Date TBD';
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (aidEnd == null || aidStart!.day == aidEnd!.day) {
      return '${months[aidStart!.month - 1]} ${aidStart!.day}, ${aidStart!.year}';
    }
    
    if (aidStart!.month == aidEnd!.month) {
      return '${months[aidStart!.month - 1]} ${aidStart!.day}-${aidEnd!.day}, ${aidStart!.year}';
    }
    
    return '${months[aidStart!.month - 1]} ${aidStart!.day} - ${months[aidEnd!.month - 1]} ${aidEnd!.day}, ${aidStart!.year}';
  }

  /// Get withdrawal window display
  String getWithdrawalWindowDisplay() {
    if (withdrawalStart == null || withdrawalEnd == null) return 'Anytime';
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[withdrawalStart!.month - 1]} ${withdrawalStart!.day} - ${months[withdrawalEnd!.month - 1]} ${withdrawalEnd!.day}';
  }

  /// Get selection deadline display
  String getSelectionDeadlineDisplay() {
    if (selectionDeadlineDate == null) return 'Anytime';
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[selectionDeadlineDate!.month - 1]} ${selectionDeadlineDate!.day}, ${selectionDeadlineDate!.year}';
  }

  /// Get days until aid display
  String getDaysUntilAidDisplay() {
    if (daysUntilAid == null) return '';
    if (daysUntilAid == 0) return 'Today!';
    if (daysUntilAid == 1) return 'Tomorrow';
    return 'In $daysUntilAid days';
  }

  /// Check if selection deadline has passed
  bool get isSelectionDeadlinePassed => !canSelect;

  /// Get the number of days in the withdrawal window
  int? get withdrawalWindowDays {
    if (withdrawalStart == null || withdrawalEnd == null) return null;
    return withdrawalEnd!.difference(withdrawalStart!).inDays + 1;
  }
}

/// Selected aid with status
class SelectedAidModel {
  final String id;
  final String aidId;
  final String aidName;
  final String aidDisplayName;
  final int maxWithdrawal;
  final String? aidStartDate;
  final String? aidEndDate;
  final String? withdrawalStartDate;
  final String? withdrawalEndDate;
  final String status; // 'selected', 'withdrawn', 'expired'
  final int? withdrawnAmount;
  final DateTime? withdrawnAt;

  SelectedAidModel({
    required this.id,
    required this.aidId,
    required this.aidName,
    required this.aidDisplayName,
    required this.maxWithdrawal,
    this.aidStartDate,
    this.aidEndDate,
    this.withdrawalStartDate,
    this.withdrawalEndDate,
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
      aidStartDate: json['aidStartDate'],
      aidEndDate: json['aidEndDate'],
      withdrawalStartDate: json['withdrawalStartDate'],
      withdrawalEndDate: json['withdrawalEndDate'],
      status: json['status'] ?? 'selected',
      withdrawnAmount: json['withdrawnAmount'],
      withdrawnAt: json['withdrawnAt'] != null 
          ? DateTime.parse(json['withdrawnAt']) 
          : null,
    );
  }

  /// Get aid date as DateTime
  DateTime? get aidStart => aidStartDate != null ? DateTime.parse(aidStartDate!) : null;
  DateTime? get aidEnd => aidEndDate != null ? DateTime.parse(aidEndDate!) : null;
  DateTime? get withdrawalStart => withdrawalStartDate != null ? DateTime.parse(withdrawalStartDate!) : null;
  DateTime? get withdrawalEnd => withdrawalEndDate != null ? DateTime.parse(withdrawalEndDate!) : null;

  bool get isWithdrawn => status == 'withdrawn';
  bool get isExpired => status == 'expired';

  /// Check if we're currently in the withdrawal window
  bool get isWithinWithdrawalWindow {
    if (withdrawalStart == null || withdrawalEnd == null) return true;
    final now = DateTime.now();
    return now.isAfter(withdrawalStart!) && now.isBefore(withdrawalEnd!.add(const Duration(days: 1)));
  }

  /// Get withdrawal window display
  String getWithdrawalWindowDisplay() {
    if (withdrawalStart == null || withdrawalEnd == null) return 'Anytime';
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[withdrawalStart!.month - 1]} ${withdrawalStart!.day} - ${months[withdrawalEnd!.month - 1]} ${withdrawalEnd!.day}';
  }
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
