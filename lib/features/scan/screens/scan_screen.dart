import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../topup/topup_service.dart';

class ScanScreen extends StatefulWidget {
  /// If true, the screen will handle redemption itself and show success/error dialogs.
  /// If false (default), it will just return the scanned code to the caller.
  final bool handleRedemption;

  const ScanScreen({super.key, this.handleRedemption = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  MobileScannerController? _scannerController;
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  bool _showManualEntry = false;
  String? _scannedCode;

  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _initAnimations();
  }

  void _initAnimations() {
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      _initializeScanner();
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _initializeScanner();
      } else {
        setState(() {
          _hasPermission = false;
          _isCheckingPermission = false;
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    setState(() {
      _hasPermission = true;
      _isCheckingPermission = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _scannedCode != null) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true;
        });
        HapticFeedback.mediumImpact();
        _processScannedCode(barcode.rawValue!);
        break;
      }
    }
  }

  /// Process scanned QR code - fill the manual entry panel for user to verify
  void _processScannedCode(String code) {
    // Clean and format the code
    final cleanedCode = code
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    
    if (cleanedCode.isEmpty) {
      // Invalid QR code, reset and continue scanning
      setState(() => _isProcessing = false);
      return;
    }

    // Format with dashes for display
    final formattedCode = _formatCodeWithDashes(cleanedCode);
    
    // Fill the text field and show manual entry panel
    _codeController.text = formattedCode;
    _codeController.selection = TextSelection.fromPosition(
      TextPosition(offset: formattedCode.length),
    );
    
    setState(() {
      _showManualEntry = true;
      _isProcessing = false;
      _scannedCode = cleanedCode; // Mark as scanned to prevent re-scanning
    });
    
    // Stop scanner while showing the code
    _scannerController?.stop();
    
    // Focus on the text field so user can edit if needed
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _codeFocusNode.requestFocus();
    });
  }

  void _onManualSubmit() {
    final code = _codeController.text.trim().toUpperCase().replaceAll('-', '');
    if (code.isEmpty) return;

    if (code.length < 6 || !RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.invalidCodeFormat ?? 'Invalid code',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    
    // If we should handle redemption ourselves (from nav bar), do it here
    if (widget.handleRedemption) {
      _redeemCode(code);
    } else {
      // Otherwise just return the code to the caller (TopUp screen)
      Navigator.of(context).pop(code);
    }
  }

  /// Redeem the code directly (when accessed from nav bar)
  Future<void> _redeemCode(String code) async {
    final l10n = AppLocalizations.of(context);
    final analytics = AnalyticsService();
    final topUpService = TopUpService();

    // Check rate limit first
    final rateLimitStatus = await TopUpService.checkRateLimit();
    if (rateLimitStatus.isLocked) {
      _showRateLimitDialog(rateLimitStatus);
      return;
    }

    // Show loading dialog
    _showLoadingDialog(l10n);

    try {
      final result = await topUpService.redeemScratchCard(code);

      analytics.trackScratchCardRedeemed(
        amount: result.amount,
        points: result.points,
      );

      // Clear rate limit on success
      await TopUpService.clearRateLimitOnSuccess();

      // Update in-memory cache for TopUp screen
      TopUpService.updateCacheFromSocket(
        newBalance: result.newBalance,
        newTotalPoints: result.newTotalPoints,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success dialog, then go back to home
        _showSuccessDialog(result, l10n);
      }
    } catch (e) {
      analytics.trackScratchCardFailed(error: e.toString());

      // Record failed attempt
      final newStatus = await TopUpService.recordFailedAttempt();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        _showErrorDialog(
          e.toString().replaceAll('Exception: ', ''),
          newStatus,
          l10n,
        );
      }
    }
  }

  void _showLoadingDialog(AppLocalizations? l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          height: 35,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.topUpRedeemCard ?? 'Redeeming...',
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRateLimitDialog(RateLimitStatus status) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 24),
              Text(
                'Too Many Attempts',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
              const SizedBox(height: 12),
              Text(
                'You\'ve entered too many invalid codes. Please try again later.',
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, color: Colors.orange.shade700, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Try again in ${status.lockoutRemainingFormatted}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Understood', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String errorMessage, RateLimitStatus status, AppLocalizations? l10n) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                'Redemption Failed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!status.isLocked && status.remainingAttempts > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: status.remainingAttempts <= 1 ? Colors.red.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: status.remainingAttempts <= 1 ? Colors.red.shade600 : Colors.orange.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${status.remainingAttempts} attempt${status.remainingAttempts == 1 ? '' : 's'} remaining',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: status.remainingAttempts <= 1 ? Colors.red.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else if (status.isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Locked for ${status.lockoutRemainingFormatted}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Reset to allow another scan
                    setState(() {
                      _scannedCode = null;
                      _codeController.clear();
                      _showManualEntry = false;
                    });
                    _scannerController?.start();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    status.isLocked ? 'OK' : 'Try Again',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(TopUpResult result, AppLocalizations? l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScanSuccessDialog(
        result: result,
        l10n: l10n,
        onClose: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to home
        },
      ),
    );
  }

  void _toggleFlash() {
    _scannerController?.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
    HapticFeedback.lightImpact();
  }

  void _toggleManualEntry() {
    setState(() {
      _showManualEntry = !_showManualEntry;
      if (_showManualEntry) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _codeFocusNode.requestFocus();
        });
      } else {
        _codeFocusNode.unfocus();
        // If closing manual entry, clear the scanned code flag and restart scanner
        if (_scannedCode != null) {
          _scannedCode = null;
          _codeController.clear();
          _scannerController?.start();
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Camera view
          if (_isCheckingPermission)
            _buildLoadingView()
          else if (!_hasPermission)
            _buildPermissionDeniedView(l10n)
          else
            _buildScannerView(),

          // Scan overlay
          if (_hasPermission && !_isCheckingPermission)
            _buildScanOverlay(size, scanAreaSize),

          // Top bar
          _buildTopBar(),

          // Bottom panel (hide when manual entry is shown)
          if (_hasPermission && !_isCheckingPermission && !_showManualEntry)
            _buildBottomPanel(l10n),

          // Manual entry panel (shown for manual entry or after QR scan)
          if (_showManualEntry) _buildManualEntryPanel(l10n),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(child: CircularProgressIndicator(color: AppColors.secondary));
  }

  Widget _buildPermissionDeniedView(AppLocalizations? l10n) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              size: 50,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n?.cameraPermissionRequired ?? 'Camera Permission Required',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.cameraPermissionDescription ??
                'We need camera access to scan codes.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(l10n?.openSettings ?? 'Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return MobileScanner(controller: _scannerController!, onDetect: _onDetect);
  }

  Widget _buildScanOverlay(Size size, double scanAreaSize) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanLineAnimation, _pulseAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: _ScanOverlayPainter(
            scanAreaSize: scanAreaSize,
            scanLineProgress: _scanLineAnimation.value,
            pulseScale: _pulseAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            // Logo
            Image.asset(
              'assets/icons/horisental.png',
              height: 28,
              fit: BoxFit.contain,
            ),

            // Flash button
            if (_hasPermission)
              GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isFlashOn
                        ? AppColors.secondary
                        : Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFlashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations? l10n) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instruction
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.pointCameraAtCode ?? 'Point camera at gift card code',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual entry button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _toggleManualEntry,
                icon: Icon(Icons.keyboard_rounded, color: AppColors.secondary),
                label: Text(
                  l10n?.enterCodeManually ?? 'Enter Code Manually',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryPanel(AppLocalizations? l10n) {
    final codeLength = _codeController.text.replaceAll('-', '').length;
    final isComplete = codeLength == 20;
    final isFromScan = _scannedCode != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Scanned badge (show when code came from QR scan)
            if (isFromScan)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'QR Code Scanned!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),

            // Header section with icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Gift card icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFromScan 
                              ? 'Verify & Redeem' 
                              : (l10n?.enterInviteCode ?? 'Enter Redemption Code'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFromScan
                              ? 'Check the code below, then tap Redeem'
                              : '20-character scratch card code',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: _toggleManualEntry,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Code input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Text field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: TextField(
                      controller: _codeController,
                      focusNode: _codeFocusNode,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                        UpperCaseTextFormatter(),
                        _CodeInputFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (isComplete) _onManualSubmit();
                      },
                    ),
                  ),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  
                  // Bottom row: Paste & Counter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Paste button
                        GestureDetector(
                          onTap: _pasteFromClipboard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.content_paste_rounded,
                                  color: AppColors.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Paste',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Clear button
                        if (_codeController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _codeController.clear();
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.backspace_outlined,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                          ),
                        // Character counter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isComplete 
                                ? Colors.green.shade50 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isComplete 
                                  ? Colors.green.shade300 
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isComplete)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green.shade600,
                                    size: 14,
                                  ),
                                ),
                              Text(
                                '$codeLength/20',
                                style: TextStyle(
                                  color: isComplete 
                                      ? Colors.green.shade700 
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Redeem button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isComplete ? _onManualSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete 
                      ? AppColors.secondary 
                      : Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.2),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                  elevation: isComplete ? 4 : 0,
                  shadowColor: AppColors.secondary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isComplete ? Icons.redeem_rounded : Icons.lock_outline_rounded,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isComplete 
                          ? 'Redeem Code' 
                          : '${20 - codeLength} characters remaining',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final cleaned = data!.text!
          .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
          .toUpperCase();
      if (cleaned.isNotEmpty) {
        _codeController.text = _formatCodeWithDashes(cleaned);
        _codeController.selection = TextSelection.fromPosition(
          TextPosition(offset: _codeController.text.length),
        );
        setState(() {});
        HapticFeedback.lightImpact();
      }
    }
  }

  String _formatCodeWithDashes(String code) {
    final clean = code.replaceAll('-', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length && i < 20; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final double scanLineProgress;
  final double pulseScale;

  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.scanLineProgress,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Corner brackets
    final cornerLength = 28.0 * pulseScale;
    final cornerPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left + cornerLength, scanRect.top)
        ..lineTo(scanRect.left + 10, scanRect.top)
        ..arcToPoint(
          Offset(scanRect.left, scanRect.top + 10),
          radius: const Radius.circular(10),
        )
        ..lineTo(scanRect.left, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right - 10, scanRect.top)
        ..arcToPoint(
          Offset(scanRect.right, scanRect.top + 10),
          radius: const Radius.circular(10),
          clockwise: true,
        )
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom - 10)
        ..arcToPoint(
          Offset(scanRect.left + 10, scanRect.bottom),
          radius: const Radius.circular(10),
        )
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.right, scanRect.bottom - 10)
        ..arcToPoint(
          Offset(scanRect.right - 10, scanRect.bottom),
          radius: const Radius.circular(10),
          clockwise: true,
        )
        ..lineTo(scanRect.right - cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Scan line
    final scanLineY = scanRect.top + (scanRect.height * scanLineProgress);
    final scanLinePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.secondary.withValues(alpha: 0.8),
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.8),
              Colors.transparent,
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ).createShader(
            Rect.fromLTWH(
              scanRect.left + 15,
              scanLineY - 2,
              scanRect.width - 30,
              4,
            ),
          );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          scanRect.left + 15,
          scanLineY - 2,
          scanRect.width - 30,
          4,
        ),
        const Radius.circular(2),
      ),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanLineProgress != scanLineProgress ||
        oldDelegate.pulseScale != pulseScale;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Auto-formats code with dashes every 4 characters (XXXX-XXXX-XXXX-XXXX-XXXX)
