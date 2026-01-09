import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/language_selector.dart';
import '../widgets/custom_text_field.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _showErrors = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                              onTap: () {
                                // TODO: Navigate to forgot password
                              },
                              child: Text(
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
                        onTap: () {
                          setState(() {
                            _showErrors = true;
                          });
                          if (_emailController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty) {
                            // TODO: Proceed with sign in
                          }
                        },
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
                      onTap: () {
                        // TODO: Sign in with Google
                      },
                      child: Container(
                        height: 52,
                        decoration: ShapeDecoration(
                          color: Colors.white,
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
}
