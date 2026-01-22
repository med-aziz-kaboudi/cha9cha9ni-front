import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

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
          _scannedCode = barcode.rawValue;
        });
        HapticFeedback.mediumImpact();
        _processCode(barcode.rawValue!);
        break;
      }
    }
  }

  void _processCode(String code) {
    _scannerController?.stop();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop(code);
    });
  }

  void _onManualSubmit() {
    final code = _codeController.text.trim().toUpperCase().replaceAll('-', '');
    if (code.isEmpty) return;
    
    if (code.length < 6 || !RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.invalidCodeFormat ?? 'Invalid code'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(code);
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
          
          // Bottom panel
          if (_hasPermission && !_isCheckingPermission && !_showManualEntry)
            _buildBottomPanel(l10n),
          
          // Manual entry
          if (_showManualEntry)
            _buildManualEntryPanel(l10n),
          
          // Success
          if (_scannedCode != null)
            _buildSuccessOverlay(l10n),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.secondary),
    );
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
            child: Icon(Icons.camera_alt_rounded, size: 50, color: AppColors.secondary),
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
            l10n?.cameraPermissionDescription ?? 'We need camera access to scan codes.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: Text(l10n?.openSettings ?? 'Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return MobileScanner(
      controller: _scannerController!,
      onDetect: _onDetect,
    );
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
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
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
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
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
                  Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary, size: 22),
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
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryPanel(AppLocalizations? l10n) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.enterInviteCode ?? 'Enter Redemption Code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleManualEntry,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
                decoration: InputDecoration(
                  hintText: 'XXXX-XXXX-XXXX',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 20,
                    letterSpacing: 3,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                  UpperCaseTextFormatter(),
                ],
                onSubmitted: (_) => _onManualSubmit(),
              ),
            ),
            const SizedBox(height: 14),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onManualSubmit,
                icon: const Icon(Icons.redeem_rounded, size: 20),
                label: Text(
                  l10n?.joinFamily ?? 'Redeem',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(AppLocalizations? l10n) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.codeScanned ?? 'Code Scanned!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
    final scanRect = Rect.fromCenter(center: center, width: scanAreaSize, height: scanAreaSize);

    // Dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = Colors.black.withValues(alpha: 0.6));

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
        ..arcToPoint(Offset(scanRect.left, scanRect.top + 10), radius: const Radius.circular(10))
        ..lineTo(scanRect.left, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right - 10, scanRect.top)
        ..arcToPoint(Offset(scanRect.right, scanRect.top + 10), radius: const Radius.circular(10), clockwise: true)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom - 10)
        ..arcToPoint(Offset(scanRect.left + 10, scanRect.bottom), radius: const Radius.circular(10))
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.right, scanRect.bottom - 10)
        ..arcToPoint(Offset(scanRect.right - 10, scanRect.bottom), radius: const Radius.circular(10), clockwise: true)
        ..lineTo(scanRect.right - cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Scan line
    final scanLineY = scanRect.top + (scanRect.height * scanLineProgress);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.secondary.withValues(alpha: 0.8),
          AppColors.secondary,
          AppColors.secondary.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(scanRect.left + 15, scanLineY - 2, scanRect.width - 30, 4));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(scanRect.left + 15, scanLineY - 2, scanRect.width - 30, 4),
        const Radius.circular(2),
      ),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanLineProgress != scanLineProgress || oldDelegate.pulseScale != pulseScale;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
