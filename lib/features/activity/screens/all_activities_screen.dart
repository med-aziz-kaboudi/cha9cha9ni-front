import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/token_storage_service.dart';
import '../../rewards/rewards_model.dart';
import '../activity_service.dart';

/// Filter options for activities
enum ActivityTimeFilter {
  last10Days,
  today,
  yesterday,
  last7Days,
  last30Days,
  last3Months,
  all,
}

/// Screen that displays all family activities with filters
class AllActivitiesScreen extends StatefulWidget {
  const AllActivitiesScreen({super.key});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen>
    with SingleTickerProviderStateMixin {
  final _activityService = ActivityService();
  List<RewardActivity> _allActivities = [];
  List<RewardActivity> _filteredActivities = [];
  StreamSubscription<List<RewardActivity>>? _subscription;
  bool _isLoading = true;

  // Rate limiting: 3 refreshes, then 15 min cooldown
  static const int _maxRefreshes = 3;
  static const int _rateLimitMinutes = 15;
  int _refreshCount = 0;
  DateTime? _rateLimitEndTime;
  Timer? _rateLimitTimer;

  // Filters - default to last 10 days
  ActivityTimeFilter _timeFilter = ActivityTimeFilter.last10Days;
  ActivityType? _typeFilter;
  bool _showOnlyMyActivities = false;
  String? _currentUserId;
  String? _currentUserName;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _initializeScreen();

    _subscription = _activityService.activitiesStream.listen((activities) {
      if (mounted) {
        setState(() {
          _allActivities = activities;
          _applyFilters();
        });
      }
    });
  }

  Future<void> _initializeScreen() async {
    // Load user info first, then activities
    await _loadCurrentUserInfo();
    await _loadActivities();
  }

  Future<void> _loadCurrentUserInfo() async {
    final tokenStorage = TokenStorageService();
    final profile = await tokenStorage.getCachedUserProfile();
    _currentUserName = profile['fullName'] ?? 
                      '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    _currentUserId = await tokenStorage.getUserId();
    debugPrint('📋 Current user ID: $_currentUserId, Name: $_currentUserName');
  }