class _CodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all dashes to get clean input
    final cleanText = newValue.text.replaceAll('-', '');

    // Limit to 20 characters
    final limitedText = cleanText.length > 20
        ? cleanText.substring(0, 20)
        : cleanText;

    // Add dashes every 4 characters
    final buffer = StringBuffer();
    for (int i = 0; i < limitedText.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(limitedText[i]);
    }

    final formattedText = buffer.toString();

    // Calculate new cursor position
    int newCursorPos = newValue.selection.end;

    // Adjust cursor for added dashes
    final oldCleanLength = oldValue.text.replaceAll('-', '').length;
    final newCleanLength = cleanText.length;

    if (newCleanLength > oldCleanLength) {
      // Characters were added
      final cursorCleanPos = newValue.text
          .substring(0, newValue.selection.end)
          .replaceAll('-', '')
          .length;
      newCursorPos = cursorCleanPos + (cursorCleanPos ~/ 4);
      if (cursorCleanPos > 0 &&
          cursorCleanPos % 4 == 0 &&
          cursorCleanPos < 20) {
        newCursorPos++; // Move past the dash
      }
    } else if (newCleanLength < oldCleanLength) {
      // Characters were removed
      final cursorCleanPos = newValue.text
          .substring(0, newValue.selection.end)
          .replaceAll('-', '')
          .length;
      newCursorPos =
          cursorCleanPos + (cursorCleanPos > 0 ? (cursorCleanPos - 1) ~/ 4 : 0);
    }

    // Clamp cursor position
    newCursorPos = newCursorPos.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}

