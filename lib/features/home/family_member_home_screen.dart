import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/family_model.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart'
    show FamilyApiService, AuthenticationException;
import '../../core/services/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';
import '../profile/screens/edit_profile_screen.dart';
import '../settings/screens/language_screen.dart';
import '../settings/screens/login_security_screen.dart';

class FamilyMemberHomeScreen extends StatefulWidget {
  const FamilyMemberHomeScreen({super.key});

  @override
  State<FamilyMemberHomeScreen> createState() => _FamilyMemberHomeScreenState();
}

class _FamilyMemberHomeScreenState extends State<FamilyMemberHomeScreen>
    with WidgetsBindingObserver {
  String _displayName = 'Loading...';
  String? _familyName;
  String? _familyOwnerName;
  int? _memberCount;
  bool _isLoadingFamily = true;
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  final _sessionManager = SessionManager();
  int _currentNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<String>? _sessionExpiredSubscription;

  // Removal request state
  List<RemovalRequest> _removalRequests = [];
  bool _isLoadingRemovalRequests = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedDataFirst();
    _listenToSessionExpired();
    // WebSocket handles real-time session invalidation via SessionManager
    _loadRemovalRequests();
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
          ownerLastName = nameParts.length > 1
              ? nameParts.last
              : nameParts.first;
          // Capitalize first letter
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
        AppToast.error(context, '${AppLocalizations.of(context)?.signOutFailed ?? 'Sign out failed'}: ${e.toString()}');
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

  /// Handle accepting removal request
  Future<void> _handleAcceptRemoval(RemovalRequest request) async {
    final l10n = AppLocalizations.of(context);
    final ownerName = request.ownerName;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
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
                      const Color(0xFFFEBC11).withOpacity(0.2),
                      const Color(0xFFFF9500).withOpacity(0.2),
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
                            AppColors.secondary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.2),
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
      barrierColor: Colors.black.withOpacity(0.6),
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
                        AppColors.primary.withOpacity(0.15),
                        AppColors.secondary.withOpacity(0.15),
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

                                    if (mounted) {
                                      Navigator.pop(dialogContext);
                                      // Show success and redirect to sign in
                                      _showRemovedFromFamilyDialog();
                                    }
                                  } catch (e) {
                                    setDialogState(() => isVerifying = false);
                                    if (mounted) {
                                      AppToast.error(
                                        dialogContext,
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                      );
                                    }
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
      barrierColor: Colors.black.withOpacity(0.6),
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
                      Colors.green.withOpacity(0.15),
                      Colors.teal.withOpacity(0.15),
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

  /// Build removal request card widget
  Widget _buildRemovalRequestCard(RemovalRequest request) {
    final l10n = AppLocalizations.of(context);
    final ownerName = request.ownerName;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.removalRequestTitle ?? 'Removal Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.removalRequestDesc(ownerName) ??
                '$ownerName wants to remove you from the family.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleAcceptRemoval(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n?.viewRequest ?? 'View Request'),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        AppToast.comingSoon(
          context,
          AppLocalizations.of(context)!.scanButtonTapped,
        );
        break;
      case 2:
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
      key: _scaffoldKey,
      drawer: CustomDrawer(
        onLogout: () {
          Navigator.pop(context);
          _handleSignOut(context);
        },
        onPersonalInfo: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        },
        onCurrentPack: () {
          Navigator.pop(context);
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
                left: Directionality.of(context) == TextDirection.rtl
                    ? null
                    : 0,
                right: Directionality.of(context) == TextDirection.rtl
                    ? 0
                    : null,
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    width: 28,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.only(
                        topRight:
                            Directionality.of(context) == TextDirection.rtl
                            ? Radius.zero
                            : const Radius.circular(28),
                        bottomRight:
                            Directionality.of(context) == TextDirection.rtl
                            ? Radius.zero
                            : const Radius.circular(28),
                        topLeft: Directionality.of(context) == TextDirection.rtl
                            ? const Radius.circular(28)
                            : Radius.zero,
                        bottomLeft:
                            Directionality.of(context) == TextDirection.rtl
                            ? const Radius.circular(28)
                            : Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.3),
                          blurRadius: 8,
                          offset:
                              Directionality.of(context) == TextDirection.rtl
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
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Add spacing at top
                      const SizedBox(height: 20),

                      // Removal requests section (if any)
                      if (_isLoadingRemovalRequests)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: CircularProgressIndicator(),
                        )
                      else if (_removalRequests.isNotEmpty) ...[
                        ..._removalRequests.map(
                          (request) => _buildRemovalRequestCard(request),
                        ),
                        const SizedBox(height: 20),
                      ],

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
                              if (_familyName != null &&
                                  _familyName!.isNotEmpty) ...[
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
                      // Bottom spacing for nav bar
                      const SizedBox(height: 20),
                    ],
                  ),
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
