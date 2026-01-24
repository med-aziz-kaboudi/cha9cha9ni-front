import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/family/family_selection_screen.dart';
import 'features/home/family_owner_home_screen.dart';
import 'features/home/family_member_home_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/auth/services/auth_api_service.dart';
import 'features/auth/models/auth_request_models.dart';
import 'features/settings/screens/app_unlock_screen.dart';
import 'features/activity/activity_service.dart';
import 'core/screens/offline_screen.dart';
import 'core/services/language_service.dart';
import 'core/services/token_storage_service.dart';
import 'core/services/family_api_service.dart' show FamilyApiService, AuthenticationException;
import 'core/services/session_manager.dart';
import 'core/services/biometric_service.dart';
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Make Android system navigation bar transparent so our nav bar shows through
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Initialize Mobile Ads SDK (only on mobile platforms)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await MobileAds.instance.initialize();
  }
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://wfqglbotmchhopdgfclx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmcWdsYm90bWNoaG9wZGdmY2x4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNzcxMTAsImV4cCI6MjA4MzY1MzExMH0.gVyQTGRQVT5S3xxgConvbakuv6AYDe_D0vTOy-4Oyc8',
  );
  
  // Load saved language
  await LanguageService().loadLanguage();
  
  runApp(const Cha9cha9niApp());
}

class Cha9cha9niApp extends StatelessWidget {
  const Cha9cha9niApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();
    
    return ValueListenableBuilder<Locale>(
      valueListenable: languageService.currentLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Cha9cha9ni',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('fr'),
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          builder: (context, child) {
            // Force RTL for Arabic
            return Directionality(
              textDirection: locale.languageCode == 'ar' 
                  ? TextDirection.rtl 
                  : TextDirection.ltr,
              child: child!,
            );
          },
          home: const AppEntry(),
        );
      },
    );
  }
}

// Global navigator key for programmatic navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Helper class for managing pending email verification state
class PendingVerificationHelper {
  static const String _pendingVerificationKey = 'pending_verification_email';
  static const String _pendingVerificationTimestampKey = 'pending_verification_timestamp';
  static const int _expiryMinutes = 5; // Verification session expires after 5 minutes