  Future<void> _loadActivities() async {
    await _activityService.initialize();
    await _activityService.refresh();
    if (mounted) {
      setState(() {
        _allActivities = _activityService.activities;
        _applyFilters();
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  void _applyFilters() {
    List<RewardActivity> result = List.from(_allActivities);

    // Apply time filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_timeFilter) {
      case ActivityTimeFilter.today:
        result = result.where((a) {
          final activityDate = DateTime(
            a.createdAt.year,
            a.createdAt.month,
            a.createdAt.day,
          );
          return activityDate == today;
        }).toList();
        break;
      case ActivityTimeFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        result = result.where((a) {
          final activityDate = DateTime(
            a.createdAt.year,
            a.createdAt.month,
            a.createdAt.day,
          );
          return activityDate == yesterday;
        }).toList();
        break;
      case ActivityTimeFilter.last7Days:
        final weekAgo = today.subtract(const Duration(days: 7));
        result = result.where((a) {
          return a.createdAt.isAfter(weekAgo) ||
              a.createdAt.isAtSameMomentAs(weekAgo);
        }).toList();
        break;
      case ActivityTimeFilter.last10Days:
        final tenDaysAgo = today.subtract(const Duration(days: 10));
        result = result.where((a) {
          return a.createdAt.isAfter(tenDaysAgo) ||
              a.createdAt.isAtSameMomentAs(tenDaysAgo);
        }).toList();
        break;
      case ActivityTimeFilter.last30Days:
        final monthAgo = today.subtract(const Duration(days: 30));
        result = result.where((a) {
          return a.createdAt.isAfter(monthAgo) ||
              a.createdAt.isAtSameMomentAs(monthAgo);
        }).toList();
        break;
      case ActivityTimeFilter.last3Months:
        final threeMonthsAgo = today.subtract(const Duration(days: 90));
        result = result.where((a) {
          return a.createdAt.isAfter(threeMonthsAgo) ||
              a.createdAt.isAtSameMomentAs(threeMonthsAgo);
        }).toList();
        break;
      case ActivityTimeFilter.all:
        break;
    }

    // Apply type filter
    if (_typeFilter != null) {
      result = result.where((a) => a.activityType == _typeFilter).toList();
    }

    // Apply member filter (show only my activities)
    if (_showOnlyMyActivities && _currentUserId != null) {
      // Filter by memberId if available, fallback to name comparison
      result = result.where((a) {
        if (a.memberId != null) {
          return a.memberId == _currentUserId;
        }
        // Fallback: case-insensitive name comparison
        return a.memberName.toLowerCase() == (_currentUserName ?? '').toLowerCase();
      }).toList();
    }

    _filteredActivities = result;
  }

  String _getTimeFilterLabel(ActivityTimeFilter filter, AppLocalizations l10n) {
    switch (filter) {
      case ActivityTimeFilter.last10Days:
        return l10n.filterLast10Days;
      case ActivityTimeFilter.all:
        return l10n.filterAll;
      case ActivityTimeFilter.today:
        return l10n.today;
      case ActivityTimeFilter.yesterday:
        return l10n.yesterday;
      case ActivityTimeFilter.last7Days:
        return l10n.filterLast7Days;
      case ActivityTimeFilter.last30Days:
        return l10n.filterLast30Days;
      case ActivityTimeFilter.last3Months:
        return l10n.filterLast3Months;
    }
  }

  String _getTypeFilterLabel(ActivityType? type, AppLocalizations l10n) {
    if (type == null) return l10n.filterAllTypes;
    switch (type) {
      case ActivityType.adWatched:
        return l10n.filterAds;
      case ActivityType.dailyCheckIn:
        return l10n.filterCheckIn;
      case ActivityType.topUp:
        return l10n.filterTopUp;
      case ActivityType.referral:
        return l10n.filterReferral;
      case ActivityType.unknown:
        return l10n.filterOther;
    }
  }

  String _formatTimeAgo(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours > 0 && difference.inHours < 24) {
      return difference.inHours == 1
          ? l10n.hourAgo(difference.inHours)
          : l10n.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? l10n.minAgo(difference.inMinutes)
          : l10n.minsAgo(difference.inMinutes);
    } else if (difference.inMinutes == 0) {
      return l10n.justNow;
    }
    return DateFormat('h:mm a').format(date);
  }

  String _getActivityTitle(RewardActivity activity, AppLocalizations l10n) {
    final name = activity.memberName;
    switch (activity.activityType) {
      case ActivityType.adWatched:
        return l10n.activityWatchedAd(name);
      case ActivityType.dailyCheckIn:
        return l10n.activityDailyCheckIn(name);
      case ActivityType.topUp:
        return l10n.activityTopUp(name);
      case ActivityType.referral:
        return l10n.activityReferral(name);
      case ActivityType.unknown:
        return l10n.activityEarnedPoints(name);
    }
  }

  String _getActivitySubtitle(ActivityType type, AppLocalizations l10n) {
    switch (type) {
      case ActivityType.adWatched:
        return l10n.filterAds;
      case ActivityType.dailyCheckIn:
        return l10n.filterCheckIn;
      case ActivityType.topUp:
        return l10n.filterTopUp;
      case ActivityType.referral:
        return l10n.filterReferral;
      case ActivityType.unknown:
        return l10n.filterOther;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.adWatched:
        return const Color(0xFF6366F1); // Indigo
      case ActivityType.dailyCheckIn:
        return const Color(0xFFF59E0B); // Amber
      case ActivityType.topUp:
        return const Color(0xFF10B981); // Emerald
      case ActivityType.referral:
        return const Color(0xFFEC4899); // Pink
      case ActivityType.unknown:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  // Group activities by date
  Map<String, List<RewardActivity>> _groupActivitiesByDate(
    AppLocalizations l10n,
  ) {
    final grouped = <String, List<RewardActivity>>{};

    for (final activity in _filteredActivities) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final activityDate = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );

      String dateKey;
      if (activityDate == today) {
        dateKey = l10n.today;
      } else if (activityDate == yesterday) {
        dateKey = l10n.yesterday;
      } else {
        dateKey = DateFormat('EEEE, MMMM d').format(activity.createdAt);
      }

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(activity);
    }

    return grouped;
  }

  void _showFilterBottomSheet() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  l10n.filterActivities,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 24),

                // Time filter section
                Text(
                  l10n.filterByTime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ActivityTimeFilter.values.map((filter) {
                    final isSelected = _timeFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => _timeFilter = filter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getTimeFilterLabel(filter, l10n),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Type filter section
                Text(
                  l10n.filterByType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip(null, l10n, setModalState),
                    _buildTypeChip(ActivityType.adWatched, l10n, setModalState),
                    _buildTypeChip(
                      ActivityType.dailyCheckIn,
                      l10n,
                      setModalState,
                    ),
                    _buildTypeChip(ActivityType.topUp, l10n, setModalState),
                  ],
                ),
                const SizedBox(height: 24),

                // Member filter section
                Text(
                  l10n.filterByMember,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.showOnlyMyActivities,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      Switch(
                        value: _showOnlyMyActivities,
                        onChanged: (value) {
                          setModalState(() => _showOnlyMyActivities = value);
                        },
                        activeColor: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _applyFilters());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n.applyFilters,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Clear filters
                if (_timeFilter != ActivityTimeFilter.last10Days ||
                    _typeFilter != null ||
                    _showOnlyMyActivities) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        setModalState(() {
                          _timeFilter = ActivityTimeFilter.last10Days;
                          _typeFilter = null;
                          _showOnlyMyActivities = false;
                        });
                        setState(() => _applyFilters());
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.clearFilters,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(
    ActivityType? type,
    AppLocalizations l10n,
    StateSetter setModalState,
  ) {
    final isSelected = _typeFilter == type;
    final color = type != null ? _getActivityColor(type) : AppColors.secondary;

    return GestureDetector(
      onTap: () {
        setModalState(() => _typeFilter = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          _getTypeFilterLabel(type, l10n),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  bool get _isRateLimited {
    if (_rateLimitEndTime == null) return false;
    return DateTime.now().isBefore(_rateLimitEndTime!);
  }

  String get _rateLimitRemainingTime {
    if (_rateLimitEndTime == null) return '';
    final remaining = _rateLimitEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  void _startRateLimitTimer() {
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        if (!_isRateLimited) {
          _rateLimitTimer?.cancel();
          setState(() {
            _rateLimitEndTime = null;
            _refreshCount = 0;
          });
        } else {
          setState(() {}); // Update UI
        }
      }
    });
  }

  Future<void> _handleRefresh() async {
    // Check rate limit
    if (_isRateLimited) {
      if (mounted) {
        AppToast.warning(
          context,
          'Rate limited. Please wait $_rateLimitRemainingTime',
        );
      }
      return;
    }

    // Increment refresh count
    _refreshCount++;
    if (_refreshCount >= _maxRefreshes) {
      _rateLimitEndTime = DateTime.now().add(
        const Duration(minutes: _rateLimitMinutes),
      );
      _startRateLimitTimer();
      if (mounted) {
        AppToast.warning(
          context,
          'Too many refreshes. Please wait $_rateLimitMinutes minutes.',
        );
      }
    }

    await _activityService.refresh(force: true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animController.dispose();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final groupedActivities = _groupActivitiesByDate(l10n);
    final hasActiveFilters =
        _timeFilter != ActivityTimeFilter.last10Days || _typeFilter != null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.gray,
          image: DecorationImage(
            image: AssetImage('assets/images/Element.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(l10n, isRTL, hasActiveFilters),

              // Active filters indicator
              if (hasActiveFilters) _buildActiveFiltersBar(l10n),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredActivities.isEmpty
                    ? _buildEmptyState(l10n)
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          color: AppColors.secondary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: groupedActivities.length,
                            itemBuilder: (context, index) {
                              final dateKey = groupedActivities.keys.elementAt(
                                index,
                              );
                              final activities = groupedActivities[dateKey]!;

                              return _buildDateSection(
                                dateKey,
                                activities,
                                l10n,
                                index,
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    AppLocalizations l10n,
    bool isRTL,
    bool hasActiveFilters,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: AppColors.secondary,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              l10n.allActivities,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                fontFamily: 'Nunito Sans',
              ),
            ),
          ),

          // Filter button
          Container(
            decoration: BoxDecoration(
              color: hasActiveFilters ? AppColors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: hasActiveFilters ? Colors.white : AppColors.secondary,
                size: 22,
              ),
              onPressed: _showFilterBottomSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_getTimeFilterLabel(_timeFilter, l10n)}${_typeFilter != null ? ' • ${_getTypeFilterLabel(_typeFilter, l10n)}' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _timeFilter = ActivityTimeFilter.last10Days;
                _typeFilter = null;
                _applyFilters();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SingleChildScrollView(child: SkeletonAllActivities());
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                color: AppColors.secondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noRecentActivities,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _timeFilter != ActivityTimeFilter.all || _typeFilter != null
                  ? l10n.noActivitiesForFilter
                  : l10n.activitiesWillAppearHere,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (_timeFilter != ActivityTimeFilter.last10Days ||
                _typeFilter != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _timeFilter = ActivityTimeFilter.last10Days;
                    _typeFilter = null;
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text(l10n.clearFilters),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(
    String dateKey,
    List<RewardActivity> activities,
    AppLocalizations l10n,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) const SizedBox(height: 20),
        // Date header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            dateKey,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.3,
            ),
          ),
        ),
        // Activities
        ...activities.asMap().entries.map((entry) {
          final activity = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildActivityCard(activity, l10n),
          );
        }),
      ],
    );
  }

  Widget _buildActivityCard(RewardActivity activity, AppLocalizations l10n) {
    final color = _getActivityColor(activity.activityType);
    final isTopUp = activity.activityType == ActivityType.topUp;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _buildActivityIcon(activity.activityType, color),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActivityTitle(activity, l10n),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getActivitySubtitle(activity.activityType, l10n),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeAgo(activity.createdAt, l10n),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // For topups: show amount + points, otherwise just points
                if (isTopUp && activity.amount != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Amount badge (primary - TND)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.2),
                              const Color(0xFF10B981).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${_formatAmount(activity.amount!)} TND',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 13,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Points badge (secondary - smaller)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFFD700).withValues(alpha: 0.2),
                              const Color(0xFFFFA500).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${activity.pointsEarned} pts',
                          style: const TextStyle(
                            color: Color(0xFFD4900A),
                            fontSize: 11,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Points only
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFFD700).withValues(alpha: 0.25),
                          const Color(0xFFFFA500).withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '+',
                          style: TextStyle(
                            color: Color(0xFFD4900A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${activity.pointsEarned}',
                          style: const TextStyle(
                            color: Color(0xFFD4900A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIcon(ActivityType type, Color color) {
    IconData iconData;
    switch (type) {
      case ActivityType.adWatched:
        iconData = Icons.smart_display_rounded;
        break;
      case ActivityType.dailyCheckIn:
        iconData = Icons.verified_rounded;
        break;
      case ActivityType.topUp:
        iconData = Icons.payments_rounded;
        break;
      case ActivityType.referral:
        iconData = Icons.group_add_rounded;
        break;
      case ActivityType.unknown:
        iconData = Icons.auto_awesome_rounded;
        break;
    }

    return Icon(iconData, color: color, size: 26);
  }

  /// Format amount - show whole number if no decimals, otherwise show decimals
  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(3);
  }
}
