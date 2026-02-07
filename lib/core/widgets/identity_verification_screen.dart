import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Result returned from verification screen
class VerificationResult {
  final String? sessionId;
  final String? status;
  final bool cancelled;

  VerificationResult({this.sessionId, this.status, this.cancelled = false});

  bool get isApproved => status == 'Approved';
  bool get isDeclined => status == 'Declined';
  bool get isInReview => status == 'In Review';
}

/// WebView screen for Didit identity verification
class IdentityVerificationScreen extends StatefulWidget {
  final String verificationUrl;
  final String? callbackScheme;

  const IdentityVerificationScreen({
    super.key,
    required this.verificationUrl,
    this.callbackScheme = 'cha9cha9ni',
  });

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  void _setupWebView() {
    // Validate URL before setting up WebView
    if (widget.verificationUrl.isEmpty ||
        !widget.verificationUrl.startsWith('http')) {
      debugPrint('Invalid verification URL: ${widget.verificationUrl}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Invalid verification URL received. Please try again later.';
            _isLoading = false;
          });
        }
      });
      return;
    }

    // Configure platform-specific parameters
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigating to: ${request.url}');

            // Check for callback URL (both deep link and regular callback)
            if (request.url.startsWith('${widget.callbackScheme}://') ||
                request.url.contains('verification-complete')) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            // Only show error for main frame
            if (error.isForMainFrame ?? false) {
              if (mounted) {
                setState(() {
                  _errorMessage = error.description;
                  _isLoading = false;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.verificationUrl));

    // Handle permissions
    final platformController = _controller.platform;
    if (platformController is WebKitWebViewController) {
      // iOS-specific: request permissions
    }

    // Android-specific configuration
    if (platformController is AndroidWebViewController) {
      platformController.setMediaPlaybackRequiresUserGesture(false);

      // Handle permission requests for camera
      platformController.setOnPlatformPermissionRequest((request) {
        debugPrint('Permission requested: ${request.types}');
        request.grant();
      });
    }
  }

  void _handleCallback(String callbackUrl) {
    final uri = Uri.parse(callbackUrl);
    final sessionId =
        uri.queryParameters['verificationSessionId'] ??
        uri.queryParameters['session_id'];
    final status = uri.queryParameters['status'];

    debugPrint(
      'Verification callback - sessionId: $sessionId, status: $status',
    );

    Navigator.of(
      context,
    ).pop(VerificationResult(sessionId: sessionId, status: status));
  }

  void _handleCancel() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
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
                        Colors.orange.withOpacity(0.15),
                        Colors.amber.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause_circle_outline_rounded,
                    size: 36,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                const Text(
                  'Leave Verification?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  'Your progress will be saved. You can continue verification later from where you left off.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sessions expire after 7 days',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext); // Close dialog first
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                Navigator.of(context).pop(VerificationResult(cancelled: true));
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Leave',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isRTL = locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom header like help screen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleCancel,
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
                        isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    l10n.verifyIdentity,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // WebView content
            Expanded(
              child: Stack(
                children: [
                  if (_errorMessage != null)
                    _buildErrorWidget()
                  else
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: WebViewWidget(controller: _controller),
                    ),

                  if (_isLoading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.loading,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
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

  Widget _buildErrorWidget() {
    final l10n = AppLocalizations.of(context)!;
    final bool isInvalidUrl =
        widget.verificationUrl.isEmpty ||
        !widget.verificationUrl.startsWith('http');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Verification Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isInvalidUrl)
              // Go back button for invalid URL
              OutlinedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(VerificationResult(cancelled: true)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: Text(l10n.back),
              )
            else
              // Retry button for network errors
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _controller.loadRequest(Uri.parse(widget.verificationUrl));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  l10n.tryAgain,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
