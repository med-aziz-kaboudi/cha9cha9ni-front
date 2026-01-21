import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _biometricService = BiometricService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Password requirements
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
    _newPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasNumber = RegExp(r'\d').hasMatch(password);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasNumber && _hasUppercase && _hasSpecialChar;

  Future<void> _handleChangePassword() async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      AppToast.error(
        context,
        l10n?.currentPasswordRequired ?? 'Current password is required',
      );
      return;
    }

    if (!_isPasswordValid) {
      AppToast.error(
        context,
        l10n?.passwordDoesNotMeetRequirements ??
            'Password does not meet requirements',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppToast.error(
        context,
        l10n?.passwordsDoNotMatch ?? 'Passwords do not match',
      );
      return;
    }

    if (currentPassword == newPassword) {
      AppToast.error(
        context,
        l10n?.newPasswordMustBeDifferent ?? 'New password must be different',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _biometricService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        HapticFeedback.heavyImpact();
        AppToast.success(
          context,
          l10n?.passwordChangedSuccess ?? 'Password changed successfully',
        );
        Navigator.pop(context);
      } else {
        HapticFeedback.vibrate();
        AppToast.error(
          context,
          result.error ??
              (l10n?.failedToChangePassword ?? 'Failed to change password'),
        );
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (delay * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 16, color: AppColors.dark),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 2,
              ),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[500],
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(bool met, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: met ? AppColors.secondary : Colors.transparent,
              border: Border.all(
                color: met ? AppColors.secondary : Colors.grey[400]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: met
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: met ? AppColors.secondary : Colors.grey[600],
              fontWeight: met ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isRTL = locale.languageCode == 'ar';

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
          child: Column(
            children: [
              // Header bar - matching other settings screens
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF683BFC).withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isRTL
                              ? Icons.arrow_forward_ios
                              : Icons.arrow_back_ios_new,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Text(
                        l10n?.changePassword ?? 'Change Password',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtitle
                          Text(
                            l10n?.changePasswordDialogDesc ??
                                'Enter your current password and choose a new one',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Current Password
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            label: l10n?.currentPassword ?? 'Current Password',
                            obscure: _obscureCurrentPassword,
                            onToggle: () => setState(
                              () => _obscureCurrentPassword =
                                  !_obscureCurrentPassword,
                            ),
                            delay: 0,
                          ),
                          const SizedBox(height: 16),

                          // New Password
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: l10n?.newPassword ?? 'New Password',
                            obscure: _obscureNewPassword,
                            onToggle: () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            ),
                            delay: 1,
                          ),
                          const SizedBox(height: 16),

                          // Password Requirements Card
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isPasswordValid
                                    ? AppColors.secondary.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isPasswordValid
                                      ? AppColors.secondary.withOpacity(0.3)
                                      : Colors.transparent,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _isPasswordValid
                                              ? AppColors.secondary.withOpacity(
                                                  0.2,
                                                )
                                              : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          _isPasswordValid
                                              ? Icons.verified
                                              : Icons.info_outline,
                                          color: _isPasswordValid
                                              ? AppColors.secondary
                                              : Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isPasswordValid
                                            ? (l10n?.passwordStrong ??
                                                  'Strong password!')
                                            : (l10n?.passwordRequirements ??
                                                  'Password requirements'),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _isPasswordValid
                                              ? AppColors.secondary
                                              : AppColors.dark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRequirementRow(
                                    _hasMinLength,
                                    l10n?.passwordRequirement1 ??
                                        'At least 8 characters',
                                  ),
                                  _buildRequirementRow(
                                    _hasNumber,
                                    l10n?.passwordRequirement2 ??
                                        'Contains a number',
                                  ),
                                  _buildRequirementRow(
                                    _hasUppercase,
                                    l10n?.passwordRequirement3 ??
                                        'Contains an uppercase letter',
                                  ),
                                  _buildRequirementRow(
                                    _hasSpecialChar,
                                    l10n?.passwordRequirement4 ??
                                        'Contains a special character',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: l10n?.confirmPassword ?? 'Confirm Password',
                            obscure: _obscureConfirmPassword,
                            onToggle: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            delay: 2,
                          ),

                          const SizedBox(height: 32),

                          // Submit Button - matching app design
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleChangePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  disabledBackgroundColor: AppColors.primary
                                      .withOpacity(0.5),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        l10n?.changePassword ??
                                            'Change Password',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
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
}
