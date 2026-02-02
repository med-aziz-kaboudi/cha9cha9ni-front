import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../../rewards/rewards_model.dart';
import '../activity_service.dart';
import '../screens/all_activities_screen.dart';

/// A reusable widget that displays recent family activities with real-time updates
class RecentActivitiesWidget extends StatefulWidget {
  /// Maximum number of activities to show (default: 7)
  final int maxActivities;

  /// Whether to show the "View All" button
  final bool showViewAll;

  const RecentActivitiesWidget({
    super.key,
    this.maxActivities = 7,
    this.showViewAll = true,
  });

  @override
  State<RecentActivitiesWidget> createState() => _RecentActivitiesWidgetState();
}

class _RecentActivitiesWidgetState extends State<RecentActivitiesWidget> {
  final _activityService = ActivityService();
  List<RewardActivity> _activities = [];
  StreamSubscription<List<RewardActivity>>? _subscription;
  bool _isLoading = true;
  bool _hasFetchedOnce = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _activityService.initialize();
      if (mounted) {
        final activities = _activityService.getRecentActivities(
          count: widget.maxActivities,
        );
        setState(() {
          _activities = activities;
          _isLoading = activities.isEmpty && !_hasFetchedOnce;
        });

        // If no cached data, fetch from API
        if (activities.isEmpty && !_hasFetchedOnce) {
          _fetchWithRetry();
        } else {
          _hasFetchedOnce = true;
          setState(() => _isLoading = false);
        }
      }

      _subscription = _activityService.activitiesStream.listen((activities) {
        if (mounted) {
          setState(() {
            _activities = activities.take(widget.maxActivities).toList();
            _isLoading = false;
            _hasFetchedOnce = true;
          });
        }
      });
    } catch (e) {
      debugPrint('RecentActivitiesWidget: Init error - $e');
      if (mounted && !_hasFetchedOnce) {
        _fetchWithRetry();
      }
    }
  }

  Future<void> _fetchWithRetry() async {
    if (_retryCount >= _maxRetries) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFetchedOnce = true;
        });
      }
      return;
    }

    try {
      await _activityService.refresh(force: true);
      if (mounted) {
        final activities = _activityService.getRecentActivities(
          count: widget.maxActivities,
        );
        setState(() {
          _activities = activities;
          _isLoading = false;
          _hasFetchedOnce = true;
          _retryCount = 0;
        });
      }
    } catch (e) {
      debugPrint(
        'RecentActivitiesWidget: Fetch error (retry $_retryCount) - $e',
      );
      _retryCount++;
      // Retry with exponential backoff
      final delay = Duration(seconds: _retryCount * 2);
      _retryTimer?.cancel();
      _retryTimer = Timer(delay, () {
        if (mounted && _activities.isEmpty) {
          _fetchWithRetry();
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  String _formatTimeAgo(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(date);
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? l10n.dayAgo(difference.inDays)
          : l10n.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? l10n.hourAgo(difference.inHours)
          : l10n.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? l10n.minAgo(difference.inMinutes)
          : l10n.minsAgo(difference.inMinutes);
    } else {
      return l10n.justNow;
    }
  }

  String _getActivityTitle(RewardActivity activity, AppLocalizations l10n) {
    final name = activity.memberName.split(' ').first;
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

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.adWatched:
        return Icons.smart_display_rounded;
      case ActivityType.dailyCheckIn:
        return Icons.verified_rounded;
      case ActivityType.topUp:
        return Icons.payments_rounded;
      case ActivityType.referral:
        return Icons.group_add_rounded;
      case ActivityType.unknown:
        return Icons.auto_awesome_rounded;
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

  /// Format amount - show whole number if no decimals, otherwise show decimals
  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(3);
  }

  void _navigateToAllActivities() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AllActivitiesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentActivities,
                style: const TextStyle(
                  color: Color(0xFF13123A),
                  fontSize: 16,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.showViewAll && _activities.isNotEmpty)
                GestureDetector(
                  onTap: _navigateToAllActivities,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.viewAll,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Show skeleton while loading, otherwise show activities or empty state
          if (_isLoading)
            const SkeletonRecentActivities(itemCount: 3)
          else if (_activities.isEmpty)
            _buildEmptyState(l10n)
          else
            Column(
              children: _activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _activities.length - 1 ? 10 : 0,
                  ),
                  child: _buildActivityCard(activity, l10n),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
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
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noRecentActivities,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(RewardActivity activity, AppLocalizations l10n) {
    final color = _getActivityColor(activity.activityType);
    final isTopUp = activity.activityType == ActivityType.topUp;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon container with gradient
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getActivityIcon(activity.activityType),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getActivityTitle(activity, l10n),
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 14,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(activity.createdAt, l10n),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontFamily: 'Nunito Sans',
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.2),
                          const Color(0xFF10B981).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${_formatAmount(activity.amount!)} TND',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
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
                          const Color(0xFFFFD700).withValues(alpha: 0.18),
                          const Color(0xFFFFA500).withValues(alpha: 0.08),
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
              // Points badge only
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.22),
                      const Color(0xFFFFA500).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${activity.pointsEarned}',
                  style: const TextStyle(
                    color: Color(0xFFD4900A),
                    fontSize: 14,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
