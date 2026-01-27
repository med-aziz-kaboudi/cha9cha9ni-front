import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../pack_models.dart';
import '../pack_service.dart';

/// Screen showing all available subscription packs
class AllPacksScreen extends StatefulWidget {
  const AllPacksScreen({super.key});

  @override
  State<AllPacksScreen> createState() => _AllPacksScreenState();
}

class _AllPacksScreenState extends State<AllPacksScreen> {
  final _packService = PackService();
  bool _isYearly = false; // Toggle for monthly/yearly pricing
  
  // Pack details with max amounts
  static const Map<String, int> _maxWithdrawAmounts = {
    'free': 1000,
    'plus': 1500,
    'pro': 2000,
    'premium': 3000,
  };
  
  /// Hardcoded packs - these are always available
  static final List<PackModel> _defaultPacks = [
    PackModel(
      id: 'free',
      name: 'free',
      displayName: 'STARTER PACK',
      priceMonthly: 0,
      priceYearly: 0,
      withdrawalsPerYear: 1,
      maxAidsSelectable: 1,
      maxFamilyMembers: 99, // Unlimited
    ),
    PackModel(
      id: 'plus',
      name: 'plus',
      displayName: 'PLUS PACK',
      priceMonthly: 5,
      priceYearly: 48, // 20% discount (5*12=60, 60*0.8=48)
      withdrawalsPerYear: 3,
      maxAidsSelectable: 2,
      maxFamilyMembers: 99, // Unlimited
    ),
    PackModel(
      id: 'pro',
      name: 'pro',
      displayName: 'PRO PACK',
      priceMonthly: 10,
      priceYearly: 96, // 20% discount (10*12=120, 120*0.8=96)
      withdrawalsPerYear: 5,
      maxAidsSelectable: 3,
      maxFamilyMembers: 99, // Unlimited
    ),
    PackModel(
      id: 'premium',
      name: 'premium',
      displayName: 'PREMIUM PACK',
      priceMonthly: 15,
      priceYearly: 144, // 20% discount (15*12=180, 180*0.8=144)
      withdrawalsPerYear: 8,
      maxAidsSelectable: 5,
      maxFamilyMembers: 99, // Unlimited
    ),
  ];
  
  List<PackModel> _packs = [];
  PackModel? _currentPack;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _togglePricing(bool yearly) {
    if (_isYearly == yearly) return;
    
    setState(() {
      _isYearly = yearly;
    });
  }

