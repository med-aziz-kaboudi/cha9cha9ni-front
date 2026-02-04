import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../ad_helper.dart';
import '../rewards_model.dart';
import '../rewards_service.dart';
import '../rewards_api_service.dart';

/// Embeddable rewards content widget - use this in home screens
class RewardsContent extends StatefulWidget {
  const RewardsContent({super.key});

  @override
  State<RewardsContent> createState() => _RewardsContentState();
}

class _RewardsContentState extends State<RewardsContent>
    with SingleTickerProviderStateMixin {
  final _rewardsService = RewardsService();
  final _rewardsApiService = RewardsApiService();

  RewardsData? _data;
  DailyCheckInStatus? _checkInStatus;
  bool _isWatchingAd = false;
  bool _isLoadingAd = false;
  bool _isCheckingIn = false;
  StreamSubscription? _dataSubscription;
  RewardedAd? _rewardedAd;
  Timer? _countdownTimer;
  Duration _timeUntilNextCheckIn = Duration.zero;

  // Rate limiting: 4 refreshes, then 10 min cooldown
  static const int _maxRefreshes = 4;
  static const int _rateLimitMinutes = 10;
  int _refreshCount = 0;
  DateTime? _rateLimitEndTime;
  Timer? _rateLimitTimer;

  late AnimationController _coinAnimController;

  // Updated redeemable rewards with correct TND to points conversion
  // 1 TND = 10,000 points
  final List<RedeemableReward> _redeemableRewards = [
    RedeemableReward(
      id: '1',
      name: '1 TND',
      description: 'Redeem for 1 TND',
      pointsCost: 10000,
      icon: Icons.monetization_on,
      color: const Color(0xFF4CAF50),
      tndValue: 1,
    ),
    RedeemableReward(
      id: '2',
      name: '5 TND',
      description: 'Redeem for 5 TND',
      pointsCost: 50000,
      icon: Icons.monetization_on,
      color: const Color(0xFF2196F3),
      tndValue: 5,
    ),
    RedeemableReward(
      id: '3',
      name: '10 TND',
      description: 'Redeem for 10 TND',
      pointsCost: 100000,
      icon: Icons.monetization_on,
      color: const Color(0xFF9C27B0),
      tndValue: 10,
    ),
    RedeemableReward(
      id: '4',
      name: '50 TND',
      description: 'Redeem for 50 TND',
      pointsCost: 500000,
      icon: Icons.monetization_on,
      color: const Color(0xFFFF9800),
      tndValue: 50,
    ),
    RedeemableReward(
      id: '5',
      name: '100 TND',
      description: 'Redeem for 100 TND (Max)',
      pointsCost: 1000000,
      icon: Icons.workspace_premium,
      color: const Color(0xFFFFD700),
      tndValue: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _coinAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _coinAnimController.repeat(reverse: true);

    // Initialize rewards service for socket updates
    _rewardsService.initialize();
    
    _loadCachedData();
    _subscribeToUpdates();
    _fetchFreshData();
    _loadRewardedAd();
    _startCountdownTimer();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedPoints = prefs.getInt('rewards_total_points');
    final cachedFamilyName = prefs.getString('rewards_family_name');
    final cachedStreak = prefs.getInt('rewards_current_streak');
    final cachedCanCheckIn = prefs.getBool('rewards_can_checkin');
    final cachedAdsWatched = prefs.getInt('rewards_ads_watched');

    if (cachedPoints != null || cachedFamilyName != null) {
      setState(() {
        _data = RewardsData(
          familyId: prefs.getString('rewards_family_id') ?? '',
          familyName: cachedFamilyName ?? 'My Family',
          totalPoints: cachedPoints ?? 0,
          tndValue: 0,
          memberCount: prefs.getInt('rewards_member_count') ?? 1,
          user: UserRewardsProgress(
            id: '',
            adsWatchedToday: cachedAdsWatched ?? 0,
            remainingAds: 5 - (cachedAdsWatched ?? 0),
            claimedSlots: [],
            nextSlotIndex: (cachedAdsWatched ?? 0) + 1,
            nextSlotPoints: _getSlotPoints((cachedAdsWatched ?? 0) + 1),
          ),
          slots: _buildDefaultSlots(cachedAdsWatched ?? 0),
          recentActivity: [],
        );

        _checkInStatus = DailyCheckInStatus(
          canCheckIn: cachedCanCheckIn ?? true,
          currentStreak: cachedStreak ?? 0,
          lastCheckInDate: null,
          totalCheckIns: 0,
          nextRewardPoints: _getStreakPoints((cachedStreak ?? 0) + 1),
          streakDay: cachedStreak ?? 0,
        );
      });
    }
  }

  List<RewardSlot> _buildDefaultSlots(int adsWatched) {
    return List.generate(
      5,
      (i) => RewardSlot(
        index: i + 1,
        points: _getSlotPoints(i + 1),
        claimed: i < adsWatched,
      ),
    );
  }

  int _getSlotPoints(int slot) {
    // Slots 1-3: 10 points, Slots 4-5: 15 points
    const slotPoints = [0, 10, 10, 10, 15, 15];
    if (slot <= 0 || slot > 5) return 10;
    return slotPoints[slot];
  }

  Future<void> _saveToCache() async {
    if (_data == null) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('rewards_family_id', _data!.familyId);
    await prefs.setString('rewards_family_name', _data!.familyName);
    await prefs.setInt('rewards_total_points', _data!.totalPoints);
    await prefs.setInt('rewards_member_count', _data!.memberCount);
    await prefs.setInt('rewards_ads_watched', _data!.user.adsWatchedToday);

    if (_checkInStatus != null) {
      await prefs.setInt(
        'rewards_current_streak',
        _checkInStatus!.currentStreak,
      );
      await prefs.setBool('rewards_can_checkin', _checkInStatus!.canCheckIn);
    }
  }

  void _subscribeToUpdates() {
    _dataSubscription = _rewardsService.dataStream.listen((data) {
      if (mounted) {
        setState(() => _data = data);
        _saveToCache();
      }
    });
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

  Future<void> _fetchFreshData() async {
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

    try {
      final results = await Future.wait([
        _rewardsService.fetchRewardsData(),
        _rewardsApiService.getCheckInStatus(),
      ]);

      if (mounted) {
        setState(() {
          _data = results[0] as RewardsData;
          _checkInStatus = results[1] as DailyCheckInStatus;
        });
        _saveToCache();
      }
    } catch (e) {
      debugPrint('Failed to fetch rewards data: $e');
    }
  }

  void _loadRewardedAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    setState(() => _isLoadingAd = true);

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _rewardedAd = ad;
              _isLoadingAd = false;
            });
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Failed to load rewarded ad: ${error.message}');
          if (mounted) setState(() => _isLoadingAd = false);
        },
      ),
    );
  }

  Future<void> _performDailyCheckIn() async {
    if (_isCheckingIn || _checkInStatus == null || !_checkInStatus!.canCheckIn)
      return;

    setState(() => _isCheckingIn = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await _rewardsApiService.performCheckIn();

      if (mounted) {
        HapticFeedback.heavyImpact();

        setState(() {
          _checkInStatus = DailyCheckInStatus(
            canCheckIn: false,
            currentStreak: result.currentStreak,
            lastCheckInDate: DateTime.now().toString().split(' ')[0],
            totalCheckIns: result.totalCheckIns,
            nextRewardPoints: _getStreakPoints(result.currentStreak + 1),
            streakDay: result.currentStreak,
          );

          if (_data != null) {
            _data = _data!.copyWith(totalPoints: result.newTotalPoints);
          }
        });

        _saveToCache();
        _showRewardOverlay(
          result.pointsEarned,
          AppLocalizations.of(context)!.rewardsDailyReward,
          Icons.wb_sunny,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  int _getStreakPoints(int day) {
    const streakPoints = [0, 10, 15, 20, 25, 30, 35, 40];
    if (day <= 0) return streakPoints[1];
    if (day >= 7) return streakPoints[7];
    return streakPoints[day];
  }

  Future<void> _watchAd() async {
    if (_isWatchingAd || _data == null || _data!.user.remainingAds <= 0) return;

    if (_rewardedAd == null) {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        await _watchAdSimulated();
        return;
      }

      AppToast.info(context, AppLocalizations.of(context)!.rewardsLoadingAd);
      _loadRewardedAd();
      return;
    }

    setState(() => _isWatchingAd = true);
    HapticFeedback.mediumImpact();

    // Reset any stale session before starting new one
    _rewardsService.resetAdSession();
    final clientEventId = _rewardsService.startWatchingAd();
    debugPrint('🎬 Ad session started: $clientEventId');
    bool adCompleted = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('🎬 Ad dismissed, adCompleted: $adCompleted');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        
        // Only cancel if user didn't earn reward (skipped/closed early)
        if (!adCompleted && mounted) {
          debugPrint('🎬 User skipped ad, cancelling session');
          _rewardsService.cancelAdWatch();
          setState(() => _isWatchingAd = false);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('🎬 Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _rewardsService.cancelAdWatch();
        _loadRewardedAd();
        if (mounted) {
          setState(() => _isWatchingAd = false);
          AppToast.error(context, AppLocalizations.of(context)!.rewardsAdFailed);
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint('🎬 User earned reward! Claiming with: $clientEventId');
        adCompleted = true;
        try {
          final result = await _rewardsService.completeAdWatch(clientEventId);
          if (mounted) {
            HapticFeedback.heavyImpact();
            _showRewardOverlay(
              result.pointsEarned,
              AppLocalizations.of(context)!.rewardsAdReward,
              Icons.play_circle_fill,
            );
            _saveToCache();
            setState(() => _isWatchingAd = false);
          }
        } catch (e) {
          debugPrint('❌ Failed to claim reward: $e');
          if (mounted) {
            AppToast.error(
              context,
              AppLocalizations.of(context)!.rewardsClaimFailed,
            );
            setState(() => _isWatchingAd = false);
          }
        }
      },
    );
    // Note: Don't await show() or check after - use callbacks only
  }

  Future<void> _watchAdSimulated() async {
    setState(() => _isWatchingAd = true);
    HapticFeedback.mediumImpact();

    try {
      final clientEventId = _rewardsService.startWatchingAd();
      final completed = await _showSimulatedAdDialog();

      if (completed) {
        final result = await _rewardsService.completeAdWatch(clientEventId);
        if (mounted) {
          HapticFeedback.heavyImpact();
          _showRewardOverlay(
            result.pointsEarned,
            AppLocalizations.of(context)!.rewardsAdReward,
            Icons.play_circle_fill,
          );
          _saveToCache();
        }
      } else {
        _rewardsService.cancelAdWatch();
      }
    } catch (e) {
      debugPrint('❌ Failed to claim reward: $e');
      _rewardsService.cancelAdWatch();
      if (mounted)
        AppToast.error(context, 'Failed to claim reward. Please try again.');
    } finally {
      if (mounted) setState(() => _isWatchingAd = false);
    }
  }

  Future<bool> _showSimulatedAdDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill,
                  color: AppColors.secondary,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.rewardsSimulatedAd),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.movie, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.rewardsSimulatedAdDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.rewardsSkipAd),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.rewardsWatchComplete),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  /// Show beautiful top overlay notification for rewards
  void _showRewardOverlay(int points, String source, IconData icon) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _RewardOverlay(
        points: points,
        source: source,
        icon: icon,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  void _startCountdownTimer() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    // Next check-in is at midnight (start of next day)
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final remaining = tomorrow.difference(now);
    
    if (mounted && _timeUntilNextCheckIn != remaining) {
      setState(() {
        _timeUntilNextCheckIn = remaining;
      });
    }
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _coinAnimController.dispose();
    _dataSubscription?.cancel();
    _rewardedAd?.dispose();
    _countdownTimer?.cancel();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchFreshData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildPointsHeader(),
                const SizedBox(height: 28),
                _buildDailyCheckIn(l10n),
                const SizedBox(height: 20),
                _buildWatchAdsSection(l10n),
                const SizedBox(height: 20),
                _buildRedeemableRewards(l10n),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsHeader() {
    final points = _data?.totalPoints ?? 0;
    final familyName = _data?.familyName ?? 'My Family';
    final streak = _checkInStatus?.currentStreak ?? 0;
    final adsWatched = 5 - (_data?.user.remainingAds ?? 5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          // Primary glow - sides and bottom only
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          // Secondary accent glow - bottom
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 25,
            spreadRadius: -5,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      child: Column(
        children: [
          // Family badge row with horisental.png
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    familyName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Horisental logo
              Image.asset(
                'assets/icons/horisental.png',
                height: 35,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Points display
          Text(
            _formatPoints(points),
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito Sans',
              height: 1,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.rewardsPoints,
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('🔥', '$streak', AppLocalizations.of(context)!.rewardsStreak),
                Container(width: 1, height: 30, color: AppColors.secondary.withValues(alpha: 0.2)),
                _buildMiniStat('📺', '$adsWatched/5', AppLocalizations.of(context)!.rewardsAds),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.secondary.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPoints(int points) {
    // Show full number with thousand separators on rewards screen
    return NumberFormatter.formatWithCommas(points);
  }

  Widget _buildDailyCheckIn(AppLocalizations l10n) {
    final canCheckIn = _checkInStatus?.canCheckIn ?? true;
    final streak = _checkInStatus?.currentStreak ?? 0;
    final nextPoints = _checkInStatus?.nextRewardPoints ?? 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=120&fit=crop',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.rewardsDailyCheckIn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '🔥 ${l10n.rewardsDayStreak(streak)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Streak days compact
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Days row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final done = day <= streak;
                    final isCurrent = day == streak + 1;
                    return _buildDayCircle(day, done, isCurrent);
                  }),
                ),
                const SizedBox(height: 16),
                // Check-in button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: canCheckIn
                      ? ElevatedButton(
                          onPressed: !_isCheckingIn ? _performDailyCheckIn : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isCheckingIn
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l10n.rewardsClaimPoints(nextPoints),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatCountdown(_timeUntilNextCheckIn),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(int day, bool done, bool isCurrent) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: done
                ? AppColors.secondary
                : isCurrent
                ? AppColors.secondary.withValues(alpha: 0.15)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: isCurrent && !done
                ? Border.all(color: AppColors.secondary, width: 2)
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$day',
                    style: TextStyle(
                      color: isCurrent
                          ? AppColors.secondary
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+${_getStreakPoints(day)}',
          style: TextStyle(
            color: done ? AppColors.secondary : Colors.grey.shade400,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWatchAdsSection(AppLocalizations l10n) {
    final remainingAds = _data?.user.remainingAds ?? 5;
    final nextPoints = _data?.user.nextSlotPoints ?? 10;
    final canWatch = remainingAds > 0 && !_isWatchingAd && !_isLoadingAd;
    final adsWatched = 5 - remainingAds;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&h=100&fit=crop',
                  width: double.infinity,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 90,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.rewardsWatchAndEarn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$adsWatched/5',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Slots compact
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Compact slot row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final slot = i + 1;
                    final done = slot <= adsWatched;
                    final isNext = slot == adsWatched + 1;
                    return _buildAdSlot(slot, done, isNext);
                  }),
                ),
                const SizedBox(height: 16),
                // Watch button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canWatch ? _watchAd : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canWatch
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isWatchingAd || _isLoadingAd
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            remainingAds > 0
                                ? l10n.rewardsWatchAdToEarn(nextPoints)
                                : l10n.rewardsAllAdsWatched,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdSlot(int slot, bool done, bool isNext) {
    final points = _getSlotPoints(slot);
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: done
                ? AppColors.primary
                : isNext
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: isNext && !done
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : Text(
                    '$slot',
                    style: TextStyle(
                      color: isNext ? AppColors.primary : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+$points',
          style: TextStyle(
            color: done ? AppColors.primary : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRedeemableRewards(AppLocalizations l10n) {
    final totalPoints = _data?.totalPoints ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?w=400&h=100&fit=crop',
                  width: double.infinity,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 90,
                    color: AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rewardsRedeemRewards,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.rewardsConvertPoints,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rewards list
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: _redeemableRewards.map((reward) {
                final canRedeem = totalPoints >= reward.pointsCost;
                final progress = (totalPoints / reward.pointsCost).clamp(
                  0.0,
                  1.0,
                );

                return _buildRewardTile(reward, canRedeem, progress, l10n);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTile(
    RedeemableReward reward,
    bool canRedeem,
    double progress,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: canRedeem
            ? AppColors.secondary.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: canRedeem
            ? Border.all(color: AppColors.secondary.withValues(alpha: 0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canRedeem ? () => _showRedeemDialog(reward) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Reward image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _getRewardImage(reward.tndValue),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      child: Center(
                        child: Text(
                          '${reward.tndValue}',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: canRedeem
                              ? AppColors.dark
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!canRedeem) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '${_formatPoints(reward.pointsCost)} pts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action
                if (canRedeem)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.rewardsRedeem,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRewardImage(int tndValue) {
    // Gift/reward themed images for each tier
    switch (tndValue) {
      case 1:
        // Bronze gift box
        return 'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?w=100&h=100&fit=crop';
      case 5:
        // Silver gift with ribbon
        return 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=100&h=100&fit=crop';
      case 10:
        // Gold wrapped gift
        return 'https://images.unsplash.com/photo-1512909006721-3d6018887383?w=100&h=100&fit=crop';
      case 50:
        // Premium golden gift
        return 'https://images.unsplash.com/photo-1577998474517-7eeeed4e448a?w=100&h=100&fit=crop';
      case 100:
        // Golden trophy cup
        return 'https://images.unsplash.com/photo-1567427017947-545c5f8d16ad?w=100&h=100&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?w=100&h=100&fit=crop';
    }
  }

  void _showRedeemDialog(RedeemableReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RedeemConfirmDialog(
        reward: reward,
        currentPoints: _data?.totalPoints ?? 0,
        onConfirm: () => _performRedemption(reward, dialogContext),
        getRewardImage: _getRewardImage,
        formatPoints: _formatPoints,
      ),
    );
  }

  Future<void> _performRedemption(RedeemableReward reward, BuildContext dialogContext) async {
    // Close the confirm dialog
    Navigator.of(dialogContext).pop();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );

    try {
      // Check if can redeem first
      final canRedeemResult = await _rewardsApiService.canRedeem();
      if (!canRedeemResult.canRedeem) {
        if (mounted) Navigator.of(context).pop(); // Close loading
        if (mounted) {
          AppToast.error(context, canRedeemResult.reason ?? 'Cannot redeem at this time');
        }
        return;
      }

      // Perform redemption
      final result = await _rewardsService.redeemPoints(reward.pointsCost);

      if (mounted) Navigator.of(context).pop(); // Close loading

      if (mounted && result.success) {
        // Show congrats animation
        _showCongratsAnimation(
          amountCredited: result.amountCredited,
          pointsSpent: result.pointsSpent,
          newBalance: result.newBalance,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showCongratsAnimation({
    required double amountCredited,
    required int pointsSpent,
    required double newBalance,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _CongratsOverlay(
          amountCredited: amountCredited,
          pointsSpent: pointsSpent,
          newBalance: newBalance,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Sleek top banner notification for rewards
class _RewardOverlay extends StatefulWidget {
  final int points;
  final String source;
  final IconData icon;
  final VoidCallback onDismiss;

  const _RewardOverlay({
    required this.points,
    required this.source,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<_RewardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) _dismiss();
        },
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    top: topPadding + 8,
                    left: 16,
                    right: 16,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.source,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Points earned!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Points badge
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: widget.points),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+$value',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RedeemableReward {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final IconData icon;
  final Color color;
  final int tndValue;

  RedeemableReward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.icon,
    required this.color,
    required this.tndValue,
  });
}

/// Legacy standalone screen - redirects to embedded content
/// Keep for backward compatibility if needed
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This shouldn't be used anymore, but if called, just show the content
    return const Scaffold(body: RewardsContent());
  }
}

/// Confirmation dialog for redeeming rewards
class _RedeemConfirmDialog extends StatelessWidget {
  final RedeemableReward reward;
  final int currentPoints;
  final VoidCallback onConfirm;
  final String Function(int) getRewardImage;
  final String Function(int) formatPoints;

  const _RedeemConfirmDialog({
    required this.reward,
    required this.currentPoints,
    required this.onConfirm,
    required this.getRewardImage,
    required this.formatPoints,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remainingPoints = currentPoints - reward.pointsCost;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reward image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.2),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${reward.tndValue}',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.rewardsConfirmRedeem,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          // Points breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  l10n.rewardsCurrentPoints,
                  formatPoints(currentPoints),
                  Colors.grey.shade700,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  l10n.rewardsPointsToSpend,
                  '-${formatPoints(reward.pointsCost)}',
                  Colors.red.shade600,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  l10n.rewardsRemainingPoints,
                  formatPoints(remainingPoints),
                  AppColors.secondary,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Amount to receive
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  const Color(0xFF4CAF50).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text(
                  '${reward.tndValue} TND',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.rewardsToBalance,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.rewardsRedeem,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Congrats animation overlay after successful redemption
class _CongratsOverlay extends StatefulWidget {
  final double amountCredited;
  final int pointsSpent;
  final double newBalance;
  final VoidCallback onDismiss;

  const _CongratsOverlay({
    required this.amountCredited,
    required this.pointsSpent,
    required this.newBalance,
    required this.onDismiss,
  });

  @override
  State<_CongratsOverlay> createState() => _CongratsOverlayState();
}

class _CongratsOverlayState extends State<_CongratsOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isDismissed) {
        _isDismissed = true;
        widget.onDismiss();
      }
    });
  }

  void _handleDismiss() {
    if (_isDismissed) return;
    _isDismissed = true;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _handleDismiss,
        child: Stack(
          children: [
            // Confetti particles
            ...List.generate(30, (index) => _buildConfettiParticle(index)),
            // Main content
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4CAF50),
                              const Color(0xFF81C784),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        l10n.rewardsCongratulations,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Amount
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withValues(alpha: 0.2),
                              AppColors.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: AppColors.secondary,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.amountCredited.toStringAsFixed(0)} TND',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Details
                      Text(
                        l10n.rewardsAddedToBalance,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.rewardsNewBalance}: ${widget.newBalance.toStringAsFixed(2)} TND',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Tap to dismiss hint
                      Text(
                        l10n.tapToDismiss,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfettiParticle(int index) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      AppColors.secondary,
    ];

    final random = index * 37 % 100;
    final startX = (random / 100) * MediaQuery.of(context).size.width;
    final delay = (index % 10) * 0.1;

    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        final progress = (_confettiController.value - delay).clamp(0.0, 1.0);
        final y = progress * MediaQuery.of(context).size.height * 1.2;
        final rotation = progress * 6 * 3.14159;
        final opacity = (1 - progress).clamp(0.0, 1.0);

        return Positioned(
          left: startX + (index % 3 == 0 ? 50 * progress : -50 * progress),
          top: y - 50,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(index % 2 == 0 ? 2 : 6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
