import 'dart:async';
import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_exception.dart';
import '../services/auth_api_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordVerifyScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordVerifyScreen({super.key, required this.email});

  @override
  State<ForgotPasswordVerifyScreen> createState() =>
      _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState
    extends State<ForgotPasswordVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 0;
  Timer? _timer;

  /// Translate backend error messages to localized strings
  String _translateError(String message, AppLocalizations l10n) {
    // Check for rate limiting message with seconds
    final waitMatch = RegExp(r'wait (\d+) seconds').firstMatch(message);
    if (waitMatch != null) {
      return l10n.pleaseWaitSeconds(waitMatch.group(1)!);
    }

    // Map common backend errors to localized strings
    if (message.contains('User not found')) {
      return l10n.userNotFound;
    }
    if (message.contains('Invalid reset code') ||
        message.contains('Invalid verification code')) {
      return l10n.invalidVerificationCode;
    }
    if (message.contains('expired')) {
      return l10n.verificationCodeExpired;
    }
    if (message.contains('No reset code')) {
      return l10n.noVerificationCode;
    }

    // Return original message if no translation found
    return message;
  }

  @override
  void initState() {
    super.initState();
    // Start countdown immediately since code was just sent from signin screen
    _countdown = 60;
    _startCountdown();
    _showExpiryInfo();
  }

  void _showExpiryInfo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.codeExpiresInfo,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue[700],
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _authApiService.dispose();
    super.dispose();
  }

  Future<void> _loadCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reset_countdown_${widget.email}';
    final expiryTimestamp = prefs.getInt(key);

    if (expiryTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((expiryTimestamp - now) / 1000).ceil();

      if (remaining > 0) {
        setState(() {
          _countdown = remaining;
        });
        _startCountdown();
      } else {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _saveCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reset_countdown_${widget.email}';
    final expiryTimestamp =
        DateTime.now().millisecondsSinceEpoch + (_countdown * 1000);
    await prefs.setInt(key, expiryTimestamp);
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
          }
        });
        if (_countdown > 0) {
          await _saveCountdown();
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('reset_countdown_${widget.email}');
        }
      }
    });
  }

  Future<void> _resendCode() async {
    if (_isResending || _countdown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _authApiService.requestPasswordReset(widget.email);

      if (mounted) {
        setState(() {
          _countdown = 60;
        });
        _startCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.codeSentSuccessfully,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String errorMessage = l10n.anErrorOccurred;

        if (e is ApiException) {
          errorMessage = _translateError(e.message, l10n);

          // Extract countdown from error message
          final waitMatch = RegExp(r'wait (\d+) seconds').firstMatch(e.message);
          if (waitMatch != null) {
            final seconds = int.parse(waitMatch.group(1)!);
            setState(() {
              _countdown = seconds;
            });
            _startCountdown();
          }
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
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.pleaseEnterComplete6DigitCode,
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
      _isLoading = true;
    });

    try {
      await _authApiService.verifyResetCode(widget.email, code);

      if (mounted) {
        // Navigate to reset password screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: widget.email,
              code: code,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String errorMessage = l10n.anErrorOccurred;

        if (e is ApiException) {
          errorMessage = _translateError(e.message, l10n);
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

  void _handlePaste(String value) {
    // Extract only digits
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');

    // Fill boxes with digits
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }

    // Focus last filled box or last box if all filled
    if (digits.length >= 6) {
      _focusNodes[5].unfocus();
    } else if (digits.length > 0) {
      _focusNodes[digits.length - 1].requestFocus();
    }

    setState(() {});
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

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.5,
            color: _focusNodes[index].hasFocus
                ? const Color(0xFFEE3764)
                : const Color(0xFFE0E0E6),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.backspace) {
              if (_controllers[index].text.isEmpty && index > 0) {
                // Move to previous box and clear it
                _controllers[index - 1].clear();
                _focusNodes[index - 1].requestFocus();
              }
            }
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6, // Allow pasting full code
          style: const TextStyle(
            color: Color(0xFF13123A),
            fontSize: 18,
            fontFamily: 'Nunito Sans',
            fontWeight: FontWeight.w600,
            height: 1.50,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onTap: () {
            // Auto-focus first empty box if clicking ahead
            for (int i = 0; i < index; i++) {
              if (_controllers[i].text.isEmpty) {
                _focusNodes[i].requestFocus();
                return;
              }
            }
          },
          onChanged: (value) {
            // Check if user pasted a full code (more than 1 character)
            if (value.length > 1) {
              _handlePaste(value);
              return;
            }

            setState(() {});

            if (value.isNotEmpty) {
              // Move to next box
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else {
                // Last box - unfocus keyboard
                _focusNodes[index].unfocus();
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                  // Icon container - using lock/key icon for password reset
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEE3764),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    AppLocalizations.of(context)!.checkYourMailbox,
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

                  // Subtitle with masked email in secondary color
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
                          TextSpan(
                            text: 'We have sent a 6-digit reset code to ',
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
                  // OTP Input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                          right: index < 5 ? 12 : 0,
                        ),
                        child: _buildOtpBox(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEE3764),
                        disabledBackgroundColor: const Color(0xFFEE3764)
                            .withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
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
                              AppLocalizations.of(context)!.verify,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w600,
                                height: 1.50,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Resend code button
                  TextButton(
                    onPressed: _countdown > 0 || _isResending
                        ? null
                        : _resendCode,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFFEE3764),
                              strokeWidth: 2,
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: AppLocalizations.of(context)!
                                      .didntReceiveCode,
                                  style: const TextStyle(
                                    color: Color(0xFF13123A),
                                    fontSize: 14,
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: _countdown > 0
                                      ? '(${_countdown}s)'
                                      : AppLocalizations.of(context)!
                                          .resendOtp,
                                  style: TextStyle(
                                    color: _countdown > 0
                                        ? const Color(0xFF4CC3C7)
                                        : const Color(0xFF4CC3C7),
                                    fontSize: 14,
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w600,
                                    height: 1.50,
                                  ),
                                ),
                              ],
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