  void _loadData() {
    // Use hardcoded packs immediately - no API fetch needed
    _packs = _defaultPacks;
    
    // Get current pack from cache if available
    final currentData = _packService.currentData;
    if (currentData != null) {
      _currentPack = currentData.pack;
    } else {
      // Default to free/starter pack - all users start with this
      _currentPack = _defaultPacks.first; // free pack is always the default
    }
    
    if (mounted) {
      setState(() {});
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
        return const Color(0xFF4CC3C7); // Teal/Cyan
      case 'pro':
        return const Color(0xFF7B93AD); // Darker Blue/Gray
      case 'premium':
        return const Color(0xFFFFC945); // Golden Yellow
      default:
        return AppColors.secondary; // Teal for free
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
                child: _buildContent(l10n),
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
            l10n.allPacks,
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

  Widget _buildContent(AppLocalizations l10n) {
    if (_packs.isEmpty) return const SizedBox();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly/Yearly Switcher with Animation
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final halfWidth = constraints.maxWidth / 2;
                final isRTL = Directionality.of(context) == TextDirection.rtl;
                return Stack(
                  children: [
                    // Animated sliding background (RTL-aware)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: isRTL 
                          ? (_isYearly ? 0 : halfWidth)
                          : (_isYearly ? halfWidth : 0),
                      child: Container(
                        width: halfWidth,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                    // Text buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _togglePricing(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  style: TextStyle(
                                    color: !_isYearly ? Colors.white : AppColors.dark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  child: Text(l10n.monthly),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _togglePricing(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      style: TextStyle(
                                        color: _isYearly ? Colors.white : AppColors.dark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      child: Text(l10n.yearly),
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isYearly 
                                            ? Colors.white.withOpacity(0.2)
                                            : const Color(0xFF10B981).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeOutCubic,
                                        style: TextStyle(
                                          color: _isYearly ? Colors.white : const Color(0xFF10B981),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                        child: const Text('-20%'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Pack Cards
          ..._packs.map((pack) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPackCard(pack, l10n),
          )),
          
          // Minimum withdrawal warning - moved to bottom as remark
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE69C)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF856404), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.minimumWithdrawal(50),
                    style: const TextStyle(
                      color: Color(0xFF856404),
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
      ),
    );
  }

  // Pack order for comparison (lower index = lower tier)
  static const _packOrder = ['free', 'plus', 'pro', 'premium'];
  
  Widget _buildPackCard(PackModel pack, AppLocalizations l10n) {
    // Compare by id OR name (to handle default free pack)
    final isCurrentPack = _currentPack?.id == pack.id || _currentPack?.name == pack.name;
    final packColor = _getPackColor(pack.name);
    
    // Determine if this is a downgrade (for button styling)
    final currentPackIndex = _packOrder.indexOf(_currentPack?.name ?? 'free');
    final thisPackIndex = _packOrder.indexOf(pack.name);
    final isDowngrade = thisPackIndex < currentPackIndex;
    
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
                    colors: pack.name == 'plus' 
                        ? [
                            packColor.withOpacity(0.35),
                            packColor.withOpacity(0.55),
                            packColor.withOpacity(0.45),
                          ]
                        : [
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
                        style: TextStyle(
                          color: pack.name == 'pro' ? AppColors.dark : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Price - show monthly or yearly based on toggle
                    if (pack.isFree)
                      Text(
                        l10n.free,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey<bool>(_isYearly),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _isYearly 
                                      ? '${pack.priceYearly.toInt()} DT'
                                      : '${pack.priceMonthly.toInt()} DT',
                                  style: const TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _isYearly ? '/ ${l10n.year}' : '/ ${l10n.month}',
                                    style: TextStyle(
                                      color: AppColors.dark.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isYearly)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${(pack.priceMonthly * 12).toInt()} DT',
                                  style: TextStyle(
                                    color: AppColors.dark.withOpacity(0.4),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 6),
                    
                    // Max withdrawal amount
                    Text(
                      l10n.upToAmount(_maxWithdrawAmounts[pack.name] ?? 1000),
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
              
              // Checkmark badge - top right (only for current pack)
              if (isCurrentPack)
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
          
          // Features/Advantages Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                _buildFeatureRow(
                  Icons.card_giftcard_rounded,
                  l10n.aidsSelectable(pack.maxAidsSelectable),
                  packColor,
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  Icons.account_balance_wallet_rounded,
                  l10n.withdrawalsPerYear(pack.withdrawalsPerYear),
                  packColor,
                ),
              ],
            ),
          ),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: isCurrentPack
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        backgroundColor: AppColors.secondary.withOpacity(0.08),
                        side: BorderSide(color: AppColors.secondary.withOpacity(0.3), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.currentPack,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : isDowngrade
                      ? OutlinedButton(
                          onPressed: () {
                            _showDowngradeDialog(pack, l10n);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.dark.withOpacity(0.7),
                            backgroundColor: Colors.grey.withOpacity(0.08),
                            side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 18,
                                color: AppColors.dark.withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.downgradeTo(pack.displayName),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            _showUpgradeDialog(pack, l10n);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: pack.name == 'pro' ? AppColors.dark : Colors.white,
                            backgroundColor: packColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            elevation: 2,
                            shadowColor: packColor.withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                size: 18,
                                color: pack.name == 'pro' ? AppColors.dark : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.upgradeTo(pack.displayName),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showUpgradeDialog(PackModel pack, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.upgradeTo(pack.displayName)),
        content: Text(
          pack.isFree 
              ? l10n.downgradeConfirmation
              : l10n.upgradeConfirmation(pack.displayName, pack.priceMonthly.toInt()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement subscription change
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.subscriptionComingSoon),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPackColor(pack.name),
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
  
  void _showDowngradeDialog(PackModel pack, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.downgradeTo(pack.displayName)),
        content: Text(l10n.downgradeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement subscription change
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.subscriptionComingSoon),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
