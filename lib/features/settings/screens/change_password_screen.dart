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
  bool _isLoadingSettings = true;
  bool _hasPassword = true; // Default to true, will be updated from settings
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
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final settings = await _biometricService.getSecuritySettings();
      if (mounted) {
        setState(() {
          _hasPassword = settings?.hasPassword ?? true;
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
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

    // Only validate current password if user has one
    if (_hasPassword && currentPassword.isEmpty) {
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

    // Only check if different from current when changing (not creating)
    if (_hasPassword && currentPassword == newPassword) {
      AppToast.error(
        context,
        l10n?.newPasswordMustBeDifferent ?? 'New password must be different',
      );
      return;
    }

    setState(() => _isLoading = true);

    final ({bool success, String? error}) result;
    
    if (_hasPassword) {
      // Change existing password
      result = await _biometricService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } else {
      // Create new password for OAuth users
      result = await _biometricService.createPassword(
        newPassword: newPassword,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        HapticFeedback.heavyImpact();
        AppToast.success(
          context,
          _hasPassword 
              ? (l10n?.passwordChangedSuccess ?? 'Password changed successfully')
              : (l10n?.passwordCreatedSuccess ?? 'Password created successfully'),
        );
        Navigator.pop(context);
      } else {
        HapticFeedback.vibrate();
        AppToast.error(
          context,
          result.error ??
              (_hasPassword 
                  ? (l10n?.failedToChangePassword ?? 'Failed to change password')
                  : (l10n?.failedToCreatePassword ?? 'Failed to create password')),
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
              color: Colors.black.withValues(alpha: 0.05),
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
                color: AppColors.secondary.withValues(alpha: 0.1),
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

    // Determine title and subtitle based on whether user has password
    final title = _hasPassword 
        ? (l10n?.changePassword ?? 'Change Password')
        : (l10n?.createPassword ?? 'Create Password');
    final subtitle = _hasPassword
        ? (l10n?.changePasswordDialogDesc ?? 'Enter your current password and choose a new one')
        : (l10n?.createPasswordDesc ?? 'Create a password for your account');
    final buttonText = _hasPassword
        ? (l10n?.changePassword ?? 'Change Password')
        : (l10n?.createPassword ?? 'Create Password');

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
                      color: const Color(0xFF683BFC).withValues(alpha: 0.05),
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
                              color: Colors.black.withValues(alpha: 0.08),
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
                        title,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (_isLoading || _isLoadingSettings)
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
                child: _isLoadingSettings
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      )
                    : FadeTransition(
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
                                  subtitle,
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Current Password - only show if user has password
                                if (_hasPassword) ...[
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
                                ],

                                // New Password
                                _buildPasswordField(
                                  controller: _newPasswordController,
                                  label: _hasPassword 
                                      ? (l10n?.newPassword ?? 'New Password')
                                      : (l10n?.password ?? 'Password'),
                                  obscure: _obscureNewPassword,
                                  onToggle: () => setState(
                                    () => _obscureNewPassword = !_obscureNewPassword,
                                  ),
                                  delay: _hasPassword ? 1 : 0,
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
                                          ? AppColors.secondary.withValues(alpha: 0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isPasswordValid
                                            ? AppColors.secondary.withValues(alpha: 0.3)
                                            : Colors.transparent,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
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
                                                    ? AppColors.secondary.withValues(
                                                        alpha: 0.2,
                                                      )
                                                    : Colors.grey.withValues(alpha: 0.1),
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
                                  delay: _hasPassword ? 2 : 1,
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
                                            .withValues(alpha: 0.5),
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
                                              buttonText,
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
