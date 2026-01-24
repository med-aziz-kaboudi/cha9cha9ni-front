import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/services/api_exception.dart';
import '../services/auth_api_service.dart';
import 'password_reset_success_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Password requirements
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _hasUpperCase = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _passwordController.addListener(_validateConfirmPassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  void _validateConfirmPassword() {
    // Trigger rebuild to update border colors and clear/show errors dynamically
    setState(() {});
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

  double _getPasswordStrength() {
    int strength = 0;
    if (_hasMinLength) strength++;
    if (_hasNumber) strength++;
    if (_hasSymbol) strength++;
    if (_hasUpperCase) strength++;
    return strength / 4;
  }

  Color _getPasswordStrengthColor() {
    final strength = _getPasswordStrength();
    if (strength >= 1.0) return const Color(0xFF4CC3C7); // Secondary - all requirements met
    if (strength >= 0.5) return const Color(0xFFFF9800); // Orange - half requirements
    return const Color(0xFFEE3764); // Primary - weak
  }

  Color _getConfirmPasswordBorderColor({bool focused = false}) {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;
    
    // Empty field - default color
    if (confirmPassword.isEmpty) {
      return focused ? const Color(0xFF4CC3C7) : const Color(0xFFE0E0E6);
    }
    
    // Passwords match - secondary (green/teal)
    if (confirmPassword == password && password.isNotEmpty) {
      return const Color(0xFF4CC3C7);
    }
    
    // Passwords don't match - show error color
    return const Color(0xFFEE3764);
  }

  String? _getConfirmPasswordError() {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context);
    
    // Don't show error if confirm field is empty
    if (confirmPassword.isEmpty) {
      return null;
    }
    
    // Show mismatch error
    if (confirmPassword != password) {
      return l10n?.passwordsDoNotMatch ?? 'Passwords do not match';
    }
    
    return null;
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }

    return '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}@$domain';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authApiService.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authApiService.resetPassword(
        widget.email,
        widget.code,
        _passwordController.text,
      );

      if (mounted) {
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PasswordResetSuccessScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String errorMessage = l10n.anErrorOccurred;

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
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? const Color(0xFF4CC3C7) : const Color(0xFFB4B4C1),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? const Color(0xFF4CC3C7) : const Color(0xFF13123A),
            fontSize: 12,
            fontFamily: 'Nunito Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          image: DecorationImage(
            image: AssetImage('assets/images/Element.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Directionality.of(context) == TextDirection.rtl
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: IconButton(
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        color: const Color(0xFF4CC3C7),
                        size: 32,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEE3764),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    l10n.resetPassword,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 24,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description with masked email
                  Opacity(
                    opacity: 0.80,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF13123A),
                          fontSize: 14,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Create new strong password for updating ',
                          ),
                          TextSpan(
                            text: _maskEmail(widget.email),
                            style: const TextStyle(
                              color: Color(0xFF4CC3C7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 14,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.enterYourPassword,
                      hintStyle: const TextStyle(
                        color: Color(0xFFC7C7D1),
                        fontSize: 14,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF8A8AA3),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF8A8AA3),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: (_hasMinLength && _hasNumber && _hasSymbol && _hasUpperCase)
                              ? const Color(0xFF4CC3C7)
                              : (_passwordController.text.isNotEmpty
                                  ? const Color(0xFFEE3764)
                                  : const Color(0xFFE0E0E6)),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: (_hasMinLength && _hasNumber && _hasSymbol && _hasUpperCase)
                              ? const Color(0xFF4CC3C7)
                              : (_passwordController.text.isNotEmpty
                                  ? const Color(0xFFEE3764)
                                  : const Color(0xFFE0E0E6)),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: (_hasMinLength && _hasNumber && _hasSymbol && _hasUpperCase)
                              ? const Color(0xFF4CC3C7)
                              : const Color(0xFFEE3764),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      if (value.length < 8) {
                        return l10n.passwordMinLength;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Password strength indicator
                  if (_passwordController.text.isNotEmpty) ...[
                    // Strength bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _getPasswordStrength(),
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE0E0E6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getPasswordStrengthColor(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Requirements checklist
                    _buildRequirement(
                      '8 characters minimum',
                      _hasMinLength,
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement(
                      'a number',
                      _hasNumber,
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement(
                      'an uppercase letter',
                      _hasUpperCase,
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement(
                      'a symbol',
                      _hasSymbol,
                    ),

                    const SizedBox(height: 9),
                  ] else
                    const SizedBox(height: 9),

                  // Confirm Password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 14,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.confirmYourPassword,
                      hintStyle: const TextStyle(
                        color: Color(0xFFC7C7D1),
                        fontSize: 14,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF8A8AA3),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF8A8AA3),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _getConfirmPasswordBorderColor(),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _getConfirmPasswordBorderColor(),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _getConfirmPasswordBorderColor(focused: true),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                      // Show error text dynamically without form validation
                      errorText: _getConfirmPasswordError(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.confirmPasswordRequired;
                      }
                      if (value != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // Reset Password button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEE3764),
                        disabledBackgroundColor:
                            const Color(0xFFEE3764).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirm Reset Password',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
                                height: 1.50,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
