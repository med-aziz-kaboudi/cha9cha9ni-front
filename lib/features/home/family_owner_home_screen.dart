import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/family_model.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart'
    show FamilyApiService, AuthenticationException;
import '../../core/services/session_manager.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/socket_service.dart' show FamilyMemberJoinedData, PointsEarnedData, AidSelectedData, MemberLeftData, SocketService;
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/tutorial_overlay.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../activity/activity_service.dart';
import '../activity/widgets/recent_activities_widget.dart';
import '../auth/screens/signin_screen.dart';
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
import '../support/screens/tawkto_chat_screen.dart';
import 'widgets/home_header_widget.dart';

class FamilyOwnerHomeScreen extends StatefulWidget {
  const FamilyOwnerHomeScreen({super.key});

  @override
  State<FamilyOwnerHomeScreen> createState() => _FamilyOwnerHomeScreenState();
}

class _FamilyOwnerHomeScreenState extends State<FamilyOwnerHomeScreen>
    with WidgetsBindingObserver {
  // ignore: unused_field
  String _displayName = 'Loading...';
  // ignore: unused_field
  String? _inviteCode;
  // ignore: unused_field
  bool _isLoadingCode = true;
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  final _sessionManager = SessionManager();
  int _currentNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<String>? _sessionExpiredSubscription;
  StreamSubscription<FamilyMemberJoinedData>? _familyMemberJoinedSubscription;
  StreamSubscription<MemberLeftData>? _memberLeftSubscription;
  final _socketService = SocketService();

  // Family members state
  List<FamilyMember> _familyMembers = [];
  bool _isLoadingMembers = true;

  // Removal state
  String? _pendingRemovalRequestId;
  bool _isRemovingMember = false;

  // Tutorial keys
  bool _showTutorial = false;
  final GlobalKey _sidebarKey = GlobalKey();
  final GlobalKey _topUpKey = GlobalKey();
  final GlobalKey _withdrawKey = GlobalKey();
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

  @override
  void initState() {
    super.initState();
    // Use cached notification count immediately
    _notificationCount = _notificationService.cachedUnreadCount;
    WidgetsBinding.instance.addObserver(this);
    _loadFamilyPoints();
    _listenToPointsUpdates();
    _loadCachedDataFirst();
    _listenToSessionExpired();
    _listenToFamilyMemberJoined();
    _listenToMemberLeft();
    _initializeNotifications();
    _loadSelectedAid();
    _listenToPackUpdates();
    _listenToAidSelectedSocket();
    // WebSocket handles real-time session invalidation via SessionManager
    _checkTutorialStatus();
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
    _familyMemberJoinedSubscription?.cancel();
    _memberLeftSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _rewardsSubscription?.cancel();
    _pointsEarnedSubscription?.cancel();
    _packDataSubscription?.cancel();
    _aidSelectedSubscription?.cancel();
    super.dispose();
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
    _pointsEarnedSubscription = _sessionManager.socketService.onPointsEarned.listen((data) async {
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

  /// Load selected aid for next withdrawal display
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
        final data = await _packService.fetchCurrentPack();
        if (mounted && data.selectedAids.isNotEmpty) {
          _updateSelectedAid(data.selectedAids.first);
        }
      }
    } catch (e) {
      debugPrint('Failed to load selected aid: $e');
    }
  }

  /// Listen to pack data updates for real-time aid changes
  void _listenToPackUpdates() {
    _packDataSubscription = _packService.dataStream.listen((data) {
      if (mounted && data.selectedAids.isNotEmpty) {
        _updateSelectedAid(data.selectedAids.first);
      } else if (mounted) {
        setState(() {
          _selectedAid = null;
          _daysUntilAid = null;
          _aidWindowOpen = false;
        });
      }
    });
  }

  /// Listen to socket for real-time aid selection (also updates own screen)
  void _listenToAidSelectedSocket() {
    _aidSelectedSubscription = _sessionManager.socketService.onAidSelected.listen((aidData) {
      if (mounted) {
        debugPrint('🎊 Home: Received real-time aid selection: ${aidData.aidDisplayName}');
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

  /// Update selected aid and calculate days
  void _updateSelectedAid(SelectedAidModel aid) {
    final now = DateTime.now();
    int? daysUntil;
    bool windowOpen = false;

    if (aid.windowStart != null && aid.windowEnd != null) {
      final parts = aid.windowStart!.split('-');
      if (parts.length >= 2) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        
        // Create window start date for this year
        var windowStart = DateTime(now.year, month, day);
        
        // If window has passed this year, check next year
        if (windowStart.isBefore(now)) {
          // Check if we're within the window
          final endParts = aid.windowEnd!.split('-');
          if (endParts.length >= 2) {
            final endMonth = int.parse(endParts[0]);
            final endDay = int.parse(endParts[1]);
            final windowEnd = DateTime(now.year, endMonth, endDay);
            
            if (now.isAfter(windowStart) && now.isBefore(windowEnd.add(const Duration(days: 1)))) {
              // We're within the window!
              windowOpen = true;
              daysUntil = 0;
            } else {
              // Window has passed, calculate for next year
              windowStart = DateTime(now.year + 1, month, day);
              daysUntil = windowStart.difference(now).inDays;
            }
          }
        } else {
          // Window is upcoming this year
          daysUntil = windowStart.difference(now).inDays;
        }
      }
    }

    setState(() {
      _selectedAid = aid;
      _daysUntilAid = daysUntil;
      _aidWindowOpen = windowOpen;
    });
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

  /// Listen to family member joined events via WebSocket
  void _listenToFamilyMemberJoined() {
    _familyMemberJoinedSubscription = _sessionManager.onFamilyMemberJoined.listen((
      data,
    ) {
      if (mounted) {
        debugPrint('👨‍👩‍👧 New family member joined: ${data.memberName}');
        
        // Add the new member to the list
        final newMember = FamilyMember(
          id: data.memberId,
          name: data.memberName,
          email: data.memberEmail,
          isOwner: false,
        );
        
        setState(() {
          // Add member to list if not already present
          if (!_familyMembers.any((m) => m.id == data.memberId)) {
            _familyMembers.add(newMember);
          }
          // Update invite code
          _inviteCode = data.newInviteCode;
        });
        
        // Update cached data
        _tokenStorage.saveFamilyMembers(
          _familyMembers.map((m) => m.toJson()).toList(),
        );
        
        // Update cached invite code and member count
        _tokenStorage.saveFamilyInfo(
          inviteCode: data.newInviteCode,
          memberCount: _familyMembers.length,
        );
        
        // Show a toast notification
        AppToast.success(
          context,
          '${data.memberName} has joined your family!',
        );
      }
    });
  }

  /// Listen to member left events via WebSocket
  void _listenToMemberLeft() {
    _memberLeftSubscription = _socketService.onMemberLeft.listen((data) {
      if (mounted) {
        debugPrint('👋 Family member left: ${data.memberName}');
        
        // Remove the member from the list
        setState(() {
          _familyMembers.removeWhere((m) => m.id == data.memberId);
        });
        
        // Update cached data
        _tokenStorage.saveFamilyMembers(
          _familyMembers.map((m) => m.toJson()).toList(),
        );
        
        // Update cached member count
        _tokenStorage.saveFamilyInfo(
          memberCount: _familyMembers.length,
        );
        
        // Show a toast notification
        AppToast.info(
          context,
          '${data.memberName} has left the family',
        );
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
      MaterialPageRoute(
        builder: (context) => const TawkToChatScreen(),
      ),
    );
  }

  /// Show dialog informing user another device logged in, then logout
  Future<void> _showSessionExpiredDialog() async {
    if (!mounted) return;

    // Check if already handling to prevent duplicate dialogs
    if (_sessionManager.isHandlingExpiration) {
      // Already showing dialog from another source, skip
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

      // Clear activity cache
      await ActivityService().clearCache();
      debugPrint('✅ Activity cache cleared');

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
      debugPrint('   parentContext.mounted = ${parentContext.mounted}');

      if (parentContext.mounted) {
        Navigator.of(parentContext, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
        debugPrint('✅ Navigation initiated');
      } else {
        debugPrint('❌ parentContext not mounted, trying global navigation');
        // Fallback: use the current context if available
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      // Reset flag even on error
      _sessionManager.resetHandlingFlag();
      // Force navigate even if sign out fails
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
        if (cachedFamily != null && cachedFamily['inviteCode'] != null) {
          _inviteCode = cachedFamily['inviteCode'];
          _isLoadingCode = false;
        }
        // Load cached members for instant display
        if (cachedMembers.isNotEmpty) {
          _familyMembers = cachedMembers
              .map((m) => FamilyMember.fromJson(m))
              .toList();
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
          _isLoadingCode = false;
        });
      }
    }
  }

  /// Refresh family data silently without showing loading states
  Future<void> _refreshFamilyDataSilently() async {
    try {
      final family = await _familyApiService.getMyFamily();
      if (mounted && family != null) {
        // Save to cache for next time
        await _tokenStorage.saveFamilyInfo(
          familyName: family.name,
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
          _inviteCode = family.inviteCode;
          _isLoadingCode = false;
          _familyMembers = family.members ?? [];
          _isLoadingMembers = false;
        });
      }
    } on AuthenticationException catch (e) {
      // Authentication failed - user needs to re-login
      debugPrint('🚫 Authentication failed in owner home: $e');
      if (mounted) {
        await _handleSignOut(context);
      }
    } catch (e) {
      if (mounted) {
        // Only update loading state if we don't have cached data
        if (_familyMembers.isEmpty) {
          setState(() {
            _isLoadingCode = false;
            _isLoadingMembers = false;
          });
        }
        // Check if it's an auth error
        if (e.toString().contains('Session expired') ||
            e.toString().contains('Session invalidated')) {
          await _handleSignOut(context);
        }
      }
    }
  }

  Future<void> _refreshFamilyData() async {
    try {
      final family = await _familyApiService.getMyFamily();
      if (mounted && family != null) {
        // Save to cache for next time
        await _tokenStorage.saveFamilyInfo(
          familyName: family.name,
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
          _inviteCode = family.inviteCode;
          _isLoadingCode = false;
          _familyMembers = family.members ?? [];
          _isLoadingMembers = false;
        });
      }
    } on AuthenticationException catch (e) {
      // Authentication failed - user needs to re-login
      debugPrint('🚫 Authentication failed in owner home: $e');
      if (mounted) {
        await _handleSignOut(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCode = false;
          _isLoadingMembers = false;
        });
        // Check if it's an auth error
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
      await ActivityService().clearCache();

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
        AppToast.error(context, '${AppLocalizations.of(context)?.signOutFailed ?? 'Sign out failed'}: ${e.toString()}');
      }
    }
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
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const ScanScreen(),
      ),
    );
    
    if (result != null && mounted) {
      // Handle the scanned code - could be an invite code to add member
      debugPrint('📷 Scanned code: $result');
      // TODO: Process the scanned code (e.g., validate invite code)
    }
  }

  void _handleNotificationTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
    // No need to fetch on return - stream subscription handles real-time updates
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
    
    // No need to call fetchNotifications() here - connect() handles it
  }

  // ignore: unused_element
  void _copyInviteCode() {
    if (_inviteCode != null) {
      // Clipboard.setData(ClipboardData(text: _inviteCode!));
      AppToast.success(
        context,
        AppLocalizations.of(context)!.inviteCodeCopiedToClipboard,
      );
    }
  }

  /// Show dialog with invite code for adding new members
  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  color: AppColors.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                AppLocalizations.of(dialogContext)?.addMember ?? 'Add Member',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                AppLocalizations.of(dialogContext)?.shareInviteCodeDesc ??
                    'Share this code with your family member to add them',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Invite code container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: _isLoadingCode
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _inviteCode ?? '------',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () {
                              if (_inviteCode != null) {
                                Clipboard.setData(
                                  ClipboardData(text: _inviteCode!),
                                );
                                AppToast.success(
                                  dialogContext,
                                  AppLocalizations.of(
                                        dialogContext,
                                      )?.inviteCodeCopiedToClipboard ??
                                      'Invite code copied!',
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.copy_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip:
                                AppLocalizations.of(dialogContext)?.copy ??
                                'Copy',
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(dialogContext)?.close ?? 'Close',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Initiate member removal process
  Future<void> _initiateRemoval(FamilyMember member) async {
    // Show professional confirmation dialog
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
              // Warning Icon
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
                  Icons.person_remove_rounded,
                  color: Color(0xFFFF9500),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                AppLocalizations.of(dialogContext)?.removeMember ??
                    'Remove Member',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23233F),
                ),
              ),
              const SizedBox(height: 12),

              // Member Avatar & Name
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
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
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
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF23233F),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            member.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                AppLocalizations.of(
                      dialogContext,
                    )?.removeMemberConfirm(member.name) ??
                    'Are you sure you want to remove ${member.name} from the family?',
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
                          AppLocalizations.of(dialogContext)?.remove ??
                              'Remove',
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

    setState(() => _isRemovingMember = true);

    try {
      final result = await _familyApiService.initiateRemoval(member.id);
      _pendingRemovalRequestId = result['requestId'];

      if (mounted) {
        setState(() => _isRemovingMember = false);
        _showOwnerVerificationDialog(member);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRemovingMember = false);
        final errorMsg = e.toString().replaceAll('Exception: ', '');

        // Check if there's already a pending request - show cancel dialog instead
        if (errorMsg.toLowerCase().contains('already pending') ||
            errorMsg.toLowerCase().contains('pending request')) {
          // Fetch the pending request ID and show cancel dialog
          await _fetchAndShowCancelDialog(member);
        } else {
          AppToast.error(context, errorMsg);
        }
      }
    }
  }

  /// Fetch pending removal request and show cancel dialog
  Future<void> _fetchAndShowCancelDialog(FamilyMember member) async {
    try {
      // Get pending removal requests to find this member's request
      final requests = await _familyApiService.getOwnerRemovalRequests();
      final memberRequest = requests.firstWhere(
        (r) => r['memberId'] == member.id,
        orElse: () => <String, dynamic>{},
      );

      if (memberRequest.isNotEmpty && memberRequest['id'] != null) {
        // Create a new FamilyMember with pending removal info
        final memberWithPending = FamilyMember(
          id: member.id,
          name: member.name,
          email: member.email,
          isOwner: member.isOwner,
          hasPendingRemoval: true,
          pendingRemovalRequestId: memberRequest['id'],
          pendingRemovalStatus: memberRequest['status'],
        );
        _showCancelRemovalDialog(memberWithPending);
      } else {
        // Refresh to get updated state
        _refreshFamilyData();
      }
    } catch (e) {
      // Just refresh the family data
      _refreshFamilyData();
    }
  }

  /// Show dialog for owner to enter verification code
  void _showOwnerVerificationDialog(FamilyMember member) {
    final memberName = member.name;
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
                // Email Icon with animation feel
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
                  AppLocalizations.of(dialogContext)?.confirmRemoval ??
                      'Confirm Removal',
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
                          onPressed: () {
                            if (_pendingRemovalRequestId != null) {
                              _familyApiService.cancelRemoval(
                                _pendingRemovalRequestId!,
                              );
                            }
                            Navigator.pop(dialogContext);
                          },
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
                                    await _familyApiService.confirmOwnerRemoval(
                                      _pendingRemovalRequestId!,
                                      codeController.text,
                                    );

                                    if (!dialogContext.mounted) return;
                                    Navigator.pop(dialogContext);

                                    // OPTIMISTIC UPDATE: Update member status immediately
                                    setState(() {
                                      _familyMembers = _familyMembers.map((
                                        m,
                                      ) {
                                        if (m.id == member.id) {
                                          return FamilyMember(
                                            id: m.id,
                                            name: m.name,
                                            email: m.email,
                                            isOwner: m.isOwner,
                                            hasPendingRemoval: true,
                                            pendingRemovalRequestId:
                                                _pendingRemovalRequestId,
                                            pendingRemovalStatus:
                                                'owner_confirmed',
                                          );
                                        }
                                        return m;
                                      }).toList();
                                    });

                                    // Update cache
                                    _tokenStorage.updateMemberPendingStatus(
                                      memberId: member.id,
                                      hasPendingRemoval: true,
                                      pendingRemovalRequestId:
                                          _pendingRemovalRequestId,
                                      pendingRemovalStatus: 'owner_confirmed',
                                    );

                                    if (!context.mounted) return;
                                    AppToast.success(
                                      context,
                                      AppLocalizations.of(
                                            context,
                                          )?.removalInitiated(memberName) ??
                                          'Removal request sent to $memberName',
                                    );

                                    // Silently sync with server
                                    _refreshFamilyDataSilently();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          backgroundColor: const Color(0xFFFAFAFA),
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
                MaterialPageRoute(builder: (context) => const LoginSecurityScreen()),
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
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ).then((_) {
                // Refresh notification count when returning
                _notificationService.fetchUnreadCount();
              });
            },
            onHelp: () {
              Navigator.pop(context);
              _openTawkToChat();
            },
            onLegalAgreements: () {
              Navigator.pop(context);
            },
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
        targetKey: _withdrawKey,
        title: l10n.tutorialWithdrawTitle,
        description: l10n.tutorialWithdrawDesc,
        icon: Icons.account_balance_wallet_outlined,
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
    return Stack(
      children: [
        // Scrollable content - behind everything
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for the fixed header
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.32,
                ),

                // Next Withdrawal Card
                _buildNextWithdrawalCard(context),

                const SizedBox(height: 24),

                // Family Members Section
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeHeaderWidget(
            points: _familyPoints,
            onTopUp: () {},
            onWithdraw: () {},
            onStatement: () {},
            onNotification: () => _handleNotificationTap(context),
            notificationCount: _notificationCount,
            topUpKey: _topUpKey,
            withdrawKey: _withdrawKey,
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
    );
  }

  Widget _buildNextWithdrawalCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // If no aid selected, show placeholder
    if (_selectedAid == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CurrentPackScreen()),
            ).then((_) => _loadSelectedAid());
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEE3764).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEE3764).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🎁', style: TextStyle(fontSize: 20)),
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
                      Text(
                        l10n.selectAnAid,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
    
    // Get the emoji based on aid type
    String aidEmoji = '🎊';
    switch (_selectedAid!.aidName) {
      case 'aid_kbir':
      case 'aid_sghir':
        aidEmoji = '🕌';
        break;
      case 'ramadan':
        aidEmoji = '🌙';
        break;
      case 'valentine':
        aidEmoji = '❤️';
        break;
      case 'new_year':
        aidEmoji = '🎉';
        break;
      case 'back_to_school':
        aidEmoji = '📚';
        break;
      case 'independence_day':
      case 'revolution_day':
        aidEmoji = '🇹🇳';
        break;
      case 'mothers_day':
      case 'womens_day':
        aidEmoji = '💐';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CurrentPackScreen()),
          ).then((_) => _loadSelectedAid());
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _aidWindowOpen 
                ? AppColors.secondary.withValues(alpha: 0.1)
                : const Color(0xFFEE3764).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: _aidWindowOpen 
                ? Border.all(color: AppColors.secondary, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _aidWindowOpen 
                      ? AppColors.secondary.withValues(alpha: 0.2)
                      : const Color(0xFFEE3764).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(aidEmoji, style: const TextStyle(fontSize: 20)),
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
                    Text(
                      '$aidEmoji ${_selectedAid!.aidDisplayName} - ${_selectedAid!.maxWithdrawal} DT',
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
                            : _daysUntilAid != null 
                                ? l10n.availableInDays(_daysUntilAid!)
                                : '',
                        style: TextStyle(
                          color: _aidWindowOpen ? AppColors.secondary : const Color(0xFF13123A),
                          fontSize: 11,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

  Widget _buildFamilyMembersSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.familyMembers,
                style: const TextStyle(
                  color: Color(0xFF23233F),
                  fontSize: 18,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _showAddMemberDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add_rounded,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)?.addMember ?? 'Add Member',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingMembers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_familyMembers.where((m) => !m.isOwner).isEmpty)
            GestureDetector(
              onTap: _showAddMemberDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.noMembersYet ??
                          'No members yet',
                      style: const TextStyle(
                        color: Color(0xFF23233F),
                        fontSize: 16,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context)?.tapAddMemberToInvite ??
                          'Tap to invite your family members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontFamily: 'Nunito Sans',
                      ),
                    ),
                  ],
                ),
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
                children: [
                  ..._familyMembers
                      .where((m) => !m.isOwner)
                      .take(4)
                      .map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildFamilyMemberAvatar(member),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberAvatar(FamilyMember member) {
    final hasPendingRemoval = member.hasPendingRemoval;

    return GestureDetector(
      onTap: _isRemovingMember ? null : () => _handleMemberTap(member),
      child: Column(
        children: [
          Stack(
            children: [
              // Main avatar container - highlighted if pending removal
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
                        : AppColors.secondary.withValues(alpha: 0.3),
                    width: hasPendingRemoval ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: hasPendingRemoval
                          ? AppColors.primary
                          : AppColors.secondary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Badge - X for remove, check for cancel
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _isRemovingMember
                        ? Colors.grey
                        : hasPendingRemoval
                        ? Colors.green
                        : const Color(0xFFFEBC11),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      hasPendingRemoval
                          ? Icons.undo_rounded
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Name with pending indicator
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
              if (hasPendingRemoval)
                Text(
                  AppLocalizations.of(context)?.pendingRemoval ?? 'Pending',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handle tap on member avatar - show remove or cancel dialog
  Future<void> _handleMemberTap(FamilyMember member) async {
    // First check if member already has pending removal in local state
    if (member.hasPendingRemoval && member.pendingRemovalRequestId != null) {
      _showCancelRemovalDialog(member);
      return;
    }

    // Also check with backend for pending requests (in case local state is stale)
    try {
      final requests = await _familyApiService.getOwnerRemovalRequests();
      final memberRequest = requests.firstWhere(
        (r) => r['memberId'] == member.id,
        orElse: () => <String, dynamic>{},
      );

      if (memberRequest.isNotEmpty && memberRequest['id'] != null) {
        // There's a pending request - show cancel dialog
        final memberWithPending = FamilyMember(
          id: member.id,
          name: member.name,
          email: member.email,
          isOwner: member.isOwner,
          hasPendingRemoval: true,
          pendingRemovalRequestId: memberRequest['id'],
          pendingRemovalStatus: memberRequest['status'],
        );
        _showCancelRemovalDialog(memberWithPending);
        return;
      }
    } catch (e) {
      // If check fails, proceed with normal flow
      debugPrint('Error checking pending requests: $e');
    }

    // No pending request - show remove dialog
    _initiateRemoval(member);
  }

  /// Show cancel removal confirmation dialog
  Future<void> _showCancelRemovalDialog(FamilyMember member) async {
    final l10n = AppLocalizations.of(context);

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
                      Colors.green.withValues(alpha: 0.15),
                      Colors.teal.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.undo_rounded,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                l10n?.cancelRemovalRequest ?? 'Cancel Request',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23233F),
                ),
              ),
              const SizedBox(height: 12),

              // Member info
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
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.secondary.withValues(alpha: 0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF23233F),
                          ),
                        ),
                        Text(
                          member.email,
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
              const SizedBox(height: 16),

              // Description
              Text(
                l10n?.cancelRemovalConfirm(member.name) ??
                    'Are you sure you want to cancel the removal request for ${member.name}?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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
                          l10n?.cancel ?? 'No',
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
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n?.ok ?? 'Yes, Cancel',
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

    // OPTIMISTIC UPDATE: Update UI immediately before API call
    final memberId = member.id;
    final originalMembers = List<FamilyMember>.from(_familyMembers);

    setState(() {
      _familyMembers = _familyMembers.map((m) {
        if (m.id == memberId) {
          return FamilyMember(
            id: m.id,
            name: m.name,
            email: m.email,
            isOwner: m.isOwner,
            hasPendingRemoval: false, // Clear pending status immediately
            pendingRemovalRequestId: null,
            pendingRemovalStatus: null,
          );
        }
        return m;
      }).toList();
    });

    // Update cache optimistically
    await _tokenStorage.updateMemberPendingStatus(
      memberId: memberId,
      hasPendingRemoval: false,
      pendingRemovalRequestId: null,
      pendingRemovalStatus: null,
    );

    try {
      await _familyApiService.cancelRemoval(member.pendingRemovalRequestId!);

      if (mounted) {
        AppToast.success(
          context,
          l10n?.removalCancelled ?? 'Removal request cancelled',
        );
        // Silently refresh to sync with server
        _refreshFamilyDataSilently();
      }
    } catch (e) {
      // ROLLBACK: Restore original state on error
      if (mounted) {
        setState(() {
          _familyMembers = originalMembers;
        });
        // Rollback cache
        await _tokenStorage.updateMemberPendingStatus(
          memberId: memberId,
          hasPendingRemoval: true,
          pendingRemovalRequestId: member.pendingRemovalRequestId,
          pendingRemovalStatus: member.pendingRemovalStatus,
        );
        if (!context.mounted) return;
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    return const RecentActivitiesWidget();
  }
}