/// Beautiful animated success dialog for scan screen
class _ScanSuccessDialog extends StatefulWidget {
  final TopUpResult result;
  final AppLocalizations? l10n;
  final VoidCallback onClose;

  const _ScanSuccessDialog({
    required this.result,
    required this.l10n,
    required this.onClose,
  });

  @override
  State<_ScanSuccessDialog> createState() => _ScanSuccessDialogState();
}

class _ScanSuccessDialogState extends State<_ScanSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController.forward().then((_) {
      _checkController.forward();
      _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Confetti particles
            ...List.generate(12, (index) {
              return AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  final angle = (index * 30) * (math.pi / 180);
                  final radius = 120 * _confettiController.value;
                  final opacity = (1 - _confettiController.value).clamp(0.0, 1.0);
                  return Positioned(
                    left: 140 + radius * math.cos(angle),
                    top: 80 + radius * math.sin(angle) - (50 * _confettiController.value),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: index % 3 == 0
                              ? AppColors.primary
                              : index % 3 == 1
                                  ? AppColors.secondary
                                  : Colors.amber,
                          shape: index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: index % 2 == 0 ? null : BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Main dialog content
            Container(
              width: 300,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated success icon
                  ScaleTransition(
                    scale: _checkAnimation,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    widget.l10n?.topUpSuccess ?? 'Top Up Successful!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                  const SizedBox(height: 20),

                  // Amount card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${widget.result.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TND', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            Text('Added', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Points earned
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: Colors.amber.shade600, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.result.points} ${widget.l10n?.topUpPointsEarned ?? 'points earned'}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.amber.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${widget.l10n?.topUpNewBalance ?? 'New balance'}: ${NumberFormatter.formatBalance(widget.result.newBalance)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // OK button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: AppColors.secondary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.celebration_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.l10n?.ok ?? 'OK',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
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
