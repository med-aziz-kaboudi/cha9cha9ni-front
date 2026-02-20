import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/identity_verification_service.dart';
import '../../../core/widgets/identity_verification_screen.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../pack_models.dart';
import '../pack_service.dart';
import 'aid_selection_screen.dart';
import 'all_packs_screen.dart';

/// Withdraw screen — guides unverified users, shows full withdrawal dashboard for verified ones
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen>
    with SingleTickerProviderStateMixin {
  final _packService = PackService();

  CurrentPackData? _packData;
  bool _isLoading = true;
  String? _error;

  StreamSubscription<CurrentPackData>? _dataSubscription;

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
    super.dispose();
  }

  void _listenToUpdates() {
    _dataSubscription = _packService.dataStream.listen((data) {
      if (mounted) {
        setState(() => _packData = data);
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
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
      if (forceRefresh) _lastRefreshTime = DateTime.now();
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
                    ? _buildSkeletonLoading()
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
            l10n.withdraw,
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
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      child: SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status overview card skeleton
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 160,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // "Withdrawal Quota" title skeleton
            Container(
              width: 130,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Quota card skeleton
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 170,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // "Your Selected Aids" title skeleton
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Aid card skeleton
            ...List.generate(2, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 80,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSkeletonDetailRow(),
                          const SizedBox(height: 12),
                          _buildSkeletonDetailRow(),
                          const SizedBox(height: 12),
                          _buildSkeletonDetailRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 12),

            // Button skeleton
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            const SizedBox(height: 20),

            // Pack info skeleton
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 120,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
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

  Widget _buildSkeletonDetailRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 80,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_packData == null) return const SizedBox();

    final withdrawAccess = _packData!.withdrawAccess;

    // Not verified → show guide
    if (!withdrawAccess.isKycVerified) {
      return _buildUnverifiedGuide(l10n, withdrawAccess);
    }

    // Verified → show withdrawal dashboard
    return _buildWithdrawalDashboard(l10n);
  }

  // ─────────────────────────────────────────────────────
  // UNVERIFIED: Guide Screen
  // ─────────────────────────────────────────────────────

  Widget _buildUnverifiedGuide(
    AppLocalizations l10n,
    WithdrawAccessInfo withdrawAccess,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Shield icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 48,
              color: Color(0xFFF59E0B),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            l10n.withdrawVerifyTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            l10n.withdrawVerifySubtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withOpacity(0.5),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Steps
          _buildStepCard(
            number: '1',
            icon: Icons.badge_outlined,
            title: l10n.withdrawStep1Title,
            subtitle: l10n.withdrawStep1Desc,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            number: '2',
            icon: Icons.schedule_rounded,
            title: l10n.withdrawStep2Title,
            subtitle: l10n.withdrawStep2Desc,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            number: '3',
            icon: Icons.account_balance_wallet_rounded,
            title: l10n.withdrawStep3Title,
            subtitle: l10n.withdrawStep3Desc,
            color: const Color(0xFF10B981),
          ),

          const SizedBox(height: 32),

          // Current status card (if in progress/review/declined)
          if (withdrawAccess.kycStatus != null &&
              withdrawAccess.kycStatus != 'not_started')
            _buildVerificationStatusCard(withdrawAccess.kycStatus!),

          if (withdrawAccess.kycStatus != null &&
              withdrawAccess.kycStatus != 'not_started')
            const SizedBox(height: 20),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _getVerificationButtonEnabled(withdrawAccess.kycStatus)
                  ? _startIdentityVerification
                  : null,
              icon: Icon(
                _getVerificationButtonIcon(withdrawAccess.kycStatus),
                size: 20,
              ),
              label: Text(
                _getVerificationButtonText(withdrawAccess.kycStatus, l10n),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getVerificationButtonColor(
                  withdrawAccess.kycStatus,
                ),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark.withOpacity(0.5),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusCard(String status) {
    final color = _getVerificationCardColor(status);
    final icon = _getVerificationIcon(status);

    String message;
    switch (status) {
      case 'in_progress':
        message = 'Your verification is in progress. Tap below to continue.';
        break;
      case 'in_review':
        message =
            'Your documents are under review. We\'ll notify you once complete.';
        break;
      case 'declined':
        message =
            'Your verification was declined. Please try again with valid documents.';
        break;
      case 'expired':
        message = 'Your session expired. Please start a new verification.';
        break;
      default:
        message = 'Start your identity verification to enable withdrawals.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // VERIFIED: Withdrawal Dashboard
  // ─────────────────────────────────────────────────────

  Widget _buildWithdrawalDashboard(AppLocalizations l10n) {
    final pack = _packData!.pack;
    final sub = _packData!.subscription;
    final selectedAids = _packData!.selectedAids;
    final isYearly = sub.billingCycle == 'yearly';

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status overview card ──
            _buildStatusOverview(l10n, pack, sub),

            const SizedBox(height: 20),

            // ── Withdrawal Quota ──
            Text(
              l10n.withdrawalQuota,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuotaCard(l10n, sub, pack),

            const SizedBox(height: 20),

            // ── Selected Aids / Withdrawal Details ──
            Text(
              l10n.withdrawalDetails,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            if (selectedAids.isEmpty)
              _buildNoAidSelected(l10n)
            else
              ...selectedAids.map(
                (aid) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAidCard(l10n, aid, pack, isYearly),
                ),
              ),

            const SizedBox(height: 12),

            // ── Select/Change Aid button ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AidSelectionScreen(
                        allAids: _packData!.allAids,
                        selectedAids: _packData!.selectedAids,
                        maxAidsSelectable: pack.maxAidsSelectable,
                      ),
                    ),
                  ).then((_) => _loadData());
                },
                icon: Icon(
                  selectedAids.isEmpty
                      ? Icons.add_circle_outline
                      : Icons.swap_horiz_rounded,
                  size: 20,
                ),
                label: Text(
                  selectedAids.isEmpty
                      ? l10n.selectAnAid
                      : l10n.changeAid,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(
                    color: AppColors.secondary.withOpacity(0.4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Pack info ──
            _buildPackInfoRow(l10n, pack),

            // ── Upgrade prompt for non-premium ──
            if (!pack.isPremium) ...[
              const SizedBox(height: 16),
              _buildUpgradePrompt(l10n),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverview(
    AppLocalizations l10n,
    PackModel pack,
    SubscriptionInfo sub,
  ) {
    final packColor = _getPackColor(pack.name);
    final isYearly = sub.billingCycle == 'yearly';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            packColor.withOpacity(0.08),
            packColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: packColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: packColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.withdrawReady,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pack.displayName} • ${isYearly ? l10n.yearly : l10n.monthly}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: packColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaCard(
    AppLocalizations l10n,
    SubscriptionInfo sub,
    PackModel pack,
  ) {
    final used = sub.withdrawalsUsed;
    final total = pack.withdrawalsPerYear;
    final remaining = sub.withdrawalsRemaining;
    final progress = total > 0 ? used / total : 0.0;

    final isExhausted = remaining <= 0;
    final progressColor = isExhausted
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.withdrawalsThisYear,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$used / $total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),  

          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: progressColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 12),

          // Remaining text
          Row(
            children: [
              Icon(
                isExhausted
                    ? Icons.block_rounded
                    : Icons.check_circle_outline,
                size: 16,
                color: isExhausted
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Text(
                isExhausted
                    ? l10n.noWithdrawalsLeft
                    : l10n.withdrawalsRemaining(remaining),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isExhausted
                      ? const Color(0xFFEF4444)
                      : AppColors.dark.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAidSelected(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: 40,
            color: AppColors.secondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noAidSelectedYet,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.noAidSelectedDesc,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withOpacity(0.5),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAidCard(
    AppLocalizations l10n,
    SelectedAidModel aid,
    PackModel pack,
    bool isYearly,
  ) {
    final isWithdrawn = aid.isWithdrawn;
    final isExpired = aid.isExpired;
    final inWindow = aid.isWithinWithdrawalWindow;

    // Status colors
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isWithdrawn) {
      statusColor = const Color(0xFF10B981);
      statusText = l10n.withdrawn;
      statusIcon = Icons.check_circle;
    } else if (isExpired) {
      statusColor = const Color(0xFF6B7280);
      statusText = l10n.expired;
      statusIcon = Icons.timer_off_rounded;
    } else if (inWindow) {
      statusColor = const Color(0xFF10B981);
      statusText = l10n.withdrawWindowOpen;
      statusIcon = Icons.lock_open_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusText = l10n.upcoming;
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Aid name + status badge
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aid.aidDisplayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    if (isWithdrawn && aid.withdrawnAt != null)
                      Text(
                        '${l10n.withdrawnOn} ${_formatDate(aid.withdrawnAt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark.withOpacity(0.4),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Max amount
                _buildDetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.maxWithdrawal,
                  value: isWithdrawn
                      ? '${aid.withdrawnAmount ?? aid.maxWithdrawal} DT'
                      : '${aid.maxWithdrawal} DT',
                  valueColor: isWithdrawn
                      ? const Color(0xFF10B981)
                      : AppColors.dark,
                  isBold: true,
                ),
                _buildDivider(),

                // Withdrawal window
                _buildDetailRow(
                  icon: Icons.date_range_rounded,
                  label: l10n.withdrawalWindow,
                  value: aid.getWithdrawalWindowDisplay(),
                  valueColor: inWindow && !isWithdrawn && !isExpired
                      ? const Color(0xFF10B981)
                      : AppColors.dark.withOpacity(0.7),
                ),
                _buildDivider(),

                // Aid dates
                if (aid.aidStart != null)
                  _buildDetailRow(
                    icon: Icons.celebration_rounded,
                    label: l10n.aidDates,
                    value: _formatDateRange(aid.aidStart, aid.aidEnd),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.dark.withOpacity(0.4)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? AppColors.dark.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.dark.withOpacity(0.06),
    );
  }

  Widget _buildPackInfoRow(AppLocalizations l10n, PackModel pack) {
    final packColor = _getPackColor(pack.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: packColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: packColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.displayName,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.withdrawalsPerYear(pack.withdrawalsPerYear),
                  style: TextStyle(
                    color: AppColors.dark.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllPacksScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: packColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.viewPacks,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: packColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllPacksScreen()),
        );
      },
      child: Container(
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Helpers (verification)
  // ─────────────────────────────────────────────────────

  Future<void> _startIdentityVerification() async {
    try {
      final status =
          await IdentityVerificationService().getVerificationStatus();

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

      if (status.statusEnum == VerificationStatus.inReview) {
        if (mounted) _showVerificationStatusDialog(status);
        return;
      }

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

        if (result != null && !result.cancelled) {
          await _loadData(forceRefresh: true);
          final newStatus = await IdentityVerificationService().checkSession(
            sessionId: response.sessionId,
          );
          if (mounted) _showVerificationStatusDialog(newStatus);
        }
      }
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (errorMsg.toLowerCase().contains('under review') ||
          errorMsg.toLowerCase().contains('in review')) {
        try {
          final status =
              await IdentityVerificationService().getVerificationStatus();
          if (mounted) _showVerificationStatusDialog(status);
        } catch (_) {}
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
        title = 'Identity Verified!';
        subtitle = 'Welcome to the verified community';
        message =
            'Your identity has been verified successfully. You now have full access to all withdrawal features.';
        break;
      case VerificationStatus.inProgress:
        icon = Icons.hourglass_top_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        title = 'Verification In Progress';
        subtitle = 'Almost there!';
        message =
            'Please complete the verification steps in the verification portal to continue.';
        break;
      case VerificationStatus.inReview:
        icon = Icons.schedule_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        title = 'Submitted for Review';
        subtitle = 'We\'re on it!';
        message =
            'Your documents have been submitted and are being reviewed by our team. This usually takes just a few minutes.';
        break;
      case VerificationStatus.declined:
        icon = Icons.error_rounded;
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        title = 'Verification Declined';
        subtitle = 'Don\'t worry, you can try again';
        message =
            'Your verification couldn\'t be approved. This might be due to unclear photos or document issues. Please try again with clearer images.';
        showRetryButton = true;
        break;
      case VerificationStatus.expired:
        icon = Icons.timer_off_rounded;
        color = const Color(0xFF6B7280);
        bgColor = const Color(0xFFF3F4F6);
        title = 'Session Expired';
        subtitle = 'Your session has timed out';
        message =
            'Your verification session has expired. Please start a new verification to continue.';
        showRetryButton = true;
        break;
      default:
        return;
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
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
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
                      Icon(Icons.notifications_active_rounded,
                          color: color, size: 20),
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
              if (showRetryButton)
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
                          child: const Text('Later',
                              style: TextStyle(fontWeight: FontWeight.w600)),
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
                          child: const Text('Try Again',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          status.statusEnum == VerificationStatus.approved
                              ? const Color(0xFF10B981)
                              : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      status.statusEnum == VerificationStatus.approved
                          ? 'Awesome!'
                          : 'Got it',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Helpers (UI)
  // ─────────────────────────────────────────────────────

  Color _getPackColor(String packName) {
    switch (packName) {
      case 'plus':
        return const Color(0xFF6366F1);
      case 'pro':
        return const Color(0xFFF59E0B);
      case 'premium':
        return const Color(0xFFEC4899);
      default:
        return AppColors.secondary;
    }
  }

  Color _getVerificationCardColor(String status) {
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

  IconData _getVerificationIcon(String status) {
    switch (status) {
      case 'in_progress':
        return Icons.hourglass_top;
      case 'in_review':
        return Icons.pending;
      case 'declined':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.info_outline;
    }
  }

  bool _getVerificationButtonEnabled(String? status) {
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
        return l10n.continueVerification;
      case 'in_review':
        return l10n.underReview;
      case 'declined':
      case 'expired':
      case 'abandoned':
        return l10n.retryVerification;
      default:
        return l10n.verifyIdentity;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'TBD';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (end == null || (start.day == end.day && start.month == end.month)) {
      return '${months[start.month - 1]} ${start.day}, ${start.year}';
    }
    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.day}-${end.day}, ${start.year}';
    }
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
  }
}
