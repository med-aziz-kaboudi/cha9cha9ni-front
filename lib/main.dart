import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/family/family_selection_screen.dart';
import 'features/home/family_owner_home_screen.dart';
import 'features/home/family_member_home_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/auth/services/auth_api_service.dart';
import 'features/auth/models/auth_request_models.dart';
import 'core/services/language_service.dart';
import 'core/services/token_storage_service.dart';
import 'core/services/family_api_service.dart' show FamilyApiService, AuthenticationException;

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
  String? _verificationEmail;
  Widget? _homeScreen; // Will be either FamilySelectionScreen, OwnerHome, or MemberHome
  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  /// Initialize app by checking saved state
  Future<void> _initializeApp() async {
    await _loadPendingVerification();
    await _checkSavedTokens();
    _checkAuthState();
  }

  /// Check for saved JWT tokens on app startup
  Future<void> _checkSavedTokens() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      
      if (accessToken != null) {
        debugPrint('🔑 Found saved access token, restoring session');
        
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back from background (e.g., after OAuth in browser)
      debugPrint('📱 App resumed - checking session');
      _checkInitialSession();
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
        
        // Determine home screen based on family status
        final homeScreen = await _determineHomeScreen();
        
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _needsVerification = false;
            _homeScreen = homeScreen;
          });
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
        
        // Save user profile data for display name
        // Backend returns firstName/lastName from database if they exist
        // Otherwise it returns fullName from Google OAuth
        await _tokenStorage.saveUserProfile(
          firstName: response.user?.firstName,
          lastName: response.user?.lastName,
          fullName: response.user?.fullName,
          email: response.user?.email ?? user.email,
        );
        
        // Check family status and determine which screen to show
        final homeScreen = await _determineHomeScreen();
        
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _needsVerification = false;
            _verificationEmail = null;
            _homeScreen = homeScreen;
          });
        }
        
        // Only navigate programmatically if splash is already done
        if (!_showSplash) {
          final navigator = navigatorKey.currentState;
          if (navigator != null) {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => homeScreen),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Backend call failed: $e');
      // Don't sign out - just let user stay on current screen
      // They can try again or use email/password login
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _needsVerification = false;
          _isProcessingOAuth = false;
        });
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
    await _tokenStorage.clearAll();
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
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ Building AppEntry: splash=$_showSplash, needsVerification=$_needsVerification, email=$_verificationEmail, isAuth=$_isAuthenticated, processing=$_isProcessingOAuth');
    
    if (_showSplash) {
      return SplashScreen(onFinished: _onSplashFinished);
    }
    
    // Show loading screen while processing OAuth callback
    if (_isProcessingOAuth) {
      return const _OAuthLoadingScreen();
    }
    
    // If user needs verification, show verify screen
    if (_needsVerification && _verificationEmail != null) {
      debugPrint('🏗️ Showing VerifyEmailScreen for $_verificationEmail');
      return VerifyEmailScreen(email: _verificationEmail!);
    }
    
    // AuthGate: Check if user is authenticated
    if (_isAuthenticated) {
      return _homeScreen ?? const FamilySelectionScreen();
    }
    
    // Always show onboarding after splash
    return const OnboardingScreen();
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
              'Signing you in...',
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
