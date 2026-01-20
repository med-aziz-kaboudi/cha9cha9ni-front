import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart' show FamilyApiService, AuthenticationException;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';

class FamilyMemberHomeScreen extends StatefulWidget {
  const FamilyMemberHomeScreen({super.key});

  @override
  State<FamilyMemberHomeScreen> createState() => _FamilyMemberHomeScreenState();
}

class _FamilyMemberHomeScreenState extends State<FamilyMemberHomeScreen> with WidgetsBindingObserver {
  String _displayName = 'Loading...';
  String? _familyName;
  String? _familyOwnerName;
  int? _memberCount;
  bool _isLoadingFamily = true;
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
        if (cachedFamily != null) {
          _familyName = cachedFamily['familyName'];
          _familyOwnerName = cachedFamily['ownerName'];
          _memberCount = cachedFamily['memberCount'];
          _isLoadingFamily = false;
        }
      });
    }
    
    // Then refresh from API in background
    _refreshFamilyInfo();
  }

  Future<void> _refreshFamilyInfo() async {
    try {
      final family = await _familyApiService.getMyFamily();
      if (mounted && family != null) {
        // Extract owner's last name for family display name
        String? ownerLastName;
        if (family.ownerName != null && family.ownerName!.isNotEmpty) {
          final nameParts = family.ownerName!.trim().split(' ');
          ownerLastName = nameParts.length > 1 ? nameParts.last : nameParts.first;
          // Capitalize first letter
          ownerLastName = ownerLastName[0].toUpperCase() + ownerLastName.substring(1);
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
        
        setState(() {
          _familyName = familyDisplayName;
          _familyOwnerName = family.ownerName;
          _memberCount = family.memberCount;
          _isLoadingFamily = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingFamily = false;
        });
      }
    } on AuthenticationException catch (e) {
      // Authentication failed - user needs to re-login
      debugPrint('🚫 Authentication failed in member home: $e');
      if (mounted) {
        await _handleSignOut(context);
      }
    } catch (e) {
      debugPrint('Error loading family info: $e');
      if (mounted) {
        setState(() {
          _isLoadingFamily = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
          child: Stack(
            children: [
              // Quarter circle drawer handle at left edge
              Positioned(
                top: MediaQuery.of(context).padding.top + 5,
                left: Directionality.of(context) == TextDirection.rtl ? null : 0,
                right: Directionality.of(context) == TextDirection.rtl ? 0 : null,
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    width: 28,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.only(
                        topRight: Directionality.of(context) == TextDirection.rtl ? Radius.zero : const Radius.circular(28),
                        bottomRight: Directionality.of(context) == TextDirection.rtl ? Radius.zero : const Radius.circular(28),
                        topLeft: Directionality.of(context) == TextDirection.rtl ? const Radius.circular(28) : Radius.zero,
                        bottomLeft: Directionality.of(context) == TextDirection.rtl ? const Radius.circular(28) : Radius.zero,
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
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/horisental.png',
                      width: MediaQuery.of(context).size.width * 0.60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      AppLocalizations.of(context)!.welcomeFamilyMember,
                      style: AppTextStyles.heading1.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayName,
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: 18,
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Family Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.family_restroom,
                            size: 48,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingFamily)
                            const CircularProgressIndicator()
                          else ...[
                            Text(
                              AppLocalizations.of(context)!.yourFamily,
                              style: AppTextStyles.heading1.copyWith(
                                fontSize: 24,
                                color: AppColors.dark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_familyName != null && _familyName!.isNotEmpty) ...[
                              Text(
                                _familyName!,
                                style: AppTextStyles.heading1.copyWith(
                                  fontSize: 28,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_familyOwnerName != null) ...[
                              Text(
                                '${AppLocalizations.of(context)!.owner}: $_familyOwnerName',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_memberCount != null)
                              Text(
                                '${AppLocalizations.of(context)!.members}: $_memberCount',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
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
                            AppLocalizations.of(context)!.signOut,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