  /// Save pending verification email to local storage with timestamp
  static Future<void> save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_pendingVerificationKey, email);
    await prefs.setInt(_pendingVerificationTimestampKey, timestamp);
    debugPrint('📧 Saved pending verification for: $email (expires in $_expiryMinutes minutes)');
  }

  /// Clear pending verification from local storage
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingVerificationKey);
    await prefs.remove(_pendingVerificationTimestampKey);
    debugPrint('📧 Cleared pending verification');
  }

  /// Get pending verification email from local storage (returns null if expired)
  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingVerificationKey);
    final timestamp = prefs.getInt(_pendingVerificationTimestampKey);
    
    if (email == null || timestamp == null) {
      return null;
    }
    
    // Check if expired (5 minutes = 300000 milliseconds)
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiryTime = timestamp + (_expiryMinutes * 60 * 1000);
    
    if (now > expiryTime) {
      // Expired - clear and return null
      debugPrint('📧 Pending verification expired for: $email');
      await clear();
      return null;
    }
    
    final remainingSeconds = ((expiryTime - now) / 1000).round();
    debugPrint('📧 Pending verification still valid for $email (${remainingSeconds}s remaining)');
    return email;
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _isAuthenticated = false;
  bool _needsVerification = false;
  bool _isProcessingOAuth = false; // Loading state during OAuth callback
  bool _needsSecurityUnlock = false; // Whether app is locked and needs unlock
  bool _isCheckingSecurityStatus = false; // Prevent duplicate checks
  bool _isOffline = false; // Whether device has no internet connection
  bool _initializationComplete = false; // Track if app initialization is done
  DateTime? _backgroundedAt; // Track when app went to background
  static const int _lockAfterSeconds = 30; // Only lock after 30 seconds in background
  String? _verificationEmail;
  Widget? _homeScreen; // Will be either FamilySelectionScreen, OwnerHome, or MemberHome
  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  final _biometricService = BiometricService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<String>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeConnectivity();
    _initializeSessionListener();
    _initializeApp();
  }

  void _initializeSessionListener() {
    _sessionExpiredSubscription = SessionManager().onSessionExpired.listen((reason) {
      if (mounted && !SessionManager().isHandlingExpiration) {
        _showSessionExpiredDialog(reason);
      }
    });
  }

  Future<void> _showSessionExpiredDialog(String reason) async {
    SessionManager().markHandling();
    bool hasLoggedOut = false;
    Timer? autoLogoutTimer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        autoLogoutTimer = Timer(const Duration(seconds: 3), () {
          if (!hasLoggedOut && Navigator.of(dialogContext).canPop()) {
            hasLoggedOut = true;
            Navigator.of(dialogContext).pop();
            _performSessionLogout();
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
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phonelink_erase_rounded, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(dialogContext)?.sessionExpiredTitle ?? 'Session Expired',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(dialogContext)?.sessionExpiredMessage ?? 'Another device has logged into your account. You will be signed out for security.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!hasLoggedOut) {
                        hasLoggedOut = true;
                        autoLogoutTimer?.cancel();
                        Navigator.of(dialogContext).pop();
                        _performSessionLogout();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      AppLocalizations.of(dialogContext)?.ok ?? 'OK',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performSessionLogout() async {
    SessionManager().disconnectSocket();
    await _tokenStorage.clearAll();
    await _biometricService.clearSecurityCache();
    await ActivityService().clearCache();
    await Supabase.instance.client.auth.signOut();
    SessionManager().resetHandlingFlag();
    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _needsVerification = false;
        _needsSecurityUnlock = false;
        _isProcessingOAuth = false;
      });
    }
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    // Check initial connectivity status
    final results = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(results);
    
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  /// Update connectivity status
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final isOffline = results.isEmpty || 
        results.every((result) => result == ConnectivityResult.none);
    
    if (mounted && _isOffline != isOffline) {
      debugPrint('📶 Connectivity changed: ${isOffline ? "OFFLINE" : "ONLINE"}');
      setState(() {
        _isOffline = isOffline;
      });
    }
  }

  /// Initialize app by checking saved state
  Future<void> _initializeApp() async {
    debugPrint('🚀 Starting app initialization...');
    await _loadPendingVerification();
    await _checkSavedTokens();
    _checkAuthState();
    
    // Mark initialization as complete
    if (mounted) {
      setState(() {
        _initializationComplete = true;
      });
    }
    debugPrint('🚀 App initialization complete: isAuth=$_isAuthenticated, needsUnlock=$_needsSecurityUnlock');
  }

  /// Check for saved JWT tokens on app startup
  Future<void> _checkSavedTokens() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      
      if (accessToken != null) {
        debugPrint('🔑 Found saved access token, restoring session');
        
        // Check if security is enabled and app needs unlock
        await _checkSecurityStatus();
        
        // Determine home screen based on family status
        final homeScreen = await _determineHomeScreen();
        
        debugPrint('🏠 Determined home screen: ${homeScreen.runtimeType}');
        
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _homeScreen = homeScreen;
          });
        }
      } else {
        debugPrint('🔑 No saved tokens found');
      }
    } catch (e) {
      debugPrint('❌ Error checking saved tokens: $e');
      // Clear invalid tokens
      await _tokenStorage.clearTokens();
    }
  }

  /// Check if security is enabled and app needs unlock
  Future<void> _checkSecurityStatus() async {
    if (_isCheckingSecurityStatus) return;
    _isCheckingSecurityStatus = true;

    try {
      // First check local cache for quick response
      var isSecurityEnabled = await _biometricService.isSecurityEnabledLocally();
      
      // Only fetch from API if cache has NEVER been set (first time user)
      // This avoids unnecessary API calls on every app open
      final hasCacheBeenSet = await _biometricService.hasSecurityCacheBeenSet();
      if (!hasCacheBeenSet) {
        debugPrint('🔐 Security cache never set, fetching from API...');
        final settings = await _biometricService.getSecuritySettings();
        if (settings != null) {
          isSecurityEnabled = settings.isSecurityEnabled;
          debugPrint('🔐 API security status: $isSecurityEnabled');
        }
      }
      
      if (isSecurityEnabled) {
        debugPrint('🔐 Security enabled - showing unlock screen');
        if (mounted) {
          setState(() {
            _needsSecurityUnlock = true;
          });
        }
      } else {
        debugPrint('🔓 Security not enabled - no unlock needed');
      }
    } catch (e) {
      debugPrint('❌ Error checking security status: $e');
      // On error, don't lock the user out
    } finally {
      _isCheckingSecurityStatus = false;
    }
  }

  /// Called when user successfully unlocks the app
  void _onAppUnlocked() {
    debugPrint('🔓 App unlocked successfully');
    if (mounted) {
      setState(() {
        _needsSecurityUnlock = false;
      });
    }
  }

  /// Called when user logs out from unlock screen
  Future<void> _onLogoutFromUnlock() async {
    await _handleAuthFailure();
  }

  /// Load pending verification email from local storage
  Future<void> _loadPendingVerification() async {
    final email = await PendingVerificationHelper.get();
    if (email != null && mounted) {
      debugPrint('📧 Found pending verification for: $email');
      setState(() {
        _needsVerification = true;
        _verificationEmail = email;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_isAuthenticated) {
        _ensureSocketConnected();
      }
      if (_isAuthenticated && !_needsSecurityUnlock && !_showSplash) {
        final wasInBackgroundLongEnough = _backgroundedAt != null &&
            DateTime.now().difference(_backgroundedAt!).inSeconds >= _lockAfterSeconds;
        if (wasInBackgroundLongEnough) {
          _checkSecurityOnResume();
        }
      }
      _backgroundedAt = null;
    }
  }

  Future<void> _ensureSocketConnected() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      SessionManager().initializeSocket(accessToken);
    }
  }

  /// Check if security lock should be shown when app resumes from background
  Future<void> _checkSecurityOnResume() async {
    try {
      // Use local cache check instead of API call for better performance
      final isSecurityEnabled = await _biometricService.isSecurityEnabledLocally();
      
      if (isSecurityEnabled) {
        debugPrint('🔐 App resumed with security enabled - showing unlock');
        if (mounted) {
          setState(() {
            _needsSecurityUnlock = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking security on resume: $e');
    }
  }

  void _checkAuthState() {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;
      
      debugPrint('🔔 Auth event: $event, session: ${session != null}');
      
      if (session != null && event == AuthChangeEvent.signedIn) {
        // Only call backend on actual NEW sign-in (OAuth callback)
        // Skip for tokenRefreshed and initialSession - these don't need backend call
        await _handleNewSession(session, isNewSignIn: true);
      } else if (session != null && event == AuthChangeEvent.initialSession) {
        // App restart with existing session - check if we have backend tokens
        await _handleInitialSession(session);
      } else if (session == null && event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _needsVerification = false;
            _verificationEmail = null;
          });
        }
      }
      // Ignore tokenRefreshed - Supabase handles this automatically
    });

    // Check initial session
    _checkInitialSession();
  }

  bool _isHandlingSession = false;

  Future<void> _checkInitialSession() async {
    if (_isHandlingSession) return; // Prevent duplicate handling
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && !_isAuthenticated && !_needsVerification) {
      await _handleInitialSession(session);
    }
  }

  /// Handle app restart with existing Supabase session
  /// Only calls backend if we don't have valid backend tokens
  Future<void> _handleInitialSession(Session session) async {
    if (_isHandlingSession) return;
    _isHandlingSession = true;
    
    try {
      // Check if we already have valid backend tokens
      final accessToken = await _tokenStorage.getAccessToken();
      
      if (accessToken != null) {
        // We already have backend tokens - just restore session without calling backend
        debugPrint('🔑 Already have backend tokens, skipping backend call');
        
        // Initialize WebSocket for real-time session monitoring
        SessionManager().initializeSocket(accessToken);
        
        // Only determine home screen if we don't already have one
        if (_homeScreen == null) {
          final homeScreen = await _determineHomeScreen();
          if (mounted) {
            setState(() {
              _isAuthenticated = true;
              _needsVerification = false;
              _homeScreen = homeScreen;
            });
          }
        } else {
          // Already have a home screen, just mark as authenticated
          if (mounted && !_isAuthenticated) {
            setState(() {
              _isAuthenticated = true;
              _needsVerification = false;
            });
          }
        }
      } else {
        // No backend tokens - need to call backend (first time linking Supabase session)
        debugPrint('🔑 No backend tokens, calling backend');
        await _handleNewSession(session, isNewSignIn: true);
      }
    } catch (e) {
      debugPrint('❌ Error in _handleInitialSession: $e');
    } finally {
      _isHandlingSession = false;
    }
  }

  /// Handle actual new sign-in (OAuth callback)
  Future<void> _handleNewSession(Session session, {required bool isNewSignIn}) async {
    if (_isHandlingSession && !isNewSignIn) return;
    if (!isNewSignIn) _isHandlingSession = true;
    
    // Show loading while processing OAuth
    if (mounted) {
      setState(() {
        _isProcessingOAuth = true;
      });
    }
    
    final user = session.user;
    
    try {
      debugPrint('🔐 Handling new session for user: ${user.email}');
      
      // Check with backend if user needs verification
      final response = await _authApiService.supabaseLogin(
        SupabaseLoginRequest(
          supabaseId: user.id,
          email: user.email!,
          fullName: user.userMetadata?['full_name'],
          phone: user.phone,
        ),
      );
      
      debugPrint('✅ Backend response: requiresVerification=${response.requiresVerification}, isSuccess=${response.isSuccess}');
      
      if (response.requiresVerification) {
        debugPrint('📱 Navigating to VerifyEmailScreen for ${response.email}');
        
        // Save pending verification to local storage for app restart (with 5 min expiry)
        await PendingVerificationHelper.save(response.email!);
        
        // Update state
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _needsVerification = true;
            _verificationEmail = response.email;
          });
        }
        
        // Only navigate programmatically if splash is already done
        // Otherwise, the build method will show the correct screen after splash
        if (!_showSplash) {
          final navigator = navigatorKey.currentState;
          debugPrint('📱 navigatorKey.currentState: $navigator');
          if (navigator != null) {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => VerifyEmailScreen(email: response.email!),
              ),
              (route) => false,
            );
            debugPrint('📱 Navigation command executed');
          } else {
            debugPrint('❌ Navigator is null - cannot navigate');
          }
        } else {
          debugPrint('📱 Splash still showing - will navigate after splash finishes');
        }
      } else if (response.isSuccess) {
        // Clear any pending verification since user is now fully verified
        await PendingVerificationHelper.clear();
        
        // Save backend tokens
        await _tokenStorage.saveTokens(
          accessToken: response.accessToken!,
          sessionToken: response.sessionToken!,
        );
        
        // Initialize WebSocket for real-time session monitoring
        SessionManager().initializeSocket(response.accessToken!);
        
        // Save user profile data for display name
        // Backend returns firstName/lastName from database if they exist
        // Otherwise it returns fullName from Google OAuth
        await _tokenStorage.saveUserProfile(
          firstName: response.user?.firstName,
          lastName: response.user?.lastName,
          fullName: response.user?.fullName,
          email: response.user?.email ?? user.email,
        );
        
        final settings = await _biometricService.getSecuritySettings();
        final isSecurityEnabled = settings?.isSecurityEnabled ?? false;
        
        final homeScreen = await _determineHomeScreen();
        
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _needsVerification = false;
            _verificationEmail = null;
            _needsSecurityUnlock = isSecurityEnabled;
            _homeScreen = homeScreen;
          });
        }
        
        if (!_showSplash) {
          final navigator = navigatorKey.currentState;
          if (navigator != null) {
            if (isSecurityEnabled) {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => AppUnlockScreen(
                    onUnlocked: () {
                      _onAppUnlocked();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => homeScreen),
                        (route) => false,
                      );
                    },
                    onLogout: _onLogoutFromUnlock,
                  ),
                ),
                (route) => false,
              );
            } else {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => homeScreen),
                (route) => false,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Backend call failed: $e');
      // Sign out from Supabase to allow retry
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _needsVerification = false;
          _isProcessingOAuth = false;
        });
        
        // Show error message to user
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
            SnackBar(
              content: const Text('Sign in failed. Please try again.'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } finally {
      _isHandlingSession = false;
      if (mounted) {
        setState(() {
          _isProcessingOAuth = false;
        });
      }
    }
  }

  Future<Widget> _determineHomeScreen() async {
    try {
      debugPrint('🔍 Checking family status...');
      final family = await _familyApiService.getMyFamily();
      
      debugPrint('👨‍👩‍👧‍👦 Family data: ${family != null ? "Found (isOwner: ${family.isOwner})" : "None"}');
      
      if (family != null) {
        // Cache the family data so home screen doesn't need to fetch again
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
        
        // User has a family
        if (family.isOwner == true) {
          debugPrint('✅ Navigating to Owner home');
          return const FamilyOwnerHomeScreen();
        } else {
          debugPrint('✅ Navigating to Member home');
          return const FamilyMemberHomeScreen();
        }
      }
      
      debugPrint('ℹ️ No family found, showing selection screen');
    } on AuthenticationException catch (e) {
      // Authentication failed - user needs to re-login
      debugPrint('🚫 Authentication failed: $e - logging out user');
      await _handleAuthFailure();
      return const OnboardingScreen(); // Will show login screen
    } catch (e) {
      debugPrint('❌ Failed to check family status: $e');
      // Check if error message indicates auth failure
      if (e.toString().contains('Session expired') || 
          e.toString().contains('Session invalidated') ||
          e.toString().contains('sign in again')) {
        debugPrint('🚫 Session error detected - logging out user');
        await _handleAuthFailure();
        return const OnboardingScreen();
      }
    }
    
    // Default: show family selection if no family or error
    return const FamilySelectionScreen();
  }

  /// Handle authentication failure - clear tokens and reset state
  Future<void> _handleAuthFailure() async {
    debugPrint('🔒 Handling auth failure - clearing tokens');
    
    // Disconnect WebSocket
    SessionManager().disconnectSocket();
    
    await _tokenStorage.clearAll();
    await ActivityService().clearCache();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _needsVerification = false;
        _isProcessingOAuth = false;
      });
    }
  }

  void _onSplashFinished() {
    // Only hide splash if initialization is complete
    // If not complete yet, we'll wait for it
    if (_initializationComplete) {
      debugPrint('✅ Splash finished, initialization already complete');
      setState(() {
        _showSplash = false;
      });
    } else {
      debugPrint('⏳ Splash finished but waiting for initialization...');
      // Wait for initialization to complete, then hide splash
      _waitForInitialization();
    }
  }

  /// Wait for initialization to complete before hiding splash
  Future<void> _waitForInitialization() async {
    // Poll until initialization is complete (max 5 seconds)
    int attempts = 0;
    while (!_initializationComplete && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    if (mounted) {
      debugPrint('✅ Initialization complete after ${attempts * 100}ms, hiding splash');
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ Building AppEntry: splash=$_showSplash, needsVerification=$_needsVerification, email=$_verificationEmail, isAuth=$_isAuthenticated, processing=$_isProcessingOAuth, needsUnlock=$_needsSecurityUnlock, offline=$_isOffline');
    
    if (_showSplash) {
      return SplashScreen(onFinished: _onSplashFinished);
    }
    
    // Determine which screen to show
    Widget currentScreen;
    
    // Check for offline status - show offline screen if no internet
    if (_isOffline) {
      debugPrint('📶 Showing OfflineScreen');
      currentScreen = const OfflineScreen();
    } else if (_isProcessingOAuth) {
      // Show loading screen while processing OAuth callback
      currentScreen = const _OAuthLoadingScreen();
    } else if (_needsVerification && _verificationEmail != null) {
      // If user needs verification, show verify screen
      debugPrint('🏗️ Showing VerifyEmailScreen for $_verificationEmail');
      currentScreen = VerifyEmailScreen(email: _verificationEmail!);
    } else if (_isAuthenticated) {
      // AuthGate: Check if user is authenticated
      if (_needsSecurityUnlock) {
        debugPrint('🏗️ Showing AppUnlockScreen');
        currentScreen = AppUnlockScreen(
          onUnlocked: _onAppUnlocked,
          onLogout: _onLogoutFromUnlock,
        );
      } else {
        currentScreen = _homeScreen ?? const FamilySelectionScreen();
      }
    } else {
      // Always show onboarding after splash
      currentScreen = const OnboardingScreen();
    }
    
    // Wrap in AnimatedSwitcher for smooth transitions (especially offline -> online)
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(currentScreen.runtimeType.toString() + (_isOffline ? '_offline' : '')),
        child: currentScreen,
      ),
    );
  }
}

/// Loading screen shown during OAuth callback processing
class _OAuthLoadingScreen extends StatelessWidget {
  const _OAuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/horisental.png',
              width: 200,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFFE5383B),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)?.signingYouIn ?? 'Signing you in...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
