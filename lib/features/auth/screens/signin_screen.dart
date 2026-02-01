import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:cha9cha9ni/main.dart' show PendingVerificationHelper;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/services/api_exception.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/services/family_api_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../family/family_selection_screen.dart';
import '../../home/family_owner_home_screen.dart';
import '../../home/family_member_home_screen.dart';
import '../../settings/screens/app_unlock_screen.dart';
import '../widgets/custom_text_field.dart';
import '../models/auth_request_models.dart';
import '../services/auth_api_service.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';
import 'forgot_password_verify_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with WidgetsBindingObserver {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  final _biometricService = BiometricService();

  bool _obscurePassword = true;
  bool _showErrors = false;
  bool _isLoading = false;
  bool _isSendingResetCode = false;
  bool _isAwaitingOAuth = false; // Track if we're waiting for OAuth callback

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAwaitingOAuth) {
      // App resumed after OAuth - check if user cancelled
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isAwaitingOAuth && mounted) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) {
            // No session = user cancelled
            setState(() {
              _isAwaitingOAuth = false;
              _isLoading = false;
            });
            _showCancelledDialog();
          }
        }
      });
    }
  }

  void _showCancelledDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
              const SizedBox(height: 24),
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                l10n.googleSignInCancelled,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                l10n.googleSignInCancelledMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.close,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleGoogleSignIn();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.tryAgain,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
  }

  Future<void> _navigateBasedOnFamilyStatus() async {
    try {
      final settings = await _biometricService.getSecuritySettings();
      final isSecurityEnabled = settings?.isSecurityEnabled ?? false;
      
      if (isSecurityEnabled) {
        if (!mounted) return;
        
        // Get family info first to know where to go after unlock
        final family = await _familyApiService.getMyFamily();
        Widget destinationScreen;
        
        if (family != null) {
          destinationScreen = family.isOwner == true 
              ? const FamilyOwnerHomeScreen() 
              : const FamilyMemberHomeScreen();
        } else {
          destinationScreen = const FamilySelectionScreen();
        }
        
        // Show unlock screen with callback to navigate after unlock
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => AppUnlockScreen(
              onUnlocked: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => destinationScreen),
                  (route) => false,
                );
              },
            ),
          ),
          (route) => false,
        );
        return;
      }
      
      // No security enabled - navigate directly to home
      final family = await _familyApiService.getMyFamily();
      
      if (!mounted) return;
      
      if (family != null) {
        // User has a family, navigate to appropriate home screen
        if (family.isOwner == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const FamilyOwnerHomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const FamilyMemberHomeScreen()),
            (route) => false,
          );
        }
      } else {
        // User doesn't have a family, show family selection
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const FamilySelectionScreen()),
        );
      }
    } catch (e) {
      // If error checking family, default to family selection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const FamilySelectionScreen()),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    // Validate email is entered
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.pleaseEnterEmail,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.invalidEmailFormat,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSendingResetCode = true;
    });

    try {
      // Request password reset code
      await _authApiService.requestPasswordReset(email);

      if (mounted) {
        // Navigate to verification screen
        final isRTL = Directionality.of(context) == TextDirection.rtl;
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ForgotPasswordVerifyScreen(email: email),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final begin = Offset(isRTL ? -1.0 : 1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              final tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              final offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = AppLocalizations.of(context)!.anErrorOccurred;

        if (e is ApiException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingResetCode = false;
        });
      }
    }
  }

  Future<void> _handleEmailSignIn() async {
    setState(() {
      _showErrors = true;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend API to login
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final response = await _authApiService.login(request);

      if (mounted) {
        if (response.requiresVerification) {
          // Save pending verification to local storage for app restart
          await PendingVerificationHelper.save(response.email!);
          
          // Navigate to verification screen with slide animation
          final isRTL = Directionality.of(context) == TextDirection.rtl;
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => VerifyEmailScreen(
                email: response.email!,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final begin = Offset(isRTL ? -1.0 : 1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                final offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
        } else if (response.isSuccess) {
          // Track login success
          AnalyticsService().trackLogin(method: 'email');
          
          // Store tokens
          await _tokenStorage.saveTokens(
            accessToken: response.accessToken!,
            sessionToken: response.sessionToken!,
            expiresIn: response.expiresIn,
            userId: response.user?.id,
          );
          
          // Save user profile for display name
          await _tokenStorage.saveUserProfile(
            firstName: response.user?.firstName,
            lastName: response.user?.lastName,
            fullName: response.user?.fullName,
            email: response.user?.email,
          );

          // Check if user has a family
          await _navigateBasedOnFamilyStatus();
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.signInFailed ?? 'Sign in failed'}: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _isAwaitingOAuth = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'cha9cha9ni://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // After OAuth, user will be redirected back to app
      // AppEntry in main.dart will handle the callback and verification
    } on AuthException catch (e) {
      setState(() {
        _isAwaitingOAuth = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAwaitingOAuth = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.googleSignInFailed ?? 'Google sign in failed'}: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted && !_isAwaitingOAuth) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    _authApiService.dispose();
    super.dispose();
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
          child: Stack(
            children: [
              Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 44),
                      Image.asset(
                        'assets/icons/horisental.png',
                        width: MediaQuery.of(context).size.width * 0.50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.welcomeBack,
                            style: AppTextStyles.heading1,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.dontHaveAccount,
                                style: AppTextStyles.body.copyWith(
                                  color: const Color(0xFF13123A),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          const SignUpScreen(),
                                      transitionsBuilder:
                                          (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(-1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOutCubic;
                                        var tween = Tween(begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        var offsetAnimation = animation.drive(tween);
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 400),
                                    ),
                                  );
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.signUp,
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Column(
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            hintText: AppLocalizations.of(context)!.enterEmail,
                            prefixIcon: Icons.email_outlined,
                            hasError: _showErrors && _emailController.text.isEmpty,
                            onChanged: (value) {
                              if (_showErrors) {
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            hintText: AppLocalizations.of(context)!.enterPassword,
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFFC7C7D1),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            hasError: _showErrors && _passwordController.text.isEmpty,
                            onChanged: (value) {
                              if (_showErrors) {
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _isSendingResetCode ? null : _handleForgotPassword,
                              child: _isSendingResetCode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF4CC3C7),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.forgotPassword,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : _handleEmailSignIn,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: ShapeDecoration(
                            gradient: _isLoading ? null : AppColors.primaryGradient,
                            color: _isLoading ? Colors.grey : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    AppLocalizations.of(context)!.signIn,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFFE0E0E6)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppLocalizations.of(context)!.orSignInWith,
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFFB4B4C1),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFFE0E0E6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isLoading ? null : _handleGoogleSignIn,
                      child: Container(
                        height: 52,
                        decoration: ShapeDecoration(
                          color: _isLoading ? Colors.grey.shade300 : Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 1,
                              color: Color(0xFFE0E0E6),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/google.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.signInWithGoogle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF13123A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!
                                .termsAgreement(AppLocalizations.of(context)!.signIn),
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF7A7A90),
                            ),
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.termOfUse,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.secondary.withValues(alpha: 0.7),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(
                                Uri.parse('https://www.cha9cha9ni.tn/terms'),
                                mode: LaunchMode.externalApplication,
                              ),
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.and,
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF7A7A90),
                            ),
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.privacyPolicy,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.secondary.withValues(alpha: 0.7),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(
                                Uri.parse('https://www.cha9cha9ni.tn/privacy'),
                                mode: LaunchMode.externalApplication,
                              ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
              Positioned(
                top: 16,
                left: Directionality.of(context) == TextDirection.rtl ? null : 16,
                right: Directionality.of(context) == TextDirection.rtl ? 16 : null,
                child: const LanguageSelector(),
              ),
        ],
      ),
    ),
      ),
    );
  }
}
