import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
      debugPrint('📱 CurrentPackScreen: Received adsStats update - userAdsToday: ${stats.userAdsToday}, familyTotal: ${stats.familyTotalAdsToday}');
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
        final remainingSeconds = (_refreshCooldown - timeSinceLastRefresh).inSeconds;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please wait $remainingSeconds seconds before refreshing again'),
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
      final data = await _packService.fetchCurrentPack(forceRefresh: forceRefresh);
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
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
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
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
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
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
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
              trailing: '${_packData!.currentFamilyMembers} / ${_packData!.maxFamilyMembers}',
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
                      pack.isFree ? l10n.free : '${pack.priceMonthly.toInt()} DT / ${l10n.month}',
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
                    side: BorderSide(color: packColor.withOpacity(0.4), width: 1.5),
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
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to KYC screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(l10n.verifyIdentity),
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
        onTap: isOwner ? () {
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
        } : null,
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
                      text: '${stats.familyTotalAdsToday} / ${stats.familyMaxAdsToday} ',
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
                colors: [
                  Color(0xFFFBBF24),
                  Color(0xFFF59E0B),
                ],
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
