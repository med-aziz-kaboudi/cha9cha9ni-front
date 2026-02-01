import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/family_model.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart'
    show FamilyApiService, AuthenticationException;
import '../../core/services/session_manager.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/socket_service.dart'
    show PointsEarnedData, AidSelectedData, MemberLeftData, SocketService;
import '../../core/services/notification_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/skeleton_loading.dart';
import '../../core/widgets/tutorial_overlay.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../activity/activity_service.dart';
import '../activity/widgets/recent_activities_widget.dart';
import '../auth/screens/signin_screen.dart';
import '../family/family_selection_screen.dart';
import '../profile/screens/edit_profile_screen.dart';
import '../rewards/rewards_service.dart';
import '../rewards/screens/rewards_screen.dart';
import '../settings/screens/language_screen.dart';
import '../settings/screens/login_security_screen.dart';
import '../notifications/screens/notifications_screen.dart';
import '../scan/screens/scan_screen.dart';
import '../pack/screens/current_pack_screen.dart';
import '../pack/pack_models.dart';
import '../pack/pack_service.dart';
import '../statement/screens/statement_screen.dart';
import '../support/screens/tawkto_chat_screen.dart';
import 'widgets/home_header_widget.dart';

class FamilyMemberHomeScreen extends StatefulWidget {
  const FamilyMemberHomeScreen({super.key});

  @override
  State<FamilyMemberHomeScreen> createState() => _FamilyMemberHomeScreenState();
}

