import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class TawkToChatScreen extends StatefulWidget {
  const TawkToChatScreen({super.key});

  @override
  State<TawkToChatScreen> createState() => _TawkToChatScreenState();
}

class _TawkToChatScreenState extends State<TawkToChatScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // Tawk.to direct chat URL - this opens the chat widget directly
  static const String _tawkToChatUrl = 'https://tawk.to/chat/697bb33b28cc321c33eda5aa/1jg5j88km';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Use platform-specific parameters for iOS/macOS to handle auth challenges
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS || Platform.isMacOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            // Inject script to prevent links from opening in external browser
            _injectLinkInterceptor();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            request.onCancel();
          },
          onUrlChange: (UrlChange change) {
            final url = change.url?.toLowerCase() ?? '';
            debugPrint('URL changed to: $url');
            
            // If navigated away from tawk.to, go back to chat
            if (!url.contains('tawk.to') && 
                !url.contains('challenges.cloudflare.com') &&
                !url.startsWith('about:') &&
                !url.startsWith('data:')) {
              debugPrint('Detected navigation away, returning to chat');
              _controller.loadRequest(Uri.parse(_tawkToChatUrl));
            }
          },
          // Block navigation away from the chat
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            
            // Allow tawk.to chat and related resources
            if (url.contains('tawk.to') || 
                url.contains('va.tawk.to') ||
                url.startsWith('about:') ||
                url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            
            // Allow Cloudflare Turnstile challenges (required for captcha)
            if (url.contains('challenges.cloudflare.com') ||
                url.contains('turnstile')) {
              return NavigationDecision.navigate;
            }
            
            // Block navigation to external sites (like tawk.to homepage, login, etc)
            debugPrint('Blocked navigation to: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_tawkToChatUrl));

    // No additional iOS/macOS handling needed - using JS injection instead
  }

  /// Inject JavaScript to intercept and block external link navigation
  void _injectLinkInterceptor() {
    _controller.runJavaScript('''
      (function() {
        // Override window.open to prevent popups
        window.open = function(url, target, features) {
          console.log('Blocked window.open:', url);
          return null;
        };
        
        // Intercept clicks on links with target="_blank"
        document.addEventListener('click', function(e) {
          var target = e.target;
          while (target && target.tagName !== 'A') {
            target = target.parentElement;
          }
          if (target && target.tagName === 'A') {
            var href = target.href || '';
            var linkTarget = target.target || '';
            
            // Allow tawk.to and Cloudflare Turnstile URLs
            if (href.indexOf('tawk.to') !== -1 || 
                href.indexOf('challenges.cloudflare.com') !== -1 ||
                href.indexOf('turnstile') !== -1) {
              return; // Allow these
            }
            
            // Block external links
            if (linkTarget === '_blank' || 
                (href && href.indexOf('tawk.to') === -1)) {
              console.log('Blocked link click:', href);
              e.preventDefault();
              e.stopPropagation();
            }
          }
        }, true);
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.gray,
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
              _buildAppBar(l10n),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(l10n)
                    : _buildWebView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    final isRTL = locale.languageCode == 'ar';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
                isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            l10n.help,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                color: AppColors.secondary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.loading,
            style: TextStyle(
              color: AppColors.secondary.withValues(alpha: 0.8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
