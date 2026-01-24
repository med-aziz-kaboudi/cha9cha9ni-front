import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Screen shown when app opens and security is enabled
/// User must authenticate via biometrics or passkey
class AppUnlockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback? onLogout;

  const AppUnlockScreen({
    super.key,
    required this.onUnlocked,
    this.onLogout,
  });

  @override
  State<AppUnlockScreen> createState() => _AppUnlockScreenState();
}

class _AppUnlockScreenState extends State<AppUnlockScreen>
    with SingleTickerProviderStateMixin {
  final _biometricService = BiometricService();
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  UnlockStatus? _unlockStatus;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _showPinInput = false;
  bool _hasFaceId = false;
  bool _isBiometricEnabled = false;
  String? _error;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _loadUnlockStatus();
    _checkFaceIdAvailable();
  }

  Future<void> _checkFaceIdAvailable() async {
    final hasFaceId = await _biometricService.hasFaceId();
    final isBiometricEnabled = await _biometricService.isBiometricEnabledLocally();
    if (mounted) {
      setState(() {
        _hasFaceId = hasFaceId;
        _isBiometricEnabled = isBiometricEnabled;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnlockStatus() async {
    // Don't show loading spinner - immediately try to unlock
    // This makes the app feel much faster
    
    try {
      // Check locally first - is biometric enabled?
      final canUseBiometrics = await _biometricService.canUseBiometrics();
      final isBiometricEnabled = await _biometricService.isBiometricEnabledLocally();
      
      // Always load unlock status in background for 2FA and lockout info
      _biometricService.getUnlockStatus().then((status) {
        if (mounted && status != null) {
          setState(() {
            _unlockStatus = status;
          });
          // If locked, start countdown timer
          if (status.isLocked && !status.permanentlyLocked) {
            _startLockoutTimer();
          }
        }
      });
      
      if (canUseBiometrics && isBiometricEnabled) {
        // Attempt biometric immediately without waiting for API
        if (mounted) {
          setState(() => _isLoading = false);
        }
        _attemptBiometricUnlock();
        return;
      }
      
      // No biometric - show PIN input immediately
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showPinInput = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading unlock status: $e');
      // On error, just show PIN input
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showPinInput = true;
        });
      }
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_unlockStatus?.lockedUntil != null) {
        final remaining = _unlockStatus!.lockedUntil!.difference(DateTime.now());
        if (remaining.isNegative) {
          timer.cancel();
          _loadUnlockStatus(); // Refresh status
        } else {
          setState(() {}); // Trigger rebuild for countdown
        }
      }
    });
  }

  Future<void> _attemptBiometricUnlock() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final result = await _biometricService.verifyAppUnlock(useBiometric: true);

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (result.success) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      // Show PIN input as fallback
      setState(() {
        _showPinInput = true;
        _error = null; // Don't show error for biometric fallback
      });
      _focusNode.requestFocus();
    }
  }

  Future<void> _attemptPinUnlock() async {
    if (_isVerifying) return;

    final pin = _pinController.text;
    if (pin.length != 6) {
      setState(() {
        _error = AppLocalizations.of(context)?.pinMustBe6Digits ?? 
            'PIN must be 6 digits';
      });
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final result = await _biometricService.verifyAppUnlock(
      useBiometric: false,
      passkey: pin,
    );

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (result.success) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      _pinController.clear();
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();

      if (result.isLocked == true) {
        // Reload status to get updated lockout info
        _loadUnlockStatus();
      } else if (result.permanentlyLocked == true) {
        setState(() {
          _unlockStatus = UnlockStatus(
            securityEnabled: true,
            biometricEnabled: false,
            passkeyEnabled: true,
            isLocked: true,
            permanentlyLocked: true,
            remainingSeconds: 0,
            lockoutLevel: 4,
            failedAttempts: 0,
            maxAttempts: 3,
          );
        });
      } else {
        setState(() {
          _error = result.message ?? 
              (AppLocalizations.of(context)?.attemptsRemaining(result.remainingAttempts ?? 0) ??
               '${result.remainingAttempts} attempts remaining');
        });
      }
    }
  }

  /// Show bottom sheet with alternative unlock options
  void _showUnlockOptions() {
    final l10n = AppLocalizations.of(context);
    final twoFAEnabled = _unlockStatus?.totpEnabled == true;
    // Passkey will be added here when implemented
    // final passkeyEnabled = _unlockStatus?.passkeyEnabled == true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.15),
                        AppColors.secondary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  l10n?.alternativeUnlock ?? 'Alternative Unlock',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.chooseSecureMethod ?? 'Choose a secure method to unlock',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 2FA option - only show if 2FA is enabled
                if (twoFAEnabled)
                  _buildModernUnlockOption(
                    icon: Icons.apps_rounded,
                    title: l10n?.authenticatorCode ?? 'Authenticator Code',
                    subtitle: l10n?.enter6DigitCode ?? 'Enter 6-digit code from your app',
                    gradientColors: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                    onTap: () {
                      Navigator.pop(context);
                      _show2FAInputDialog();
                    },
                  ),
                
                // Passkey option will be added here when implemented
                // if (passkeyEnabled)
                //   _buildModernUnlockOption(...),
                
                const SizedBox(height: 16),
                
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n?.cancel ?? 'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Modern unlock option tile with gradient icon
  Widget _buildModernUnlockOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog for 2FA code input
  void _show2FAInputDialog() {
    final l10n = AppLocalizations.of(context);
    final codeController = TextEditingController();
    bool isVerifying = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with gradient background
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.secondary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      l10n?.enter2FACode ?? 'Enter 2FA Code',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.enterCodeFromAuthenticator ?? 
                          'Enter the 6-digit code from your authenticator app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Code input with individual boxes look
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: errorText != null
                              ? AppColors.primary
                              : AppColors.secondary.withValues(alpha: 0.3),
                          width: errorText != null ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (errorText != null 
                                ? AppColors.primary 
                                : AppColors.secondary).withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 32,
                          letterSpacing: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                        decoration: InputDecoration(
                          hintText: '······',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            letterSpacing: 16,
                            color: Colors.grey[300],
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (errorText != null) {
                            setDialogState(() => errorText = null);
                          }
                        },
                      ),
                    ),

                    // Error message
                    if (errorText != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              errorText!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Verify button (full width)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final code = codeController.text;
                                if (code.length != 6) {
                                  setDialogState(() {
                                    errorText = l10n?.enterSixDigitCode ??
                                        'Enter 6-digit code';
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  isVerifying = true;
                                  errorText = null;
                                });

                                final result = await _biometricService
                                    .verifyAppUnlockWithTotp(code);

                                if (!context.mounted) return;

                                if (result.success) {
                                  Navigator.pop(dialogContext);
                                  HapticFeedback.mediumImpact();
                                  widget.onUnlocked();
                                } else {
                                  setDialogState(() {
                                    isVerifying = false;
                                    codeController.clear();
                                    
                                    if (result.isLocked == true) {
                                      Navigator.pop(dialogContext);
                                      _loadUnlockStatus();
                                    } else if (result.permanentlyLocked == true) {
                                      Navigator.pop(dialogContext);
                                      setState(() {
                                        _unlockStatus = UnlockStatus(
                                          securityEnabled: true,
                                          biometricEnabled: false,
                                          passkeyEnabled: true,
                                          totpEnabled: true,
                                          isLocked: true,
                                          permanentlyLocked: true,
                                          remainingSeconds: 0,
                                          lockoutLevel: 4,
                                          failedAttempts: 0,
                                          maxAttempts: 3,
                                        );
                                      });
                                    } else {
                                      errorText = result.message ??
                                          (l10n?.invalidCode ?? 'Invalid code');
                                    }
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n?.verify ?? 'Verify',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: isVerifying
                            ? null
                            : () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n?.cancel ?? 'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                )
              : _buildContent(l10n),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations? l10n) {
    // Check for permanent lock
    if (_unlockStatus?.permanentlyLocked == true) {
      return _buildPermanentlyLockedView(l10n);
    }

    // Check for temporary lock
    if (_unlockStatus?.isLocked == true && _unlockStatus?.lockedUntil != null) {
      return _buildLockedView(l10n);
    }

    // Normal unlock view
    return _buildUnlockView(l10n);
  }

  Widget _buildPermanentlyLockedView(AppLocalizations? l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Logo
            Image.asset(
              'assets/icons/horisental.png',
              width: MediaQuery.of(context).size.width * 0.45,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 48),

            // Lock icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              l10n?.accountLocked ?? 'Account Locked',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              child: Text(
                l10n?.accountPermanentlyLocked ?? 
                    'Your account has been permanently locked due to multiple failed unlock attempts. Please contact our support team to regain access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Contact support button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open email or support page
                },
                icon: const Icon(Icons.support_agent, size: 20),
                label: Text(
                  l10n?.contactSupport ?? 'Contact Support',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            if (widget.onLogout != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  l10n?.signOut ?? 'Sign Out',
                  style: const TextStyle(fontSize: 15),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedView(AppLocalizations? l10n) {
    final remaining = _unlockStatus!.lockedUntil!.difference(DateTime.now());
    final formattedTime = _formatRemainingTime(remaining);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Logo
            Image.asset(
              'assets/icons/horisental.png',
              width: MediaQuery.of(context).size.width * 0.45,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 48),

            // Lock icon with timer
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_clock,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              l10n?.accountLocked ?? 'Account Locked',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 20),

            // Countdown card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    l10n?.tryAgainIn('') ?? 'Try again in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info text card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getLockoutMessage(l10n),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.onLogout != null) ...[
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  l10n?.signOut ?? 'Sign Out',
                  style: const TextStyle(fontSize: 15),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getLockoutMessage(AppLocalizations? l10n) {
    switch (_unlockStatus?.lockoutLevel) {
      case 1:
        return 'Too many failed attempts. Please wait 1 hour before trying again.';
      case 2:
        return 'Multiple failed attempts detected. Please wait 24 hours before trying again.';
      case 3:
        return 'Security lockout active. Please wait 1 week before trying again.';
      default:
        return 'Account temporarily locked for security.';
    }
  }

  Widget _buildUnlockView(AppLocalizations? l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Logo
            Image.asset(
              'assets/icons/horisental.png',
              width: MediaQuery.of(context).size.width * 0.45,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 48),

            // App unlock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_open,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              l10n?.unlockApp ?? 'Unlock App',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              l10n?.enterPinToUnlock ?? 'Enter your PIN to unlock',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),

            // PIN input
            if (_showPinInput) ...[
              Container(
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
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value * 10 * 
                            ((_shakeController.value * 10).floor() % 2 == 0 ? 1 : -1),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: TextField(
                    controller: _pinController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    enabled: !_isVerifying,
                    style: const TextStyle(
                      fontSize: 32,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (value.length == 6) {
                        _attemptPinUnlock();
                      }
                    },
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Unlock button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _attemptPinUnlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n?.unlockApp ?? 'Unlock',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],

            // Biometric button (if available and enabled)
            if (_isBiometricEnabled) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: _isVerifying ? null : _attemptBiometricUnlock,
                  icon: Icon(
                    _hasFaceId ? Icons.face : Icons.fingerprint,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                  label: Builder(
                    builder: (context) {
                      final type = _hasFaceId 
                          ? (l10n?.faceId ?? 'Face ID') 
                          : (l10n?.fingerprint ?? 'Fingerprint');
                      return Text(
                        l10n?.useBiometric(type) ?? 'Use $type',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      );
                    },
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],

            // Show PIN button if biometric
            if (!_showPinInput && _unlockStatus?.passkeyEnabled == true) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _showPinInput = true);
                  _focusNode.requestFocus();
                },
                child: Text(
                  l10n?.usePinInstead ?? 'Use PIN instead',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],

            // Use another method button - only show when there are alternative methods available
            // Currently shows when 2FA is enabled (passkey will be added later)
            if (_unlockStatus?.totpEnabled == true) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _showUnlockOptions,
                icon: Icon(
                  Icons.more_horiz,
                  color: Colors.grey[600],
                  size: 20,
                ),
                label: Text(
                  l10n?.useAnotherMethod ?? 'Use another method',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            if (widget.onLogout != null) ...[
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  l10n?.signOut ?? 'Sign Out',
                  style: const TextStyle(fontSize: 15),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
