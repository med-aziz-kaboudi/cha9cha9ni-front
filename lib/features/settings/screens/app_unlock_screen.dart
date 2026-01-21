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
      
      // Load full status in background for lockout info
      _unlockStatus = await _biometricService.getUnlockStatus();
      
      if (_unlockStatus != null && mounted) {
        // If locked, start countdown timer
        if (_unlockStatus!.isLocked && !_unlockStatus!.permanentlyLocked) {
          _startLockoutTimer();
          setState(() {}); // Refresh UI with lockout info
        }
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
    final biometricEnabled = _unlockStatus?.biometricEnabled == true;
    // TODO: These would come from backend when implemented
    // ignore: dead_code
    final passkeyEnabled = false; // Device passkey - coming soon
    // ignore: dead_code
    final twoFAEnabled = false; // 2FA - coming soon
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                
                // Title
                Text(
                  l10n?.unlockOptions ?? 'Unlock Options',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.chooseUnlockMethod ?? 'Choose how to unlock',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Face ID option
                if (biometricEnabled)
                  _buildUnlockOptionTile(
                    icon: _hasFaceId ? Icons.face : Icons.fingerprint,
                    title: l10n?.tryFaceIdAgain ?? 'Try Face ID again',
                    subtitle: _hasFaceId 
                        ? (l10n?.faceId ?? 'Face ID')
                        : (l10n?.fingerprint ?? 'Fingerprint'),
                    iconColor: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _attemptBiometricUnlock();
                    },
                  ),
                
                // Passkey option (coming soon)
                _buildUnlockOptionTile(
                  icon: Icons.key,
                  title: l10n?.usePasskey ?? 'Use Passkey',
                  subtitle: l10n?.devicePasskey ?? 'Device Passkey',
                  iconColor: Colors.blue,
                  enabled: passkeyEnabled,
                  comingSoon: !passkeyEnabled,
                  onTap: null, // Will be enabled when passkey is implemented
                ),
                
                // 2FA option (coming soon)
                _buildUnlockOptionTile(
                  icon: Icons.security,
                  title: l10n?.use2FACode ?? 'Use 2FA Code',
                  subtitle: l10n?.authenticatorApp ?? 'Authenticator App',
                  iconColor: Colors.purple,
                  enabled: twoFAEnabled,
                  comingSoon: !twoFAEnabled,
                  onTap: null, // Will be enabled when 2FA is implemented
                ),
                
                const SizedBox(height: 16),
                
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      l10n?.cancel ?? 'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
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

  Widget _buildUnlockOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    bool enabled = true,
    bool comingSoon = false,
    VoidCallback? onTap,
  }) {
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: enabled ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (enabled ? iconColor : Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? iconColor : Colors.grey,
                    size: 24,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: enabled ? AppColors.dark : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
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
                
                // Coming soon badge or arrow
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n?.soon ?? 'Soon',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  )
                else if (enabled)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
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
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
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
                    color: Colors.black.withOpacity(0.05),
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
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
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
                    color: Colors.orange.withOpacity(0.15),
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
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
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
                    AppColors.secondary.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
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
                      color: Colors.black.withOpacity(0.05),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                  color: AppColors.secondary.withOpacity(0.1),
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

            // Use another method button (only if biometric is enabled)
            if (_isBiometricEnabled) ...[
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
