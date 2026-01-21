import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart'
    show FamilyApiService, AuthenticationException;
import '../../core/services/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _displayName = 'Loading...';
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  final _sessionManager = SessionManager();
  int _currentNavIndex = 0;
  StreamSubscription<String>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDisplayName();
    _listenToSessionExpired();
    // WebSocket handles real-time session invalidation via SessionManager
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionExpiredSubscription?.cancel();
    super.dispose();
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
                        AppColors.primary.withOpacity(0.1),
                        AppColors.secondary.withOpacity(0.1),
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

  Future<void> _loadDisplayName() async {
    final name = await _tokenStorage.getUserDisplayName();
    if (mounted) {
      setState(() {
        _displayName = name;
      });
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Clear backend tokens and user profile
      await _tokenStorage.clearTokens();

      // Clear any pending verification
      await PendingVerificationHelper.clear();

      // Sign out from Supabase (if there's a session)
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.signOut();
      }

      // Navigate to sign in screen and clear all routes
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
    setState(() {
      _currentNavIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        // Center button - Add your scan/action logic here
        AppToast.comingSoon(
          context,
          AppLocalizations.of(context)!.scanButtonTapped,
        );
        break;
      case 2:
        // Reward - Navigate to rewards screen
        AppToast.comingSoon(
          context,
          AppLocalizations.of(context)!.rewardScreenComingSoon,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/icons/horisental.png',
                  width: MediaQuery.of(context).size.width * 0.60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 60),

                // Welcome text
                Text(
                  'Welcome!',
                  style: AppTextStyles.heading1.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // User name
                Text(
                  _displayName,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Sign out button
                GestureDetector(
                  onTap: () => _handleSignOut(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: ShapeDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)?.signOut ?? 'Sign Out',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
