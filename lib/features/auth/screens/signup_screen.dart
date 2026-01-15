import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/services/api_exception.dart';
import '../widgets/custom_text_field.dart';
import '../models/auth_request_models.dart';
import '../services/auth_api_service.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _authApiService = AuthApiService();

  bool _obscurePassword = true;
  bool _showErrors = false;
  bool _isLoading = false;

  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _hasUpperCase = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _authApiService.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignUp() async {
    setState(() {
      _showErrors = true;
    });

    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.length != 8 ||
        !_isPasswordValid()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend API to register
      final request = RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: '+216${_phoneController.text}',
      );

      final response = await _authApiService.register(request);

      if (mounted) {
        // Show success message from backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.secondary,
          ),
        );
        
        // Navigate to sign-in screen (NOT verification)
        // User needs to login first, then they'll receive verification email
        final isRTL = Directionality.of(context) == TextDirection.rtl;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SignInScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final begin = Offset(isRTL ? 1.0 : -1.0, 0.0); // Slide from left (back direction)
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              final offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
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
            content: Text('Sign up failed: ${e.toString()}'),
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

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
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
            content: Text('Google sign up failed: ${e.toString()}'),
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

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    });
  }

  bool _isPasswordValid() {
    return _hasMinLength && _hasNumber && _hasSymbol && _hasUpperCase;
  }

  Color _getPasswordStrengthColor() {
    if (_hasMinLength && _hasNumber && _hasUpperCase && _hasSymbol) {
      return AppColors.secondary;
    } else if (_hasMinLength && _hasNumber && _hasUpperCase) {
      return const Color(0xFFFF9800);
    } else {
      return AppColors.primary;
    }
  }

  double _getPasswordStrength() {
    if (_hasMinLength && _hasNumber && _hasUpperCase && _hasSymbol) {
      return 1.0;
    } else if (_hasMinLength && _hasNumber && _hasUpperCase) {
      return 0.66;
    } else if (_passwordController.text.isNotEmpty) {
      return 0.33;
    }
    return 0.0;
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
                            AppLocalizations.of(context)!.createNewAccount,
                            style: AppTextStyles.heading1,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.alreadyHaveAccount,
                                style: AppTextStyles.body.copyWith(
                                  color: const Color(0xFF13123A),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const SignInScreen(),
                                        transitionsBuilder:
                                            (context, animation, secondaryAnimation, child) {
                                          const begin = Offset(1.0, 0.0);
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
                                  }
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.signIn,
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
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _firstNameController,
                                  hintText: AppLocalizations.of(context)!.firstName,
                                  prefixIcon: Icons.person_outline,
                                  hasError: _showErrors && _firstNameController.text.isEmpty,
                                  onChanged: (value) {
                                    if (_showErrors) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  controller: _lastNameController,
                                  hintText: AppLocalizations.of(context)!.lastName,
                                  prefixIcon: Icons.person_outline,
                                  hasError: _showErrors && _lastNameController.text.isEmpty,
                                  onChanged: (value) {
                                    if (_showErrors) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          Container(
                            height: 48,
                            decoration: ShapeDecoration(
                              color: AppColors.gray,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: _showErrors && _phoneController.text.length != 8
                                      ? AppColors.primary
                                      : const Color(0xFFBDBDC3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Text('🇹🇳', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  '+216',
                                  style: AppTextStyles.body.copyWith(
                                    color: const Color(0xFF13123A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: const Color(0xFFBDBDC3),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 8,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (value) {
                                      if (_showErrors) {
                                        setState(() {});
                                      }
                                    },
                                    style: AppTextStyles.body.copyWith(
                                      color: const Color(0xFF13123A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.phoneNumber,
                                      hintStyle: AppTextStyles.body.copyWith(
                                        color: const Color(0xFFA0A0AC),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      counterText: '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                            hasError: _showErrors && (_passwordController.text.isEmpty || !_isPasswordValid()),
                            onChanged: (value) {
                              if (_showErrors) {
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 350),
                            firstCurve: Curves.easeOutCubic,
                            secondCurve: Curves.easeInCubic,
                            sizeCurve: Curves.easeInOutCubic,
                            crossFadeState: _passwordController.text.isNotEmpty
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: _getPasswordStrength(),
                                    backgroundColor: const Color(0xFFE0E0E6),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getPasswordStrengthColor(),
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordRequirement(
                                  AppLocalizations.of(context)!.passwordRequirement1,
                                  _hasMinLength,
                                ),
                                const SizedBox(height: 8),
                                _buildPasswordRequirement(
                                  AppLocalizations.of(context)!.passwordRequirement2,
                                  _hasNumber,
                                ),
                                const SizedBox(height: 8),
                                _buildPasswordRequirement(
                                  AppLocalizations.of(context)!.passwordRequirement3,
                                  _hasUpperCase,
                                ),
                                const SizedBox(height: 8),
                                _buildPasswordRequirement(
                                  AppLocalizations.of(context)!.passwordRequirement4,
                                  _hasSymbol,
                                ),
                              ],
                            ),
                            secondChild: const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : _handleEmailSignUp,
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
                                    AppLocalizations.of(context)!.signUp,
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
                            AppLocalizations.of(context)!.orSignUpWith,
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
                      onTap: _isLoading ? null : _handleGoogleSignUp,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: ShapeDecoration(
                          color: _isLoading ? Colors.grey.shade300 : Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 1,
                              color: Color(0xFFB4B4C1),
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
                              AppLocalizations.of(context)!.signUpWithGoogle,
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
                                .termsAgreement(AppLocalizations.of(context)!.signUp),
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF7A7A90),
                            ),
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.termOfUse,
                            style: AppTextStyles.bodyBold,
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.and,
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF7A7A90),
                            ),
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.privacyPolicy,
                            style: AppTextStyles.bodyBold,
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

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? AppColors.secondary : const Color(0xFFB4B4C1),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: isMet ? AppColors.secondary : const Color(0xFF13123A),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
