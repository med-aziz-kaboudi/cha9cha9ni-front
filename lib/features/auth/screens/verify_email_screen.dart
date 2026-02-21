import 'dart:async';
import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:cha9cha9ni/main.dart' show PendingVerificationHelper;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/api_exception.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/utils/error_sanitizer.dart';
import '../models/auth_request_models.dart';
import '../services/auth_api_service.dart';
import 'signin_screen.dart';
import 'verification_success_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
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
  final _tokenStorage = TokenStorageService();

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
    if (message.contains('already verified')) {
      return l10n.emailAlreadyVerified;
    }
    if (message.contains('User not found')) {
      return l10n.userNotFound;
    }
    if (message.contains('Invalid verification code')) {
      return l10n.invalidVerificationCode;
    }
    if (message.contains('expired')) {
      return l10n.verificationCodeExpired;
    }
    if (message.contains('No verification code')) {
      return l10n.noVerificationCode;
    }
    
    // Return original message if no translation found
    return message;
  }

  @override
  void initState() {
    super.initState();
    _loadCountdown();
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
    final key = 'resend_countdown_${widget.email}';
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
    final key = 'resend_countdown_${widget.email}';
    final expiryTimestamp =
        DateTime.now().millisecondsSinceEpoch + (_countdown * 1000);
    await prefs.setInt(key, expiryTimestamp);
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
        if (_countdown == 0) {
          timer.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('resend_countdown_${widget.email}');
        }
      } else {
        timer.cancel();
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  /// Auto-fill all OTP boxes when a full code is pasted
  void _handlePaste(String pastedText) {
    // Extract only digits from pasted text
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digits.length >= 6) {
      // Fill all boxes with the first 6 digits
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
      }
      // Unfocus and trigger rebuild
      _focusNodes[5].unfocus();
      setState(() {});
    }
  }

  Future<void> _handleVerifyEmail() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterAllDigits),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = VerifyEmailRequest(
        email: widget.email,
        code: _code,
      );

      final response = await _authApiService.verifyEmail(request);

      if (!mounted) return;

      if (response.isSuccess) {
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
          email: response.user?.email ?? widget.email,
          phone: response.user?.phone,
          profilePictureUrl: response.user?.profilePictureUrl,
          identityVerified: response.user?.identityVerified,
        );

        // Clear countdown on successful verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('resend_countdown_${widget.email}');
        
        // Clear pending verification
        await PendingVerificationHelper.clear();

        // Navigate to success screen - clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const VerificationSuccessScreen()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translateError(e.message, l10n)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.verificationFailed(ErrorSanitizer.message(e, fallback: AppLocalizations.of(context)!.anErrorOccurred))),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendCode() async {
    if (_countdown > 0) return;

    setState(() => _isResending = true);

    try {
      final request = ResendVerificationRequest(email: widget.email);
      final response = await _authApiService.resendVerification(request);

      if (!mounted) return;

      setState(() {
        _countdown = 60;
      });
      await _saveCountdown();
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      
      // Check if error contains remaining seconds from rate limiting
      final match = RegExp(r'wait (\d+) seconds').firstMatch(e.message);
      if (match != null) {
        final seconds = int.parse(match.group(1)!);
        setState(() {
          _countdown = seconds;
        });
        await _saveCountdown();
        _startCountdown();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translateError(e.message, l10n)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Widget _buildDigitBox(int index) {
    return Container(
      width: 48,
      height: 48,
      decoration: ShapeDecoration(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.5,
            color: _focusNodes[index].hasFocus
                ? const Color(0xFF4CC3C7)
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
                      onPressed: () async {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        
                        // Clear pending verification when user goes back
                        await PendingVerificationHelper.clear();
                        
                        // Sign out from Supabase if there's a session (Google OAuth)
                        final session = Supabase.instance.client.auth.currentSession;
                        if (session != null) {
                          await Supabase.instance.client.auth.signOut();
                        }
                        
                        // Navigate to sign-in screen
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const SignInScreen()),
                            (route) => false,
                          );
                        }
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEE3764),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    AppLocalizations.of(context)!.otpVerification,
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

                  // Subtitle
                  Opacity(
                    opacity: 0.80,
                    child: Text(
                      AppLocalizations.of(context)!.verifyEmailSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF13123A),
                        fontSize: 14,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Description
                  Text(
                    AppLocalizations.of(context)!.verifyEmailDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF13123A),
                        fontSize: 14,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                  ),

                  const SizedBox(height: 8),

                  // Email display
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4CC3C7),
                      fontSize: 14,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.50,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // OTP Digit boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (index) => Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: index == 0 ? 0 : 8,
                        ),
                        child: _buildDigitBox(index),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerifyEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEE3764),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.verify,
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

                  const SizedBox(height: 16),

                  // Resend button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: (_countdown > 0 || _isResending) ? null : _handleResendCode,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          width: 1,
                          color: _countdown > 0
                              ? const Color(0xFFE0E0E6)
                              : const Color(0xFF13123A),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isResending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4CC3C7),
                                ),
                              ),
                            )
                          : Text(
                              _countdown > 0
                                  ? AppLocalizations.of(context)!.resendOTPIn(_countdown.toString())
                                  : AppLocalizations.of(context)!.resendOTP,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _countdown > 0
                                    ? const Color(0xFFE0E0E6)
                                    : const Color(0xFF4CC3C7),
                                fontSize: 14,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
                                height: 1.50,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
