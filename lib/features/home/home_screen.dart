import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart' show FamilyApiService, AuthenticationException;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
  int _currentNavIndex = 0;
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDisplayName();
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
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
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
                AppLocalizations.of(context)?.sessionExpiredTitle ?? 'Session Expired',
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
                AppLocalizations.of(context)?.sessionExpiredMessage ?? 
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
                    Navigator.of(context).pop();
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
                    AppLocalizations.of(context)?.ok ?? 'OK',
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
    
    // Handle navigation based on index
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        // Center button - Add your scan/action logic here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.scanButtonTapped)),
        );
        break;
      case 2:
        // Reward - Navigate to rewards screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.rewardScreenComingSoon)),
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
                        'Sign Out',
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