class _FamilyMemberHomeScreenState extends State<FamilyMemberHomeScreen>
    with WidgetsBindingObserver {
  // ignore: unused_field
  String _displayName = 'Loading...';
  String? _familyName;
  // ignore: unused_field
  String? _familyOwnerName;
  // ignore: unused_field
  String? _familyOwnerId;
  // ignore: unused_field
  bool _isLoadingFamily = true;
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  final _sessionManager = SessionManager();
  int _currentNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<String>? _sessionExpiredSubscription;

  // Family members state
  List<FamilyMember> _familyMembers = [];
  bool _isLoadingMembers = true;

  // Removal request state - owner requested to remove this member
  List<RemovalRequest> _removalRequests = [];
  // ignore: unused_field
  bool _isLoadingRemovalRequests = false;

  // Tutorial keys
  bool _showTutorial = false;
  final GlobalKey _sidebarKey = GlobalKey();
  final GlobalKey _topUpKey = GlobalKey();
  final GlobalKey _statementKey = GlobalKey();
  final GlobalKey _pointsKey = GlobalKey();
  final GlobalKey _notificationKey = GlobalKey();
  final GlobalKey _qrCodeKey = GlobalKey();
  final GlobalKey _rewardKey = GlobalKey();

  // Notification service
  final _notificationService = NotificationService();
  late int _notificationCount;
  StreamSubscription<int>? _unreadCountSubscription;

  // Rewards/Points
  final _rewardsService = RewardsService();
  int _familyPoints = 0;
  StreamSubscription? _rewardsSubscription;
  StreamSubscription<PointsEarnedData>? _pointsEarnedSubscription;

  // Pack/Selected Aid
  final _packService = PackService();
  SelectedAidModel? _selectedAid;
  int? _daysUntilAid;
  bool _aidWindowOpen = false;
  StreamSubscription<CurrentPackData>? _packDataSubscription;
  StreamSubscription<AidSelectedData>? _aidSelectedSubscription;

  // Leave family state
  final _socketService = SocketService();
  StreamSubscription<MemberLeftData>? _memberLeftSubscription;

  // Leave family rate limiting
  static const String _leaveAttemptKey = 'leave_family_attempts';
  static const String _leaveBlockedUntilKey = 'leave_family_blocked_until';
  static const int _maxLeaveAttempts = 3;
  static const int _blockDurationMinutes = 15;

  // Pull-to-refresh rate limiting
  static const int _maxRefreshes = 3;
  static const int _rateLimitMinutes = 15;
  int _refreshCount = 0;
  DateTime? _rateLimitEndTime;
  Timer? _rateLimitTimer;

  @override
  void initState() {
    super.initState();
    // Use cached notification count immediately
    _notificationCount = _notificationService.cachedUnreadCount;
    WidgetsBinding.instance.addObserver(this);
    _loadCachedDataFirst();
    _listenToSessionExpired();
    _initializeNotifications();
    _checkTutorialStatus();
    _loadFamilyPoints();
    _listenToPointsUpdates();
    _loadSelectedAid();
    _listenToPackUpdates();
    _listenToAidSelectedSocket();
    _listenToMemberLeft();
    // Delay loading removal requests to avoid too many simultaneous API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadRemovalRequests();
    });
  }

  Future<void> _checkTutorialStatus() async {
    final hasCompleted = await TutorialOverlay.hasCompletedTutorial();
    if (!hasCompleted && mounted) {
      // Small delay to let the UI render first
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _showTutorial = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionExpiredSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _rewardsSubscription?.cancel();
    _pointsEarnedSubscription?.cancel();
    _packDataSubscription?.cancel();
    _aidSelectedSubscription?.cancel();
    _memberLeftSubscription?.cancel();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  // Rate limiting helpers for pull-to-refresh
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
        }
      }
    });
  }

  Future<void> _handlePullToRefresh() async {
    // Check rate limit
    if (_isRateLimited) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppToast.warning(
          context,
          l10n?.rateLimitedWait(_rateLimitRemainingTime) ??
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
        final l10n = AppLocalizations.of(context);
        AppToast.warning(
          context,
          l10n?.tooManyRefreshes(_rateLimitMinutes) ??
              'Too many refreshes. Please wait $_rateLimitMinutes minutes.',
        );
      }
    }

    // Refresh all data
    await Future.wait([
      _refreshFamilyDataSilently(),
      _loadFamilyPoints(),
      _loadSelectedAid(),
      _loadRemovalRequests(),
      ActivityService().refresh(force: true),
    ]);
  }

  /// Load family points from rewards service
  Future<void> _loadFamilyPoints() async {
    // Load cached points first for instant display
    final prefs = await SharedPreferences.getInstance();
    final cachedPoints = prefs.getInt('rewards_total_points');
    if (cachedPoints != null && mounted) {
      setState(() {
        _familyPoints = cachedPoints;
      });
    }

    // Then fetch fresh data
    try {
      final data = await _rewardsService.fetchRewardsData();
      if (mounted) {
        setState(() {
          _familyPoints = data.totalPoints;
        });
        // Update cache
        await prefs.setInt('rewards_total_points', data.totalPoints);
      }
    } catch (e) {
      debugPrint('Failed to load family points: $e');
    }
  }

  /// Listen to realtime points updates
  void _listenToPointsUpdates() {
    _rewardsSubscription = _rewardsService.dataStream.listen((data) async {
      if (mounted) {
        setState(() {
          _familyPoints = data.totalPoints;
        });
        // Update cache for instant display next time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('rewards_total_points', data.totalPoints);
      }
    });

    // Also listen to socket for realtime updates
    _pointsEarnedSubscription = _sessionManager.socketService.onPointsEarned
        .listen((data) async {
          if (mounted) {
            setState(() {
              _familyPoints = data.newTotalPoints;
            });
            // Update cache for instant display next time
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('rewards_total_points', data.newTotalPoints);
          }
        });
  }

  /// Load selected aid from pack service (cache first, then API if needed)
  Future<void> _loadSelectedAid() async {
    try {
      // Initialize pack service (loads from cache first)
      await _packService.initialize();

      // Check cached data first for instant display
      final cachedAid = _packService.getCachedSelectedAid();
      if (cachedAid != null && mounted) {
        _updateSelectedAid(cachedAid);
      }

      // Only fetch from API if not fetched this session
      if (!_packService.hasFetchedOnce) {
        final packData = await _packService.fetchCurrentPack();
        _updateSelectedAid(
          packData.selectedAids.isNotEmpty ? packData.selectedAids.first : null,
        );
      }
    } catch (e) {
      debugPrint('Error loading selected aid: $e');
    }
  }

  /// Listen to pack updates for selected aid changes
  void _listenToPackUpdates() {
    _packDataSubscription = _packService.dataStream.listen((packData) {
      _updateSelectedAid(
        packData.selectedAids.isNotEmpty ? packData.selectedAids.first : null,
      );
    });
  }

  /// Listen to socket for real-time aid selection by owner
  void _listenToAidSelectedSocket() {
    _aidSelectedSubscription = _sessionManager.socketService.onAidSelected.listen((
      aidData,
    ) {
      if (mounted) {
        debugPrint(
          '🎊 Home: Received real-time aid selection: ${aidData.aidDisplayName}',
        );
        // Convert socket data to SelectedAidModel
        final aid = SelectedAidModel(
          id: aidData.aidId,
          aidId: aidData.aidId,
          aidName: aidData.aidName,
          aidDisplayName: aidData.aidDisplayName,
          maxWithdrawal: aidData.maxWithdrawal,
          windowStart: aidData.windowStart,
          windowEnd: aidData.windowEnd,
          status: 'selected',
        );
        _updateSelectedAid(aid);
      }
    });
  }

  /// Update selected aid and calculate days until window
  void _updateSelectedAid(SelectedAidModel? aid) {
    if (!mounted) return;

    if (aid == null) {
      setState(() {
        _selectedAid = null;
        _daysUntilAid = null;
        _aidWindowOpen = false;
      });
      return;
    }

    // Parse window start date (format: MM-DD)
    final now = DateTime.now();
    final windowStart = aid.windowStart;
    if (windowStart == null) {
      setState(() {
        _selectedAid = aid;
        _daysUntilAid = null;
        _aidWindowOpen = false;
      });
      return;
    }

    final parts = windowStart.split('-');
    if (parts.length == 2) {
      final month = int.tryParse(parts[0]) ?? 1;
      final day = int.tryParse(parts[1]) ?? 1;

      // Calculate target date (this year or next)
      var targetDate = DateTime(now.year, month, day);
      if (targetDate.isBefore(now)) {
        // Check if we're in the window (before window end)
        final windowEnd = aid.windowEnd;
        if (windowEnd != null) {
          final endParts = windowEnd.split('-');
          if (endParts.length == 2) {
            final endMonth = int.tryParse(endParts[0]) ?? 1;
            final endDay = int.tryParse(endParts[1]) ?? 1;
            var endDate = DateTime(now.year, endMonth, endDay);
            if (endDate.isBefore(targetDate)) {
              endDate = DateTime(now.year + 1, endMonth, endDay);
            }

            if (now.isBefore(endDate) || now.isAtSameMomentAs(endDate)) {
              // Window is open
              setState(() {
                _selectedAid = aid;
                _daysUntilAid = 0;
                _aidWindowOpen = true;
              });
              return;
            }
          }
        }
        // Window passed, next year
        targetDate = DateTime(now.year + 1, month, day);
      }

      final daysUntil = targetDate.difference(now).inDays;
      setState(() {
        _selectedAid = aid;
        _daysUntilAid = daysUntil;
        _aidWindowOpen = false;
      });
    } else {
      setState(() {
        _selectedAid = aid;
        _daysUntilAid = null;
        _aidWindowOpen = false;
      });
    }
  }

  /// Listen to member_left socket events (when another member leaves)
  void _listenToMemberLeft() {
    _memberLeftSubscription = _socketService.onMemberLeft.listen((data) {
      if (mounted) {
        debugPrint('👋 Family member left: ${data.memberName}');
        // Refresh family members list
        _refreshFamilyDataSilently();
        // Show a toast notification
        AppToast.info(context, '${data.memberName} has left the family');
      }
    });
  }

  /// Check if leave family is rate limited
  Future<bool> _isLeaveRateLimited() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUntil = prefs.getInt(_leaveBlockedUntilKey);
    if (blockedUntil != null) {
      final blockedUntilTime = DateTime.fromMillisecondsSinceEpoch(
        blockedUntil,
      );
      if (DateTime.now().isBefore(blockedUntilTime)) {
        return true;
      } else {
        // Block expired, reset attempts
        await prefs.remove(_leaveBlockedUntilKey);
        await prefs.remove(_leaveAttemptKey);
      }
    }
    return false;
  }

  /// Get remaining block time in minutes
  Future<int> _getLeaveBlockRemainingMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUntil = prefs.getInt(_leaveBlockedUntilKey);
    if (blockedUntil != null) {
      final blockedUntilTime = DateTime.fromMillisecondsSinceEpoch(
        blockedUntil,
      );
      final remaining = blockedUntilTime.difference(DateTime.now()).inMinutes;
      return remaining > 0 ? remaining + 1 : 0;
    }
    return 0;
  }

  /// Increment leave attempt and check if should block
  Future<bool> _incrementLeaveAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = prefs.getInt(_leaveAttemptKey) ?? 0;
    attempts++;
    await prefs.setInt(_leaveAttemptKey, attempts);

    if (attempts >= _maxLeaveAttempts) {
      // Block for 15 minutes
      final blockedUntil = DateTime.now().add(
        Duration(minutes: _blockDurationMinutes),
      );
      await prefs.setInt(
        _leaveBlockedUntilKey,
        blockedUntil.millisecondsSinceEpoch,
      );
      return true; // Now blocked
    }
    return false;
  }

  /// Reset leave attempts on success
  Future<void> _resetLeaveAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leaveAttemptKey);
    await prefs.remove(_leaveBlockedUntilKey);
  }

  /// Handle leave family button tap - shows bottom sheet with all states
  Future<void> _handleLeaveFamily() async {
    // Check rate limit first
    if (await _isLeaveRateLimited()) {
      final remainingMinutes = await _getLeaveBlockRemainingMinutes();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppToast.error(context, l10n.tooManyAttempts(remainingMinutes));
      }
      return;
    }

    // Show the new combined bottom sheet

    // Show the new combined bottom sheet
    _showLeaveFamilyBottomSheet();
  }

  /// Show family options bottom sheet
  void _showFamilyOptionsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Family info header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.secondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _familyName ?? l10n.myFamily,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF23233F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_familyMembers.length} ${l10n.members}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Owner info
                if (_familyOwnerName != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.owner,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _familyOwnerName!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Leave family button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    // Use Future.delayed to ensure bottom sheet is fully closed
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _handleLeaveFamily();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.leaveFamily,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.leaveFamilyWarning,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show leave family bottom sheet with confirmation and code input
  void _showLeaveFamilyBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (sheetContext) => _LeaveFamilyBottomSheet(
        familyName: _familyName,
        familyMembersCount: _familyMembers.length,
        ownerName: _familyOwnerName,
        familyApiService: _familyApiService,
        onSuccess: () async {
          Navigator.pop(sheetContext);
          await _resetLeaveAttempts();
          await _performLeaveAndNavigate();
        },
        onAttemptUsed: () async {
          await _incrementLeaveAttempt();
        },
        isRateLimited: _isLeaveRateLimited,
        getBlockRemainingMinutes: _getLeaveBlockRemainingMinutes,
      ),
    );
  }

  /// After successful leave, navigate to family selection screen
  Future<void> _performLeaveAndNavigate() async {
    final l10n = AppLocalizations.of(context)!;

    // Clear pack cache since we're leaving family
    await PackService().clearCache();
    PackService().reset();

    // Clear cached family info
    await _tokenStorage.clearFamilyInfo();

    // Force token refresh to get new token without family association
    // This ensures subsequent API calls (create/join family) work correctly
    debugPrint('🔄 Refreshing token after leaving family...');
    await _familyApiService.forceTokenRefresh();

    // Show success message
    AppToast.success(context, l10n.leaveFamilySuccess);

    // Track leave family event
    AnalyticsService().trackLeaveFamily();

    // Navigate to family selection screen where they can create or join a new family
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const FamilySelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back from background - validate session once
      debugPrint('📱 App resumed - validating session');
      _validateSessionOnce();
    }
  }

  /// Listen to session expired events from any API call
  void _listenToSessionExpired() {
    _sessionExpiredSubscription = _sessionManager.onSessionExpired.listen((
      reason,
    ) {
      if (mounted) {
        _showSessionExpiredDialog();
      }
    });
  }

  /// Initialize notification service and listen for updates
  Future<void> _initializeNotifications() async {
    // Connect WebSocket for real-time updates
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      // connect() will call fetchNotifications() internally after connecting
      _notificationService.connect(token);
    }

    // Listen for unread count changes (stream subscription)
    _unreadCountSubscription = _notificationService.unreadCount.listen((count) {
      if (mounted) {
        setState(() => _notificationCount = count);
      }
    });
  }

  /// Validate session once (called when app resumes from background)
  Future<void> _validateSessionOnce() async {
    try {
      await _familyApiService.validateSession();
    } on AuthenticationException catch (e) {
      debugPrint('🚫 Session validation failed: $e');
      // SessionManager.notifySessionExpired() is called in the API service
    } catch (e) {
      // Network errors or other issues - don't logout, just log
      debugPrint('⚠️ Session validation error (non-auth): $e');
    }
  }

  /// Open Tawk.to live chat support
  void _openTawkToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TawkToChatScreen()),
    );
  }

  /// Show dialog informing user another device logged in, then logout
  Future<void> _showSessionExpiredDialog() async {
    if (!mounted) return;

    // Check if already handling to prevent duplicate dialogs
    if (_sessionManager.isHandlingExpiration) {
      debugPrint('⚠️ Session expired dialog already showing, skipping');
      return;
    }

    // Mark as handling
    _sessionManager.markHandling();

    // Store parent context for navigation after dialog closes
    final parentContext = context;
    bool hasLoggedOut = false;

    // Auto logout timer - will logout after 3 seconds even if user doesn't click OK
    Timer? autoLogoutTimer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        // Start auto-logout timer
        autoLogoutTimer = Timer(const Duration(seconds: 3), () {
          if (!hasLoggedOut && Navigator.of(dialogContext).canPop()) {
            hasLoggedOut = true;
            Navigator.of(dialogContext).pop();
            _performSignOut(parentContext);
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.secondary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phonelink_erase_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  AppLocalizations.of(dialogContext)?.sessionExpiredTitle ??
                      'Session Expired',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  AppLocalizations.of(dialogContext)?.sessionExpiredMessage ??
                      'Another device has logged into your account. You will be signed out for security.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!hasLoggedOut) {
                        hasLoggedOut = true;
                        autoLogoutTimer?.cancel();
                        Navigator.of(dialogContext).pop();
                        _performSignOut(parentContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(dialogContext)?.ok ?? 'OK',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Clean up timer if dialog was dismissed another way
    autoLogoutTimer?.cancel();
  }

  /// Perform sign out and navigate to sign in screen
  Future<void> _performSignOut(BuildContext parentContext) async {
    debugPrint('🚪 Starting sign out process...');
    try {
      // Disconnect WebSocket first
      _sessionManager.disconnectSocket();

      await _tokenStorage.clearTokens();
      debugPrint('✅ Tokens cleared');
      await PendingVerificationHelper.clear();
      debugPrint('✅ Pending verification cleared');

      // Clear security cache so unlock screen doesn't show on next login
      await BiometricService().clearSecurityCache();
      debugPrint('✅ Security cache cleared');

      // Clear pack service cache
      await _packService.clearCache();
      _packService.reset();
      debugPrint('✅ Pack cache cleared');

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.signOut();
        debugPrint('✅ Supabase signed out');
      }

      // Reset session manager flag for next login
      _sessionManager.resetHandlingFlag();

      debugPrint('🔄 Attempting navigation to SignInScreen...');

      if (parentContext.mounted) {
        Navigator.of(parentContext, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
        debugPrint('✅ Navigation initiated');
      } else if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      _sessionManager.resetHandlingFlag();
      if (parentContext.mounted) {
        Navigator.of(parentContext, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      } else if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadCachedDataFirst() async {
    // Load display name
    final name = await _tokenStorage.getUserDisplayName();

    // Load cached family info first for instant display
    final cachedFamily = await _tokenStorage.getCachedFamilyInfo();
    final cachedMembers = await _tokenStorage.getCachedFamilyMembers();

    if (mounted) {
      setState(() {
        _displayName = name;
        if (cachedFamily != null) {
          _familyName = cachedFamily['familyName'];
          _familyOwnerName = cachedFamily['ownerName'];
          _isLoadingFamily = false;
        }
        // Load cached members for instant display
        if (cachedMembers.isNotEmpty) {
          _familyMembers = cachedMembers
              .map((m) => FamilyMember.fromJson(m))
              .toList();
          // Find owner ID
          final owner = _familyMembers.where((m) => m.isOwner).firstOrNull;
          if (owner != null) {
            _familyOwnerId = owner.id;
          }
          _isLoadingMembers = false;
        }
      });
    }

    // Only refresh from API if data is stale (>30 seconds old)
    // This avoids duplicate requests when navigating from main.dart
    final isFresh = await _tokenStorage.isFamilyDataFresh(thresholdSeconds: 30);
    if (!isFresh) {
      debugPrint('📦 Family data is stale, refreshing from API');
      _refreshFamilyDataSilently();
    } else {
      debugPrint('📦 Family data is fresh (< 30s), skipping API refresh');
      // Make sure we're not in loading state if we have cached data
      if (mounted && _familyMembers.isNotEmpty) {
        setState(() {
          _isLoadingMembers = false;
          _isLoadingFamily = false;
        });
      }
    }
  }

  /// Refresh family data silently without showing loading states
  Future<void> _refreshFamilyDataSilently() async {
    try {
      final family = await _familyApiService.getMyFamily();
      if (mounted && family != null) {
        // Extract owner's last name for family display name
        String? ownerLastName;
        if (family.ownerName != null && family.ownerName!.isNotEmpty) {
          final nameParts = family.ownerName!.trim().split(' ');
          ownerLastName = nameParts.length > 1
              ? nameParts.last
              : nameParts.first;
          ownerLastName =
              ownerLastName[0].toUpperCase() + ownerLastName.substring(1);
        }

        final familyDisplayName = ownerLastName ?? family.name;

        // Save to cache for next time
        await _tokenStorage.saveFamilyInfo(
          familyName: familyDisplayName,
          ownerName: family.ownerName,
          memberCount: family.memberCount,
          isOwner: family.isOwner,
          inviteCode: family.inviteCode,
        );

        // Cache members as JSON
        if (family.members != null) {
          await _tokenStorage.saveFamilyMembers(
            family.members!.map((m) => m.toJson()).toList(),
          );
        }

        setState(() {
          _familyName = familyDisplayName;
          _familyOwnerName = family.ownerName;
          _familyMembers = family.members ?? [];
          _isLoadingFamily = false;
          _isLoadingMembers = false;
          // Find owner ID
          final owner = _familyMembers.where((m) => m.isOwner).firstOrNull;
          if (owner != null) {
            _familyOwnerId = owner.id;
          }
        });
      }
    } on AuthenticationException catch (e) {
      debugPrint('🚫 Authentication failed in member home: $e');
      if (mounted) {
        await _handleSignOut(context);
      }
    } catch (e) {
      debugPrint('Error loading family info: $e');
      if (mounted) {
        if (_familyMembers.isEmpty) {
          setState(() {
            _isLoadingFamily = false;
            _isLoadingMembers = false;
          });
        }
        if (e.toString().contains('Session expired') ||
            e.toString().contains('Session invalidated')) {
          await _handleSignOut(context);
        }
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await _tokenStorage.clearTokens();
      await PendingVerificationHelper.clear();
      await BiometricService().clearSecurityCache();

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.signOut();
      }

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          '${AppLocalizations.of(context)?.signOutFailed ?? 'Sign out failed'}: ${e.toString()}',
        );
      }
    }
  }

  /// Load pending removal requests for this member
  Future<void> _loadRemovalRequests() async {
    setState(() => _isLoadingRemovalRequests = true);
    try {
      final requests = await _familyApiService.getMemberRemovalRequests();
      if (mounted) {
        setState(() {
          _removalRequests = requests;
          _isLoadingRemovalRequests = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading removal requests: $e');
      if (mounted) {
        setState(() => _isLoadingRemovalRequests = false);
      }
    }
  }

  /// Check if there's a pending removal request from the owner
  bool get _hasPendingRemovalFromOwner => _removalRequests.isNotEmpty;

  /// Get the owner's removal request if any
  RemovalRequest? get _ownerRemovalRequest =>
      _removalRequests.isNotEmpty ? _removalRequests.first : null;

  /// Handle accepting removal request
  Future<void> _handleAcceptRemoval(RemovalRequest request) async {
    final l10n = AppLocalizations.of(context);
    final ownerName = request.ownerName;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFEBC11).withValues(alpha: 0.2),
                      const Color(0xFFFF9500).withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Color(0xFFFF9500),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                l10n?.acceptRemoval ?? 'Accept Removal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23233F),
                ),
              ),
              const SizedBox(height: 12),

              // Owner info card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          ownerName.isNotEmpty
                              ? ownerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ownerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF23233F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                l10n?.acceptRemovalConfirm(ownerName) ??
                    '$ownerName wants to remove you from the family. Do you accept?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                              dialogContext,
                            )?.verificationCodeWillBeSent ??
                            'A verification code will be sent to your email',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n?.decline ?? 'Decline',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9500),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n?.accept ?? 'Accept',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _familyApiService.acceptRemoval(request.id);
      if (mounted) {
        _showMemberVerificationDialog(request);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Show dialog for member to enter verification code
  void _showMemberVerificationDialog(RemovalRequest request) {
    final codeController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.secondary.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  AppLocalizations.of(dialogContext)?.confirmLeave ??
                      'Confirm Leave',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF23233F),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  AppLocalizations.of(dialogContext)?.enterCodeSentToEmail ??
                      'Enter the verification code sent to your email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Code Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                      color: Color(0xFF23233F),
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        letterSpacing: 12,
                        color: Colors.grey[300],
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(dialogContext)?.cancel ??
                                'Cancel',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isVerifying
                              ? null
                              : () async {
                                  if (codeController.text.length != 6) {
                                    AppToast.error(
                                      dialogContext,
                                      AppLocalizations.of(
                                            dialogContext,
                                          )?.enterValidCode ??
                                          'Enter a valid 6-digit code',
                                    );
                                    return;
                                  }

                                  setDialogState(() => isVerifying = true);

                                  try {
                                    await _familyApiService
                                        .confirmMemberRemoval(
                                          request.id,
                                          codeController.text,
                                        );

                                    if (!dialogContext.mounted) return;
                                    Navigator.pop(dialogContext);
                                    _showRemovedFromFamilyDialog();
                                  } catch (e) {
                                    setDialogState(() => isVerifying = false);
                                    if (!dialogContext.mounted) return;
                                    AppToast.error(
                                      dialogContext,
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isVerifying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(dialogContext)?.verify ??
                                      'Verify',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show dialog that user has been removed from family
  void _showRemovedFromFamilyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.15),
                      Colors.teal.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                AppLocalizations.of(dialogContext)?.removedFromFamily ??
                    'Removed from Family',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23233F),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                AppLocalizations.of(dialogContext)?.removedFromFamilyDesc ??
                    'You have been successfully removed from the family. You can now join or create a new family.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // OK Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _handleSignOut(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(dialogContext)?.ok ?? 'OK',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _onNavBarTap(int index) {
    if (index == 1) {
      // Scan screen - navigate to it
      _openScanScreen();
      return;
    }

    // For home (0) and rewards (2), just switch the view
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _openScanScreen() async {
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (context) => const ScanScreen()));

    if (result != null && mounted) {
      // Handle the scanned code
      debugPrint('📷 Scanned code: $result');
      // TODO: Process the scanned code
    }
  }

  void _handleNotificationTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
    // No need to fetch on return - stream subscription handles real-time updates
  }

  void _navigateToRewards(BuildContext context) {
    // Switch to rewards tab in nav bar instead of pushing new route
    setState(() {
      _currentNavIndex = 2;
    });
  }

  void _navigateToStatement(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const StatementScreen()));
  }

  List<TutorialStep> _buildTutorialSteps() {
    final l10n = AppLocalizations.of(context)!;
    return [
      TutorialStep(
        targetKey: _sidebarKey,
        title: l10n.tutorialSidebarTitle,
        description: l10n.tutorialSidebarDesc,
        icon: Icons.menu_rounded,
      ),
      TutorialStep(
        targetKey: _topUpKey,
        title: l10n.tutorialTopUpTitle,
        description: l10n.tutorialTopUpDesc,
        icon: Icons.add_circle_outline,
      ),
      TutorialStep(
        targetKey: _statementKey,
        title: l10n.tutorialStatementTitle,
        description: l10n.tutorialStatementDesc,
        icon: Icons.receipt_long_outlined,
      ),
      TutorialStep(
        targetKey: _pointsKey,
        title: l10n.tutorialPointsTitle,
        description: l10n.tutorialPointsDesc,
        icon: Icons.stars_rounded,
      ),
      TutorialStep(
        targetKey: _notificationKey,
        title: l10n.tutorialNotificationTitle,
        description: l10n.tutorialNotificationDesc,
        icon: Icons.notifications_outlined,
      ),
      TutorialStep(
        targetKey: _qrCodeKey,
        title: l10n.tutorialQrCodeTitle,
        description: l10n.tutorialQrCodeDesc,
        icon: Icons.qr_code_scanner,
      ),
      TutorialStep(
        targetKey: _rewardKey,
        title: l10n.tutorialRewardTitle,
        description: l10n.tutorialRewardDesc,
        icon: Icons.emoji_events_outlined,
      ),
    ];
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _handlePullToRefresh,
      color: AppColors.secondary,
      displacement: 40,
      edgeOffset: MediaQuery.of(context).padding.top,
      child: Stack(
        children: [
          // Scrollable content - behind everything
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space for the fixed header
                  SizedBox(height: MediaQuery.of(context).size.height * 0.32),

                  // Pending removal banner (if any)
                  if (_hasPendingRemovalFromOwner) ...[
                    _buildPendingRemovalBanner(context),
                    const SizedBox(height: 16),
                  ],

                  // Next Withdrawal Card
                  _buildNextWithdrawalCard(context),

                  const SizedBox(height: 24),

                  // Family Members Section (view only)
                  _buildFamilyMembersSection(context),

                  const SizedBox(height: 24),

                  // Recent Activities Section
                  _buildRecentActivitiesSection(context),

                  // Bottom padding for nav bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Fixed Header on top - doesn't move
          // Member only sees TopUp and Statement (no Withdraw)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderWidget(
              points: _familyPoints,
              onTopUp: () {},
              onStatement: () => _navigateToStatement(context),
              showWithdraw: false, // Hide withdraw for members
              onPoints: () => _navigateToRewards(context),
              onNotification: () => _handleNotificationTap(context),
              notificationCount: _notificationCount,
              topUpKey: _topUpKey,
              statementKey: _statementKey,
              pointsKey: _pointsKey,
              notificationKey: _notificationKey,
            ),
          ),

          // Drawer handle - positioned at top (RTL aware)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: Directionality.of(context) == TextDirection.rtl ? null : 0,
            right: Directionality.of(context) == TextDirection.rtl ? 0 : null,
            child: GestureDetector(
              key: _sidebarKey,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 24,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.only(
                    topRight: Directionality.of(context) == TextDirection.rtl
                        ? Radius.zero
                        : const Radius.circular(24),
                    bottomRight: Directionality.of(context) == TextDirection.rtl
                        ? Radius.zero
                        : const Radius.circular(24),
                    topLeft: Directionality.of(context) == TextDirection.rtl
                        ? const Radius.circular(24)
                        : Radius.zero,
                    bottomLeft: Directionality.of(context) == TextDirection.rtl
                        ? const Radius.circular(24)
                        : Radius.zero,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Directionality.of(context) == TextDirection.rtl
                          ? const Offset(-2, 0)
                          : const Offset(2, 0),
                    ),
                  ],
                ),
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextWithdrawalCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Get emoji for aid type
    String getAidEmoji(String aidName) {
      switch (aidName.toLowerCase()) {
        case 'eid_fitr':
          return '🕌';
        case 'eid_adha':
          return '🐑';
        case 'ramadan':
          return '🌙';
        case 'moulid':
          return '☪️';
        case 'new_year':
          return '🎉';
        case 'ashura':
          return '🕯️';
        case 'valentines':
          return '❤️';
        case 'rentrée':
        case 'rentree':
          return '📚';
        case 'mothers_day':
          return '👩';
        case 'fathers_day':
          return '👨';
        default:
          return '🎊';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          // Navigate to pack screen (read-only for members)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CurrentPackScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _aidWindowOpen
                ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                : const Color(0xFFEE3764).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: _aidWindowOpen
                ? Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _aidWindowOpen
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                      : const Color(0xFFEE3764).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _selectedAid != null
                        ? getAidEmoji(_selectedAid!.aidName)
                        : '📅',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nextWithdrawal,
                      style: const TextStyle(
                        color: Color(0xFF13123A),
                        fontSize: 12,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_selectedAid != null) ...[
                      Text(
                        '${getAidEmoji(_selectedAid!.aidName)} ${_selectedAid!.aidDisplayName} - ${_selectedAid!.maxWithdrawal.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          color: Color(0xFF13123A),
                          fontSize: 12,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          _aidWindowOpen
                              ? l10n.aidWindowOpen
                              : (_daysUntilAid != null
                                    ? l10n.daysUntilAid(
                                        _daysUntilAid!,
                                        _selectedAid!.aidDisplayName,
                                      )
                                    : l10n.availableInDays(0)),
                          style: TextStyle(
                            color: _aidWindowOpen
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF13123A),
                            fontSize: 11,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ] else ...[
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          l10n.noAidSelected,
                          style: const TextStyle(
                            color: Color(0xFF13123A),
                            fontSize: 12,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: const Color(0xFF13123A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the family members section (view only, no add/remove)
  Widget _buildFamilyMembersSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Get the display name for family - translate "My Family" if it's the default
    String? displayFamilyName = _familyName;
    if (_familyName == 'My Family' ||
        _familyName == 'Ma Famille' ||
        _familyName == 'عائلتي') {
      displayFamilyName = l10n?.myFamily ?? _familyName;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header - no add button for members
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.familyMembers ?? 'Family Members',
                style: const TextStyle(
                  color: Color(0xFF23233F),
                  fontSize: 18,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Show family name badge - tappable for family options
              if (displayFamilyName != null && displayFamilyName.isNotEmpty)
                GestureDetector(
                  onTap: () => _showFamilyOptionsSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.family_restroom_rounded,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayFamilyName,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 14,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.secondary.withValues(alpha: 0.7),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingMembers)
            const SkeletonFamilyMembersRow(itemCount: 3)
          else if (_familyMembers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.noMembersYet ?? 'No members yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: () {
                  // Sort members: owner first, then others
                  final sortedMembers = [..._familyMembers]
                    ..sort((a, b) {
                      if (a.isOwner && !b.isOwner) return -1;
                      if (!a.isOwner && b.isOwner) return 1;
                      return 0;
                    });
                  return sortedMembers
                      .take(5)
                      .map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildFamilyMemberAvatar(member),
                        ),
                      )
                      .toList();
                }(),
              ),
            ),
        ],
      ),
    );
  }

  /// Build a family member avatar
  /// Owner shows in red with banner if there's a pending removal request
  Widget _buildFamilyMemberAvatar(FamilyMember member) {
    final isOwner = member.isOwner;
    final hasPendingRemoval = isOwner && _hasPendingRemovalFromOwner;

    return GestureDetector(
      onTap: hasPendingRemoval && _ownerRemovalRequest != null
          ? () => _handleAcceptRemoval(_ownerRemovalRequest!)
          : null,
      child: Column(
        children: [
          Stack(
            children: [
              // Main avatar container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: hasPendingRemoval
                        ? [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.3),
                          ]
                        : isOwner
                        ? [
                            AppColors.secondary.withValues(alpha: 0.15),
                            AppColors.secondary.withValues(alpha: 0.25),
                          ]
                        : [
                            AppColors.secondary.withValues(alpha: 0.1),
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: hasPendingRemoval
                        ? AppColors.primary
                        : isOwner
                        ? AppColors.secondary
                        : AppColors.secondary.withValues(alpha: 0.3),
                    width: hasPendingRemoval || isOwner ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: hasPendingRemoval
                          ? AppColors.primary
                          : isOwner
                          ? AppColors.secondary
                          : AppColors.secondary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Star badge for owner or warning for pending removal
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: hasPendingRemoval
                        ? AppColors.primary
                        : isOwner
                        ? AppColors.secondary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: (hasPendingRemoval || isOwner)
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: (hasPendingRemoval || isOwner)
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: hasPendingRemoval
                        ? const Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : isOwner
                        ? const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Name
          Column(
            children: [
              SizedBox(
                width: 65,
                child: Text(
                  member.name.split(' ').first,
                  style: TextStyle(
                    color: hasPendingRemoval
                        ? AppColors.primary
                        : const Color(0xFF23233F),
                    fontSize: 13,
                    fontFamily: 'DM Sans',
                    fontWeight: hasPendingRemoval
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOwner && !hasPendingRemoval)
                Text(
                  AppLocalizations.of(context)?.owner ?? 'Owner',
                  style: const TextStyle(
                    color: Color(0xFFFF9500),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (hasPendingRemoval)
                Text(
                  AppLocalizations.of(context)?.wantsToRemoveYou ??
                      'Wants to remove',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build pending removal banner at the top
  Widget _buildPendingRemovalBanner(BuildContext context) {
    if (!_hasPendingRemovalFromOwner || _ownerRemovalRequest == null) {
      return const SizedBox.shrink();
    }

    final request = _ownerRemovalRequest!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _handleAcceptRemoval(request),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Owner avatar (red)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Text(
                    request.ownerName.isNotEmpty
                        ? request.ownerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.removalRequestTitle ?? 'Removal Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.ownerRequestedRemoval(request.ownerName) ??
                          '${request.ownerName} has requested to remove you from the family',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n?.respond ?? 'Respond',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    return const RecentActivitiesWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: CustomDrawer(
            onLogout: () {
              Navigator.pop(context);
              _handleSignOut(context);
            },
            onPersonalInfo: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            onCurrentPack: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrentPackScreen(),
                ),
              );
            },
            onLoginSecurity: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginSecurityScreen(),
                ),
              );
            },
            onLanguages: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageScreen()),
              );
            },
            onNotifications: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              // No need to fetch on return - stream subscription handles real-time updates
            },
            onHelp: () {
              Navigator.pop(context);
              _openTawkToChat();
            },
            onLegalAgreements: () {
              Navigator.pop(context);
            },
            isOwner: false,
          ),
          body: IndexedStack(
            index: _currentNavIndex == 2 ? 1 : 0,
            children: [
              // Home content (index 0)
              _buildHomeContent(),
              // Rewards content (index 2 maps to 1 here)
              const RewardsContent(),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _currentNavIndex,
            onTap: _onNavBarTap,
            qrCodeKey: _qrCodeKey,
            rewardKey: _rewardKey,
          ),
        ),
        // Tutorial overlay
        if (_showTutorial)
          TutorialOverlay(
            steps: _buildTutorialSteps(),
            onComplete: () {
              setState(() {
                _showTutorial = false;
              });
            },
            onSkip: () {
              setState(() {
                _showTutorial = false;
              });
            },
          ),
      ],
    );
  }
}

/// Bottom sheet for leave family flow with all states
class _LeaveFamilyBottomSheet extends StatefulWidget {
  final String? familyName;
  final int familyMembersCount;
  final String? ownerName;
  final FamilyApiService familyApiService;
  final VoidCallback onSuccess;
  final Future<void> Function() onAttemptUsed;
  final Future<bool> Function() isRateLimited;
  final Future<int> Function() getBlockRemainingMinutes;

  const _LeaveFamilyBottomSheet({
    required this.familyName,
    required this.familyMembersCount,
    required this.ownerName,
    required this.familyApiService,
    required this.onSuccess,
    required this.onAttemptUsed,
    required this.isRateLimited,
    required this.getBlockRemainingMinutes,
  });

  @override
  State<_LeaveFamilyBottomSheet> createState() =>
      _LeaveFamilyBottomSheetState();
}

class _LeaveFamilyBottomSheetState extends State<_LeaveFamilyBottomSheet> {
  // States: 'sending', 'code', 'blocked'
  String _currentState = 'sending';

  final _codeController = TextEditingController();
  bool _isSendingCode = true; // Start as sending
  bool _isVerifying = false;
  String? _errorMessage;

  // Resend countdown
  int _resendCountdown = 0;
  Timer? _resendTimer;

  // Rate limit state
  int _blockedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _initAndSendCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Check rate limit and send code automatically
  Future<void> _initAndSendCode() async {
    final isBlocked = await widget.isRateLimited();
    if (isBlocked) {
      final minutes = await widget.getBlockRemainingMinutes();
      if (mounted) {
        setState(() {
          _blockedMinutes = minutes;
          _currentState = 'blocked';
        });
      }
      return;
    }

    // Send code automatically
    try {
      await widget.familyApiService.initiateSelfLeave();
      await widget.onAttemptUsed();

      // Check if now blocked after this attempt
      if (await widget.isRateLimited()) {
        final minutes = await widget.getBlockRemainingMinutes();
        if (mounted) {
          setState(() {
            _blockedMinutes = minutes;
            _currentState = 'blocked';
            _isSendingCode = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _currentState = 'code';
          _isSendingCode = false;
        });
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
          _currentState = 'code'; // Show code input with error
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    // Check rate limit
    if (await widget.isRateLimited()) {
      final minutes = await widget.getBlockRemainingMinutes();
      setState(() {
        _blockedMinutes = minutes;
        _currentState = 'blocked';
      });
      return;
    }

    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
    });

    try {
      await widget.familyApiService.initiateSelfLeave();
      await widget.onAttemptUsed();

      // Check if now blocked
      if (await widget.isRateLimited()) {
        final minutes = await widget.getBlockRemainingMinutes();
        setState(() {
          _blockedMinutes = minutes;
          _currentState = 'blocked';
          _isSendingCode = false;
        });
        return;
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppToast.success(context, l10n.codeSentAgain);
        setState(() => _isSendingCode = false);
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = l10n.enterAllDigits);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await widget.familyApiService.confirmSelfLeave(code);
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Family info header (always shown)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.familyName ?? l10n.myFamily,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF23233F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.familyMembersCount} ${l10n.members}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Owner info
              if (widget.ownerName != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.owner,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.ownerName!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Dynamic content based on state
              _buildStateContent(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(AppLocalizations l10n) {
    switch (_currentState) {
      case 'blocked':
        return _buildBlockedState(l10n);
      case 'code':
        return _buildCodeInputState(l10n);
      case 'sending':
      default:
        return _buildSendingState(l10n);
    }
  }

  Widget _buildSendingState(AppLocalizations l10n) {
    return Column(
      children: [
        // Warning message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.leaveFamilyWarning,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Loading indicator
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),

        Text(
          l10n.leaveFamilyCodeSent.replaceAll('sent', 'sending...'),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCodeInputState(AppLocalizations l10n) {
    return Column(
      children: [
        // Info text
        Text(
          l10n.leaveFamilyCodePrompt,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Code input
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            letterSpacing: 12,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 12),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Error message
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Resend button
        TextButton(
          onPressed: (_resendCountdown > 0 || _isSendingCode)
              ? null
              : _resendCode,
          child: _isSendingCode
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _resendCountdown > 0
                      ? '${l10n.resendCodeIn} ${_resendCountdown}s'
                      : l10n.resendCode,
                  style: TextStyle(
                    color: _resendCountdown > 0
                        ? Colors.grey
                        : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isVerifying
                    ? null
                    : () {
                        _resendTimer?.cancel();
                        Navigator.pop(context);
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.confirm,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBlockedState(AppLocalizations l10n) {
    return Column(
      children: [
        // Blocked icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block_rounded, color: Colors.red, size: 48),
        ),
        const SizedBox(height: 16),

        Text(
          l10n.tooManyAttemptsTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          l10n.tooManyAttempts(_blockedMinutes),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.ok,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
