import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/app_localizations.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen>
    with SingleTickerProviderStateMixin {
  final _biometricService = BiometricService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isSaving = false;
  SecuritySettings? _settings;
  bool _canUseBiometrics = false;
  bool _hasFaceId = false;
  bool _hasFingerprint = false;

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
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Check device capabilities
      _canUseBiometrics = await _biometricService.canUseBiometrics();
      _hasFaceId = await _biometricService.hasFaceId();
      _hasFingerprint = await _biometricService.hasFingerprint();

      // Get settings from backend
      _settings = await _biometricService.getSecuritySettings();
    } catch (e) {
      debugPrint('Error loading security settings: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  String get _biometricName {
    final l10n = AppLocalizations.of(context);
    if (_hasFaceId) return l10n?.faceId ?? 'Face ID';
    if (_hasFingerprint) return l10n?.fingerprint ?? 'Fingerprint';
    return l10n?.biometrics ?? 'Biometrics';
  }

  Future<void> _setupPinCode() async {
    final pin = await _showPinDialog(
      title: AppLocalizations.of(context)?.setupPinCode ?? 'Set Up PIN Code',
      subtitle: AppLocalizations.of(context)?.enterNewPin ?? 
          'Enter a 6-digit PIN to secure your account',
      confirmRequired: true,
    );

    if (pin == null || pin.isEmpty) return;

    setState(() => _isSaving = true);

    final result = await _biometricService.setupPasskey(pin);

    if (mounted) {
      setState(() => _isSaving = false);

      if (result.success) {
        AppToast.success(
          context,
          AppLocalizations.of(context)?.pinSetupSuccess ?? 
              'PIN Code set up successfully',
        );
        _loadSettings();
      } else {
        AppToast.error(
          context,
          result.error ?? (AppLocalizations.of(context)?.failedToSetupPin ?? 'Failed to set up PIN Code'),
        );
      }
    }
  }

  Future<void> _changePinCode() async {
    // First verify current PIN
    final currentPin = await _showPinDialog(
      title: AppLocalizations.of(context)?.currentPin ?? 'Current PIN',
      subtitle: AppLocalizations.of(context)?.enterCurrentPin ?? 
          'Enter your current PIN',
      confirmRequired: false,
    );

    if (currentPin == null || currentPin.isEmpty) return;

    // Then get new PIN
    final newPin = await _showPinDialog(
      title: AppLocalizations.of(context)?.newPin ?? 'New PIN',
      subtitle: AppLocalizations.of(context)?.enterNewPin ?? 
          'Enter your new 6-digit PIN',
      confirmRequired: true,
    );

    if (newPin == null || newPin.isEmpty) return;

    setState(() => _isSaving = true);

    final result = await _biometricService.changePasskey(currentPin, newPin);

    if (mounted) {
      setState(() => _isSaving = false);

      if (result.success) {
        AppToast.success(
          context,
          AppLocalizations.of(context)?.pinChangedSuccess ?? 
              'PIN changed successfully',
        );
      } else {
        AppToast.error(
          context,
          result.error ?? (AppLocalizations.of(context)?.failedToChangePin ?? 'Failed to change PIN'),
        );
      }
    }
  }

  Future<void> _removePinCode() async {
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RemovePinDialog(
        biometricService: _biometricService,
        l10n: l10n,
      ),
    );

    if (result == true && mounted) {
      AppToast.success(
        context,
        l10n?.pinRemovedSuccess ?? 'PIN Code removed',
      );
      _loadSettings();
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    final l10n = AppLocalizations.of(context);
    final isPinEnabled = _settings?.passkeyEnabled ?? false;
    
    // PIN is required before enabling Face ID
    if (enable && !isPinEnabled) {
      AppToast.info(
        context,
        l10n?.pinRequiredForFaceId ?? 'Please set up PIN code first',
      );
      return;
    }
    
    if (!_canUseBiometrics) {
      AppToast.error(
        context,
        l10n?.biometricsNotAvailable ?? 
            'Biometrics not available on this device',
      );
      return;
    }

    if (enable) {
      // First verify biometric works
      final authenticated = await _biometricService.authenticateWithBiometrics(
        reason: l10n?.confirmBiometric ?? 
            'Confirm biometric to enable',
      );

      if (!authenticated) {
        if (mounted) {
          AppToast.error(
            context,
            AppLocalizations.of(context)?.biometricAuthFailed ?? 
                'Biometric authentication failed',
          );
        }
        return;
      }
    }

    setState(() => _isSaving = true);

    final result = enable 
        ? await _biometricService.enableBiometric()
        : await _biometricService.disableBiometric();

    if (mounted) {
      setState(() => _isSaving = false);

      if (result.success) {
        AppToast.success(
          context,
          enable 
              ? (AppLocalizations.of(context)?.biometricEnabled ?? '$_biometricName enabled')
              : (AppLocalizations.of(context)?.biometricDisabled ?? '$_biometricName disabled'),
        );
        _loadSettings();
      } else {
        AppToast.error(
          context,
          result.error ?? (AppLocalizations.of(context)?.failedToUpdateBiometric ?? 'Failed to update biometric settings'),
        );
      }
    }
  }

  Future<String?> _showPinDialog({
    required String title,
    required String subtitle,
    required bool confirmRequired,
  }) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final l10n = AppLocalizations.of(context);
    bool isConfirmStep = false;
    String? errorMessage;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentController = isConfirmStep ? confirmController : pinController;
          final currentTitle = isConfirmStep 
              ? (l10n?.confirmPin ?? 'Confirm PIN')
              : title;
          final currentSubtitle = isConfirmStep
              ? (l10n?.reenterPinToConfirm ?? 'Re-enter your PIN to confirm')
              : subtitle;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 16,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withOpacity(0.1),
                            AppColors.secondary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConfirmStep ? Icons.check_circle_outline : Icons.lock_outline,
                        color: AppColors.secondary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      currentTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      currentSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // PIN Input with individual boxes look
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: errorMessage != null 
                              ? AppColors.primary 
                              : Colors.grey.withOpacity(0.2),
                          width: errorMessage != null ? 2 : 1,
                        ),
                      ),
                      child: TextFormField(
                        controller: currentController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        obscuringCharacter: '●',
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 32,
                          letterSpacing: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                        decoration: const InputDecoration(
                          hintText: '······',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            letterSpacing: 16,
                            color: Colors.grey,
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (errorMessage != null) {
                            setDialogState(() => errorMessage = null);
                          }
                        },
                      ),
                    ),

                    // Error message
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      children: [
                        // Cancel/Back button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                if (isConfirmStep) {
                                  setDialogState(() {
                                    isConfirmStep = false;
                                    confirmController.clear();
                                    errorMessage = null;
                                  });
                                } else {
                                  Navigator.pop(dialogContext, null);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isConfirmStep 
                                    ? (l10n?.back ?? 'Back')
                                    : (l10n?.cancel ?? 'Cancel'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Continue/Confirm button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final pin = currentController.text;
                                  
                                  // Validate PIN length
                                  if (pin.length != 6) {
                                    setDialogState(() {
                                      errorMessage = l10n?.pinMustBe6Digits ?? 
                                          'PIN must be 6 digits';
                                    });
                                    return;
                                  }

                                  if (confirmRequired && !isConfirmStep) {
                                    // Move to confirm step
                                    setDialogState(() {
                                      isConfirmStep = true;
                                      errorMessage = null;
                                    });
                                  } else if (confirmRequired && isConfirmStep) {
                                    // Validate PINs match
                                    if (pinController.text != confirmController.text) {
                                      setDialogState(() {
                                        errorMessage = l10n?.pinsDoNotMatch ?? 
                                            'PINs do not match';
                                        confirmController.clear();
                                      });
                                      return;
                                    }
                                    Navigator.pop(dialogContext, pinController.text);
                                  } else {
                                    // No confirmation needed
                                    Navigator.pop(dialogContext, pinController.text);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isConfirmStep || !confirmRequired
                                      ? (l10n?.confirm ?? 'Confirm')
                                      : (l10n?.continueText ?? 'Continue'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Step indicator for confirm flow
                    if (confirmRequired) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: !isConfirmStep 
                                  ? AppColors.secondary 
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isConfirmStep 
                                  ? AppColors.secondary 
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
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
              // Header bar
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
                        l10n?.loginSecurity ?? 'Login & Security',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (_isSaving)
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
                child: _isLoading
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
                                // PIN Code section - first
                                _buildPinCodeCard(),
                                const SizedBox(height: 16),

                                // Face ID section
                                if (_canUseBiometrics) ...[
                                  _buildBiometricCard(),
                                  const SizedBox(height: 16),
                                ],

                                // Passkey section (device-based login)
                                _buildPasskeyCard(),
                                const SizedBox(height: 16),

                                // 2FA section (placeholder)
                                _build2FACard(),
                                const SizedBox(height: 16),

                                // Security info
                                _buildSecurityInfoCard(),
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

  Widget _buildPinCodeCard() {
    final l10n = AppLocalizations.of(context);
    final isEnabled = _settings?.passkeyEnabled ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? AppColors.secondary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEnabled ? Icons.pin : Icons.pin_outlined,
                  color: isEnabled ? AppColors.secondary : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.sixDigitPin ?? '6-Digit PIN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnabled
                          ? (l10n?.pinEnabled ?? 'Enabled')
                          : (l10n?.pinNotSet ?? 'Not set up'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isEnabled ? AppColors.secondary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                Icon(
                  Icons.check_circle,
                  color: AppColors.secondary,
                  size: 24,
                ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: l10n?.changePin ?? 'Change',
                    icon: Icons.edit,
                    onTap: _changePinCode,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: l10n?.remove ?? 'Remove',
                    icon: Icons.delete_outline,
                    onTap: _removePinCode,
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            _buildActionButton(
              label: l10n?.setupPin ?? 'Set Up PIN',
              icon: Icons.add,
              onTap: _setupPinCode,
              isPrimary: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasskeyCard() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.key,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.devicePasskey ?? 'Device Passkey',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.passkeyShortDesc ?? 'Passwordless login',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n?.soon ?? 'Soon',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build2FACard() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.security,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.authenticatorApp ?? 'Authenticator App',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.twoFAShortDesc ?? 'Google Authenticator, Authy',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n?.soon ?? 'Soon',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
    final l10n = AppLocalizations.of(context);
    final isEnabled = _settings?.biometricEnabled ?? false;
    final isPinEnabled = _settings?.passkeyEnabled ?? false;
    final isLocked = !isPinEnabled;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEnabled 
                        ? AppColors.secondary.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _hasFaceId ? Icons.face : Icons.fingerprint,
                    color: isEnabled ? AppColors.secondary : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _biometricName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLocked
                            ? (l10n?.requiresPinFirst ?? 'Requires PIN code')
                            : isEnabled
                                ? (l10n?.biometricEnabled ?? 'Enabled')
                                : (l10n?.biometricDisabled ?? 'Disabled'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isLocked 
                              ? Colors.orange
                              : isEnabled ? AppColors.secondary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n?.pinFirst ?? 'PIN first',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Switch(
                    value: isEnabled,
                    onChanged: _isSaving ? null : _toggleBiometric,
                    activeColor: AppColors.secondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfoCard() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.howItWorks ?? 'How it works',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.securityInfoShort ?? 'Face ID first, then PIN as backup. 3 failed attempts locks temporarily.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final Color bgColor;
    final Color textColor;

    if (isDestructive) {
      bgColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
    } else if (isPrimary) {
      bgColor = AppColors.secondary;
      textColor = Colors.white;
    } else {
      bgColor = AppColors.gray;
      textColor = AppColors.dark;
    }

    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// Separate dialog widget for removing PIN to properly manage TextEditingController lifecycle
class _RemovePinDialog extends StatefulWidget {
  final BiometricService biometricService;
  final AppLocalizations? l10n;

  const _RemovePinDialog({
    required this.biometricService,
    required this.l10n,
  });

  @override
  State<_RemovePinDialog> createState() => _RemovePinDialogState();
}

class _RemovePinDialogState extends State<_RemovePinDialog> {
  late TextEditingController _pinController;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleRemove() async {
    final pin = _pinController.text;
    if (pin.length != 6) {
      setState(() {
        _errorText = widget.l10n?.pinMustBe6Digits ?? 'PIN must be 6 digits';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    
    final result = await widget.biometricService.removePasskey(pin);
    
    if (!mounted) return;
    
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _errorText = result.error ?? (widget.l10n?.incorrectPin ?? 'Incorrect PIN');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with warning icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.removePin ?? 'Remove PIN Code',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n?.enterPinToRemove ?? 'Enter your current PIN to confirm removal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // PIN Input
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        letterSpacing: 8,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.red.shade400,
                          width: 2,
                        ),
                      ),
                      errorText: _errorText,
                      errorStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading 
                              ? null 
                              : () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            l10n?.cancel ?? 'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Remove Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade400,
                                Colors.red.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRemove,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    l10n?.remove ?? 'Remove',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}