import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';
import 'widgets/home_header_widget.dart';

class FamilyOwnerHomeScreen extends StatefulWidget {
  const FamilyOwnerHomeScreen({super.key});

  @override
  State<FamilyOwnerHomeScreen> createState() => _FamilyOwnerHomeScreenState();
}

class _FamilyOwnerHomeScreenState extends State<FamilyOwnerHomeScreen> {
  // ignore: unused_field
  String _displayName = 'Loading...';
  // ignore: unused_field
  String? _inviteCode;
  // ignore: unused_field
  bool _isLoadingCode = true;
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  int _currentNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCachedDataFirst();
  }

  Future<void> _loadCachedDataFirst() async {
    // Load display name
    final name = await _tokenStorage.getUserDisplayName();
    
    // Load cached family info first for instant display
    final cachedFamily = await _tokenStorage.getCachedFamilyInfo();
    
    if (mounted) {
      setState(() {
        _displayName = name;
        if (cachedFamily != null && cachedFamily['inviteCode'] != null) {
          _inviteCode = cachedFamily['inviteCode'];
          _isLoadingCode = false;
        }
      });
    }
    
    // Then refresh from API in background
    _refreshInviteCode();
  }

  Future<void> _refreshInviteCode() async {
    try {
      final family = await _familyApiService.getMyFamily();
      if (mounted && family != null) {
        // Save to cache for next time
        await _tokenStorage.saveFamilyInfo(
          familyName: family.name,
          ownerName: family.ownerName,
          memberCount: family.memberCount,
          isOwner: family.isOwner,
          inviteCode: family.inviteCode,
        );
        
        setState(() {
          _inviteCode = family.inviteCode;
          _isLoadingCode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCode = false;
        });
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await _tokenStorage.clearTokens();
      await PendingVerificationHelper.clear();
      
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.signOut();
      }
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    
    switch (index) {
      case 0:
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.scanButtonTapped)),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.rewardScreenComingSoon)),
        );
        break;
    }
  }

  // ignore: unused_element
  void _copyInviteCode() {
    if (_inviteCode != null) {
      // Clipboard.setData(ClipboardData(text: _inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.inviteCodeCopiedToClipboard),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: CustomDrawer(
        onLogout: () {
          Navigator.pop(context);
          _handleSignOut(context);
        },
        onPersonalInfo: () {
          Navigator.pop(context);
        },
        onCurrentPack: () {
          Navigator.pop(context);
        },
        onLoginSecurity: () {
          Navigator.pop(context);
        },
        onLanguages: () {
          Navigator.pop(context);
        },
        onNotifications: () {
          Navigator.pop(context);
        },
        onHelp: () {
          Navigator.pop(context);
        },
        onLegalAgreements: () {
          Navigator.pop(context);
        },
      ),
      body: Stack(
        children: [
          // Scrollable content - behind everything
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space for the fixed header
                  SizedBox(height: MediaQuery.of(context).size.height * 0.32),
                  
                  // Next Withdrawal Card
                  _buildNextWithdrawalCard(context),
                
                  const SizedBox(height: 24),
                  
                  // Family Members Section
                  _buildFamilyMembersSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Activities Section
                  _buildRecentActivitiesSection(context),
                  
                  // Bottom padding for nav bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Fixed Header on top - doesn't move
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderWidget(
              onTopUp: () {},
              onWithdraw: () {},
              onStatement: () {},
            ),
          ),
          
          // Drawer handle - positioned at top (RTL aware)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: Directionality.of(context) == TextDirection.rtl ? null : 0,
            right: Directionality.of(context) == TextDirection.rtl ? 0 : null,
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 24,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.only(
                    topRight: Directionality.of(context) == TextDirection.rtl ? Radius.zero : const Radius.circular(24),
                    bottomRight: Directionality.of(context) == TextDirection.rtl ? Radius.zero : const Radius.circular(24),
                    topLeft: Directionality.of(context) == TextDirection.rtl ? const Radius.circular(24) : Radius.zero,
                    bottomLeft: Directionality.of(context) == TextDirection.rtl ? const Radius.circular(24) : Radius.zero,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Directionality.of(context) == TextDirection.rtl ? const Offset(-2, 0) : const Offset(2, 0),
                    ),
                  ],
                ),
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildNextWithdrawalCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEE3764).withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEE3764).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🎊', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.nextWithdrawal,
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 12,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    '🎊 Aid Kbir - 1000 DT',
                    style: TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 12,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Opacity(
                    opacity: 0.6,
                    child: Text(
                      AppLocalizations.of(context)!.availableInDays(23),
                      style: const TextStyle(
                        color: Color(0xFF13123A),
                        fontSize: 11,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
              color: const Color(0xFF13123A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMembersSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.familyMembers,
                style: const TextStyle(
                  color: Color(0xFF23233F),
                  fontSize: 18,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  AppLocalizations.of(context)!.manage,
                  style: const TextStyle(
                    color: Color(0xFFEE3764),
                    fontSize: 14,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFamilyMemberAvatar('John'),
                const SizedBox(width: 20),
                _buildFamilyMemberAvatar('Loui William'),
                const SizedBox(width: 20),
                _buildFamilyMemberAvatar('Hannahsx'),
                const SizedBox(width: 20),
                _buildFamilyMemberAvatar('Leahaed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberAvatar(String name) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CC3C7),
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDDDDD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Yellow badge
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEBC11),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF23233F),
            fontSize: 14,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentActivities,
                style: const TextStyle(
                  color: Color(0xFF13123A),
                  fontSize: 16,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  AppLocalizations.of(context)!.viewAll,
                  style: const TextStyle(
                    color: Color(0xFFEE3764),
                    fontSize: 14,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            emoji: '💸',
            title: 'Aid Kbir Withdrawal',
            date: 'Jun 9, 2025',
            amount: '- 1000 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💰',
            title: 'Deposit from john',
            date: 'Jun 5, 2025',
            amount: '+ 500 DT',
            amountColor: const Color(0xFF4CC3C7),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🎁',
            title: 'Ads earning (aziz)',
            date: 'Jun 5, 2025',
            amount: '+ 10 Points',
            amountColor: const Color(0xFFD8B217),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💳',
            title: 'Monthly subscription',
            date: 'Jun 1, 2025',
            amount: '- 50 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💰',
            title: 'Deposit from Sarah',
            date: 'May 28, 2025',
            amount: '+ 750 DT',
            amountColor: const Color(0xFF4CC3C7),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🛒',
            title: 'Shopping expense',
            date: 'May 25, 2025',
            amount: '- 200 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🎁',
            title: 'Referral bonus',
            date: 'May 20, 2025',
            amount: '+ 25 Points',
            amountColor: const Color(0xFFD8B217),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '💰',
            title: 'Deposit from Mike',
            date: 'May 15, 2025',
            amount: '+ 300 DT',
            amountColor: const Color(0xFF4CC3C7),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🏠',
            title: 'Rent payment',
            date: 'May 10, 2025',
            amount: '- 800 DT',
            amountColor: const Color(0xFFEE3764),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            emoji: '🎁',
            title: 'Daily login reward',
            date: 'May 5, 2025',
            amount: '+ 5 Points',
            amountColor: const Color(0xFFD8B217),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String emoji,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CC3C7).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF13123A),
                    fontSize: 14,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Opacity(
                  opacity: 0.6,
                  child: Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF13123A),
                      fontSize: 12,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 12,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
