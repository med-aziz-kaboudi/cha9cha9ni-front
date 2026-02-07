import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/identity_verification_service.dart';
import '../../../core/widgets/identity_verification_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../pack_models.dart';
import '../pack_service.dart';
import 'aid_selection_screen.dart';
import 'all_packs_screen.dart';

/// Screen showing user's current subscription pack details
class CurrentPackScreen extends StatefulWidget {
  const CurrentPackScreen({super.key});

  @override
  State<CurrentPackScreen> createState() => _CurrentPackScreenState();
}

class _CurrentPackScreenState extends State<CurrentPackScreen> {
  final _packService = PackService();

  CurrentPackData? _packData;
  bool _isLoading = true;
  String? _error;
  bool _withdrawAccessExpanded = false;

  StreamSubscription<CurrentPackData>? _dataSubscription;
  StreamSubscription<FamilyAdsStats>? _adsSubscription;

  // Rate limiting for refresh
  DateTime? _lastRefreshTime;
  static const _refreshCooldown = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _packService.initialize();
    _loadData();
    _listenToUpdates();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _adsSubscription?.cancel();
    super.dispose();
  }

  void _listenToUpdates() {
    _dataSubscription = _packService.dataStream.listen((data) {
      debugPrint('📱 CurrentPackScreen: Received dataStream update');
      if (mounted) {
        setState(() {
          _packData = data;
        });
      }
    });

    _adsSubscription = _packService.adsStatsStream.listen((stats) {
      debugPrint(
        '📱 CurrentPackScreen: Received adsStats update - userAdsToday: ${stats.userAdsToday}, familyTotal: ${stats.familyTotalAdsToday}',
      );
      if (mounted && _packData != null) {
        setState(() {
          _packData = CurrentPackData(
            pack: _packData!.pack,
            subscription: _packData!.subscription,
            currentFamilyMembers: _packData!.currentFamilyMembers,
            maxFamilyMembers: _packData!.maxFamilyMembers,
            withdrawAccess: _packData!.withdrawAccess,
            selectedAids: _packData!.selectedAids,
            allAids: _packData!.allAids,
            adsStats: stats,
          );
        });
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    // Rate limit refresh requests
    if (forceRefresh && _lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _refreshCooldown) {
        final remainingSeconds =
            (_refreshCooldown - timeSinceLastRefresh).inSeconds;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait $remainingSeconds seconds before refreshing again',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _packService.fetchCurrentPack(
        forceRefresh: forceRefresh,
      );
      if (forceRefresh) {
        _lastRefreshTime = DateTime.now();
      }
      if (mounted) {
        setState(() {
          _packData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Start identity verification flow
  Future<void> _startIdentityVerification() async {
    try {
      // First check current verification status
      final status =
          await IdentityVerificationService().getVerificationStatus();

      // If already verified, no need to continue
      if (status.isVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already verified!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadData(forceRefresh: true);
        }
        return;
      }

      // If verification is under review, show status (can't continue)
      if (status.statusEnum == VerificationStatus.inReview) {
        if (mounted) {
          _showVerificationStatusDialog(status);
        }
        return;
      }

      // Start or resume verification session (works for in_progress too)
      final response = await IdentityVerificationService().startVerification();
      if (mounted) {
        final result = await Navigator.push<VerificationResult>(
          context,
          MaterialPageRoute(
            builder: (context) => IdentityVerificationScreen(
              verificationUrl: response.verificationUrl,
            ),
          ),
        );

        // Reload pack data after verification attempt to update KYC status
        if (result != null && !result.cancelled) {
          await _loadData(forceRefresh: true);

          // Check the final status after verification
          final newStatus = await IdentityVerificationService().checkSession(
            sessionId: response.sessionId,
          );

          if (mounted) {
            _showVerificationStatusDialog(newStatus);
          }
        }
      }
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      // Check if it's an "under review" error from backend
      if (errorMsg.toLowerCase().contains('under review') || 
          errorMsg.toLowerCase().contains('in review')) {
        // Re-check status and show the review dialog
        try {
          final status = await IdentityVerificationService().getVerificationStatus();
          if (mounted) {
            _showVerificationStatusDialog(status);
          }
        } catch (_) {
          // Fallback: show a styled dialog
          if (mounted) {
            _showFallbackReviewDialog();
          }
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start verification: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFallbackReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded, size: 40, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Submitted for Review',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'re on it!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3B82F6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your documents have been submitted and are being reviewed by our team. This usually takes just a few minutes.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'ll receive an email when the review is complete.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
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
                    'Got it',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showVerificationStatusDialog(VerificationStatusResponse status) {
    IconData icon;
    Color color;
    Color bgColor;
    String title;
    String message;
    String? subtitle;
    bool showRetryButton = false;

    switch (status.statusEnum) {
      case VerificationStatus.approved:
        icon = Icons.verified_rounded;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        title = 'Identity Verified! 🎉';
        subtitle = 'Welcome to the verified community';
        message = 'Your identity has been verified successfully. You now have full access to all withdrawal features.';
        break;
      case VerificationStatus.inProgress:
        icon = Icons.hourglass_top_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        title = 'Verification In Progress';
        subtitle = 'Almost there!';
        message = 'Please complete the verification steps in the verification portal to continue.';
        break;
      case VerificationStatus.inReview:
        icon = Icons.schedule_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        title = 'Submitted for Review';
        subtitle = 'We\'re on it!';
        message = 'Your documents have been submitted and are being reviewed by our team. This usually takes just a few minutes.';
        break;
      case VerificationStatus.declined:
        icon = Icons.error_rounded;
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        title = 'Verification Declined';
        subtitle = 'Don\'t worry, you can try again';
        message = 'Your verification couldn\'t be approved. This might be due to unclear photos or document issues. Please try again with clearer images.';
        showRetryButton = true;
        break;
      case VerificationStatus.expired:
        icon = Icons.timer_off_rounded;
        color = const Color(0xFF6B7280);
        bgColor = const Color(0xFFF3F4F6);
        title = 'Session Expired';
        subtitle = 'Your session has timed out';
        message = 'Your verification session has expired. Please start a new verification to continue.';
        showRetryButton = true;
        break;
      default:
        return; // Don't show dialog for not_started or abandoned
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              // Info box for in_review
              if (status.statusEnum == VerificationStatus.inReview) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You\'ll receive an email when the review is complete.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Buttons
              if (showRetryButton) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Later', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _startIdentityVerification();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status.statusEnum == VerificationStatus.approved 
                          ? const Color(0xFF10B981) 
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      status.statusEnum == VerificationStatus.approved ? 'Awesome!' : 'Got it',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for verification status UI
  Color _getVerificationCardColor(String? status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'in_review':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      case 'expired':
      case 'abandoned':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getVerificationIcon(String? status) {
    switch (status) {
      case 'in_progress':
        return Icons.hourglass_top;
      case 'in_review':
        return Icons.pending;
      case 'declined':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      case 'abandoned':
        return Icons.exit_to_app;
      default:
        return Icons.info_outline;
    }
  }

  String _getVerificationMessage(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'in_progress':
        return 'Verification in progress. Tap to continue where you left off.';
      case 'in_review':
        return 'Your verification is under review. We\'ll notify you once complete.';
      case 'declined':
        return 'Verification was declined. Please try again with valid documents.';
      case 'expired':
        return 'Your verification session expired. Please start a new verification.';
      case 'abandoned':
        return 'Your previous session was abandoned. Start a new verification.';
      default:
        return l10n.verifyIdentityDescription;
    }
  }

  bool _getVerificationButtonEnabled(String? status) {
    // Button is disabled only when verification is in_review (waiting for manual review)
    return status != 'in_review';
  }

  Color _getVerificationButtonColor(String? status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'declined':
      case 'expired':
      case 'abandoned':
        return Colors.red.shade600;
      default:
        return AppColors.primary;
    }
  }

  IconData _getVerificationButtonIcon(String? status) {
    switch (status) {
      case 'in_progress':
        return Icons.play_arrow;
      case 'in_review':
        return Icons.hourglass_top;
      case 'declined':
      case 'expired':
      case 'abandoned':
        return Icons.refresh;
      default:
        return Icons.verified_user_outlined;
    }
  }

  String _getVerificationButtonText(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'in_progress':
        return 'Continue Verification';
      case 'in_review':
        return 'Under Review...';
      case 'declined':
      case 'expired':
      case 'abandoned':
        return 'Retry Verification';
      default:
        return l10n.verifyIdentity;
    }
  }

  String _getPackImage(String packName) {
    switch (packName) {
      case 'plus':
        return 'assets/images/plus.png';
      case 'pro':
        return 'assets/images/pro.png';
      case 'premium':
        return 'assets/images/premium.png';
      default:
        return 'assets/images/free.png';
    }
  }

  Color _getPackColor(String packName) {
    switch (packName) {
      case 'plus':
        return const Color(0xFF6366F1); // Indigo
      case 'pro':
        return const Color(0xFFF59E0B); // Amber
      case 'premium':
        return const Color(0xFFEC4899); // Pink
      default:
        return AppColors.secondary; // Teal
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              _buildAppBar(l10n, isRTL),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      )
                    : _error != null
                    ? _buildError()
                    : _buildContent(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n, bool isRTL) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            l10n.yourCurrentPack,
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_packData == null) return const SizedBox();

    final isOwner = _packData!.withdrawAccess.isOwner;

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Read-only banner for non-owners
            if (!isOwner) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.viewOnlyPackInfo,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pack Card
            _buildPackCard(l10n, isOwner),

            const SizedBox(height: 24),

            // Usage and Limits Section
            Text(
              l10n.usageAndLimits,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            // Family Members
            _buildInfoTile(
              icon: Icons.people_rounded,
              iconColor: AppColors.primary,
              title: l10n.familyMembers,
              subtitle: l10n.ownerPlusMembers(_packData!.maxFamilyMembers - 1),
              trailing:
                  '${_packData!.currentFamilyMembers} / ${_packData!.maxFamilyMembers}',
              onTap: null,
            ),

            const SizedBox(height: 8),

            // Withdraw Access
            _buildWithdrawAccessTile(l10n),

            const SizedBox(height: 8),

            // Selected Aid
            _buildSelectedAidTile(l10n, isOwner),

            const SizedBox(height: 8),

            // Ads Today
            _buildAdsTile(l10n),

            const SizedBox(height: 16),

            // Upgrade Prompt (only for owner)
            if (isOwner) _buildUpgradePrompt(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPackCard(AppLocalizations l10n, bool isOwner) {
    final pack = _packData!.pack;
    final packColor = _getPackColor(pack.name);

    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.42; // 42% of screen width
    final rightPadding = screenWidth * 0.38; // Space for image

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: packColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pack Header with Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background gradient container
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, 24, rightPadding, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      packColor.withOpacity(0.08),
                      packColor.withOpacity(0.18),
                      packColor.withOpacity(0.12),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pack Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: packColor,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: packColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        pack.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Price
                    Text(
                      pack.isFree
                          ? l10n.free
                          : '${pack.priceMonthly.toInt()} DT / ${l10n.month}',
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Withdrawals
                    Text(
                      l10n.withdrawalsPerYear(pack.withdrawalsPerYear),
                      style: TextStyle(
                        color: AppColors.dark.withOpacity(0.55),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Pack Image - larger and touching the edge
              Positioned(
                right: -10,
                top: -5,
                bottom: 0,
                child: SizedBox(
                  width: imageWidth,
                  child: Image.asset(
                    _getPackImage(pack.name),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),

              // Checkmark badge - top right
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Change Pack Button (owner only)
          if (isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllPacksScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dark,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: packColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.changeMyPack,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String? trailing,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.dark.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (showArrow && onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.chevron_right, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawAccessTile(AppLocalizations l10n) {
    final withdrawAccess = _packData!.withdrawAccess;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Main tile
          InkWell(
            onTap: () {
              setState(() {
                _withdrawAccessExpanded = !_withdrawAccessExpanded;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.withdrawAccess,
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.ownerOnlyCanWithdraw,
                          style: TextStyle(
                            color: AppColors.dark.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _withdrawAccessExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_withdrawAccessExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          withdrawAccess.isOwner
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 16,
                          color: withdrawAccess.isOwner
                              ? Colors.green
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            withdrawAccess.isOwner
                                ? l10n.youAreOwner
                                : l10n.onlyOwnerCanWithdrawDescription,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (withdrawAccess.isOwner) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            withdrawAccess.isKycVerified
                                ? Icons.verified_user
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: withdrawAccess.isKycVerified
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              withdrawAccess.isKycVerified
                                  ? l10n.kycVerified
                                  : l10n.kycRequired,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: withdrawAccess.isKycVerified
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!withdrawAccess.isKycVerified) ...[
                        const SizedBox(height: 16),
                        // Verification info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getVerificationCardColor(
                              withdrawAccess.kycStatus,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getVerificationCardColor(
                                withdrawAccess.kycStatus,
                              ).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getVerificationIcon(withdrawAccess.kycStatus),
                                color: _getVerificationCardColor(
                                  withdrawAccess.kycStatus,
                                ),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _getVerificationMessage(
                                    withdrawAccess.kycStatus,
                                    l10n,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getVerificationCardColor(
                                      withdrawAccess.kycStatus,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _getVerificationButtonEnabled(
                                  withdrawAccess.kycStatus,
                                )
                                ? _startIdentityVerification
                                : null,
                            icon: Icon(
                              _getVerificationButtonIcon(
                                withdrawAccess.kycStatus,
                              ),
                              size: 18,
                            ),
                            label: Text(
                              _getVerificationButtonText(
                                withdrawAccess.kycStatus,
                                l10n,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getVerificationButtonColor(
                                withdrawAccess.kycStatus,
                              ),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedAidTile(AppLocalizations l10n, bool isOwner) {
    final selectedAids = _packData!.selectedAids;
    final maxAids = _packData!.pack.maxAidsSelectable;
    final hasAid = selectedAids.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isOwner
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AidSelectionScreen(
                      allAids: _packData!.allAids,
                      selectedAids: _packData!.selectedAids,
                      maxAidsSelectable: _packData!.pack.maxAidsSelectable,
                    ),
                  ),
                ).then((_) => _loadData());
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectedAid,
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (hasAid)
                          Text(
                            '${selectedAids.first.aidDisplayName} - ${l10n.maxDT(selectedAids.first.maxWithdrawal)}',
                            style: TextStyle(
                              color: AppColors.dark.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            isOwner ? l10n.selectAnAid : l10n.noAidSelected,
                            style: TextStyle(
                              color: isOwner ? AppColors.primary : Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${selectedAids.length} / $maxAids',
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isOwner)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                ],
              ),

              if (hasAid) ...[
                const SizedBox(height: 8),
                Text(
                  'window: ${_getAidWindow(selectedAids.first)}',
                  style: TextStyle(
                    color: AppColors.dark.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAidWindow(SelectedAidModel aid) {
    return aid.getWithdrawalWindowDisplay();
  }

  Widget _buildAdsTile(AppLocalizations l10n) {
    final stats = _packData!.adsStats;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adsToday,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.adsPerMember(5),
                      style: TextStyle(
                        color: AppColors.dark.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${stats.familyTotalAdsToday} / ${stats.familyMaxAdsToday} ',
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: l10n.watched,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress Bar - shows user's personal ads progress
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: LinearProgressIndicator(
                    value: stats.userProgress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.secondary.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondary,
                    ),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${stats.userAdsToday} / ${stats.userMaxAds}',
                style: TextStyle(
                  color: AppColors.secondary.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            l10n.adsDescription,
            style: TextStyle(
              color: AppColors.dark.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(AppLocalizations l10n) {
    if (_packData!.pack.isPremium) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFEF3C7),
            const Color(0xFFFDE68A).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.unlockMoreBenefits,
              style: TextStyle(
                color: AppColors.dark.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: const Color(0xFFF59E0B).withOpacity(0.7),
            size: 16,
          ),
        ],
      ),
    );
  }
}
