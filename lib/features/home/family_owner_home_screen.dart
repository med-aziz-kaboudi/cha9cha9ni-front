import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/family_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';

class FamilyOwnerHomeScreen extends StatefulWidget {
  const FamilyOwnerHomeScreen({super.key});

  @override
  State<FamilyOwnerHomeScreen> createState() => _FamilyOwnerHomeScreenState();
}

class _FamilyOwnerHomeScreenState extends State<FamilyOwnerHomeScreen> {
  String _displayName = 'Loading...';
  String? _inviteCode;
  bool _isLoadingCode = true;
  final _tokenStorage = TokenStorageService();
  final _familyApiService = FamilyApiService();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadDisplayName();
    await _loadInviteCode();
  }

  Future<void> _loadDisplayName() async {
    final name = await _tokenStorage.getUserDisplayName();
    if (mounted) {
      setState(() {
        _displayName = name;
      });
    }
  }

  Future<void> _loadInviteCode() async {
    try {
      final family = await _familyApiService.getMyFamily();
      if (mounted && family != null) {
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
          const SnackBar(content: Text('Scan button tapped')),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward screen coming soon')),
        );
        break;
    }
  }

  void _copyInviteCode() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite code copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/horisental.png',
                  width: MediaQuery.of(context).size.width * 0.60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                
                Text(
                  AppLocalizations.of(context)!.welcomeFamilyOwner,
                  style: AppTextStyles.heading1.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Text(
                  _displayName,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Invite Code Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.familyInviteCode,
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 16,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isLoadingCode)
                        const CircularProgressIndicator()
                      else if (_inviteCode != null)
                        GestureDetector(
                          onTap: _copyInviteCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _inviteCode!,
                                style: AppTextStyles.heading1.copyWith(
                                  fontSize: 24,
                                    color: AppColors.secondary,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.copy,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Text('No code available'),
                      
                      const SizedBox(height: 12),
                      Text(
                        'Share this code with family members.\nIt will change after each use.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                GestureDetector(
                  onTap: () => _handleSignOut(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: ShapeDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.signOut,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
