import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart' show FamilyApiService, AuthenticationException;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';
import 'widgets/home_header_widget.dart';

class FamilyOwnerHomeScreen extends StatefulWidget {
  const FamilyOwnerHomeScreen({super.key});

  @override
  State<FamilyOwnerHomeScreen> createState() => _FamilyOwnerHomeScreenState();
}

class _FamilyOwnerHomeScreenState extends State<FamilyOwnerHomeScreen> with WidgetsBindingObserver {
  // ignore: unused_field
  String _displayName = 'Loading...';
  // ignore: unused_field
  String? _inviteCode;
  // ignore: unused_field
  bool _isLoadingCode = true;
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  int _currentNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedDataFirst();
    _startSessionValidation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back from background - check if session is still valid
      debugPrint('📱 App resumed - validating session');
      _validateSession();
    }
  }

  /// Start periodic session validation (every 5 seconds)
  void _startSessionValidation() {
    _sessionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _validateSession();
      }
    });
  }

  /// Validate session and logout if invalid
  Future<void> _validateSession() async {
    try {
      await _familyApiService.validateSession();
    } on AuthenticationException catch (e) {
      debugPrint('🚫 Session validation failed: $e');
      if (mounted) {
        _sessionCheckTimer?.cancel(); // Stop checking
        await _showSessionExpiredDialog();
      }
    } catch (e) {
      // Network errors or other issues - don't logout, just log
      debugPrint('⚠️ Session validation error (non-auth): $e');
    }
  }

  /// Show dialog informing user another device logged in, then logout
  Future<void> _showSessionExpiredDialog() async {
    if (!mounted) return;
    
    // Store parent context for navigation after dialog closes
    final parentContext = context;
    bool hasLoggedOut = false;
    
    // Auto logout timer - will logout after 3 seconds even if user doesn't click OK
    Timer? autoLogoutTimer;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
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
                  AppLocalizations.of(dialogContext)?.sessionExpiredTitle ?? 'Session Expired',
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
    try {
      await _tokenStorage.clearTokens();
      await PendingVerificationHelper.clear();
      
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.signOut();
      }
      
      if (parentContext.mounted) {
        Navigator.of(parentContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      // Force navigate even if sign out fails
      if (parentContext.mounted) {
        Navigator.of(parentContext).pushAndRemoveUntil(
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
    
    if (mounted) {
      setState(() {
        _displayName = name;
        if (cachedFamily != null && cachedFamily['inviteCode'] != null) {
          _inviteCode = cachedFamily['inviteCode'];
          _isLoadingCode = false;
        }
      });
    }
    
    // Then refresh from API in background
    _refreshInviteCode();
  }

  Future<void> _refreshInviteCode() async {
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
        
        setState(() {
          _inviteCode = family.inviteCode;
          _isLoadingCode = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    
    switch (index) {
      case 0:
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.scanButtonTapped)),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.rewardScreenComingSoon)),
        );
        break;
    }
  }

  void _handleNotificationTap(BuildContext context) {
    // TODO: Navigate to notifications screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications coming soon!'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  // ignore: unused_element
  void _copyInviteCode() {
    if (_inviteCode != null) {
      // Clipboard.setData(ClipboardData(text: _inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.inviteCodeCopiedToClipboard),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: CustomDrawer(
        onLogout: () {
          Navigator.pop(context);
          _handleSignOut(context);
        },
        onPersonalInfo: () {
          Navigator.pop(context);
        },
        onCurrentPack: () {
          Navigator.pop(context);
        },
        onLoginSecurity: () {
          Navigator.pop(context);
        },
        onLanguages: () {
          Navigator.pop(context);
        },
        onNotifications: () {
          Navigator.pop(context);
        },
        onHelp: () {
          Navigator.pop(context);
        },
        onLegalAgreements: () {
          Navigator.pop(context);
        },
      ),
      body: Stack(
        children: [
          // Scrollable content - behind everything
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space for the fixed header
                  SizedBox(height: MediaQuery.of(context).size.height * 0.32),
                  
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
              onTopUp: () {},
              onWithdraw: () {},
              onStatement: () {},
              onNotification: () => _handleNotificationTap(context),
              notificationCount: 3, // TODO: Replace with actual notification count
            ),
          ),
          
          // Drawer handle - positioned at top (RTL aware)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: Directionality.of(context) == TextDirection.rtl ? null : 0,
            right: Directionality.of(context) == TextDirection.rtl ? 0 : null,
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 24,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.only(
                    topRight: Directionality.of(context) == TextDirection.rtl ? Radius.zero : const Radius.circular(24),
                    bottomRight: Directionality.of(context) == TextDirection.rtl ? Radius.zero : const Radius.circular(24),
                    topLeft: Directionality.of(context) == TextDirection.rtl ? const Radius.circular(24) : Radius.zero,
                    bottomLeft: Directionality.of(context) == TextDirection.rtl ? const Radius.circular(24) : Radius.zero,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Directionality.of(context) == TextDirection.rtl ? const Offset(-2, 0) : const Offset(2, 0),
                    ),
                  ],
                ),
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildNextWithdrawalCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEE3764).withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEE3764).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🎊', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.nextWithdrawal,
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 12,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    '🎊 Aid Kbir - 1000 DT',
                    style: TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 12,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Opacity(
                    opacity: 0.6,
                    child: Text(
                      AppLocalizations.of(context)!.availableInDays(23),
                      style: const TextStyle(
                        color: Color(0xFF13123A),
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
              Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
              color: const Color(0xFF13123A),
            ),
          ],
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
                onTap: () {},
                child: Text(
                  AppLocalizations.of(context)!.manage,
                  style: const TextStyle(
                    color: Color(0xFFEE3764),
                    fontSize: 14,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFamilyMemberAvatar('John'),
                const SizedBox(width: 20),
                _buildFamilyMemberAvatar('Loui William'),
                const SizedBox(width: 20),
                _buildFamilyMemberAvatar('Hannahsx'),
                const SizedBox(width: 20),
                _buildFamilyMemberAvatar('Leahaed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberAvatar(String name) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CC3C7),
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDDDDD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Yellow badge
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEBC11),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF23233F),
            fontSize: 14,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentActivities,
                style: const TextStyle(
                  color: Color(0xFF13123A),
                  fontSize: 16,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  AppLocalizations.of(context)!.viewAll,
                  style: const TextStyle(
                    color: Color(0xFFEE3764),
                    fontSize: 14,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            emoji: '💸',
            title: 'Aid Kbir Withdrawal',
            date: 'Jun 9, 2025',
            amount: '- 1000 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💰',
            title: 'Deposit from john',
            date: 'Jun 5, 2025',
            amount: '+ 500 DT',
            amountColor: const Color(0xFF4CC3C7),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🎁',
            title: 'Ads earning (aziz)',
            date: 'Jun 5, 2025',
            amount: '+ 10 Points',
            amountColor: const Color(0xFFD8B217),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💳',
            title: 'Monthly subscription',
            date: 'Jun 1, 2025',
            amount: '- 50 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💰',
            title: 'Deposit from Sarah',
            date: 'May 28, 2025',
            amount: '+ 750 DT',
            amountColor: const Color(0xFF4CC3C7),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🛒',
            title: 'Shopping expense',
            date: 'May 25, 2025',
            amount: '- 200 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🎁',
            title: 'Referral bonus',
            date: 'May 20, 2025',
            amount: '+ 25 Points',
            amountColor: const Color(0xFFD8B217),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💰',
            title: 'Deposit from Mike',
            date: 'May 15, 2025',
            amount: '+ 300 DT',
            amountColor: const Color(0xFF4CC3C7),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🏠',
            title: 'Rent payment',
            date: 'May 10, 2025',
            amount: '- 800 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🎁',
            title: 'Daily login reward',
            date: 'May 5, 2025',
            amount: '+ 5 Points',
            amountColor: const Color(0xFFD8B217),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String emoji,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CC3C7).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF13123A),
                    fontSize: 14,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Opacity(
                  opacity: 0.6,
                  child: Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 12,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 12,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
