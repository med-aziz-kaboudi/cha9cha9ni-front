import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/family_model.dart';
import '../../core/services/family_api_service.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';import '../../l10n/app_localizations.dart';import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';
import '../home/family_owner_home_screen.dart';
import '../home/family_member_home_screen.dart';

// Custom formatter for invite code (XXXX-XXXX format)
class InviteCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '').toUpperCase();
    
    if (text.length > 8) {
      return oldValue;
    }
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4) {
        formatted += '-';
      }
      formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FamilySelectionScreen extends StatefulWidget {
  const FamilySelectionScreen({super.key});

  @override
  State<FamilySelectionScreen> createState() => _FamilySelectionScreenState();
}

class _FamilySelectionScreenState extends State<FamilySelectionScreen> {
  final _familyApiService = FamilyApiService();
  final _tokenStorage = TokenStorageService();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;
  bool _showJoinInput = false;

  @override
  void initState() {
    super.initState();
    // Ensure we have fresh tokens when arriving at this screen
    // This is important after leaving a family to get tokens without family association
    _ensureFreshToken();
  }

  Future<void> _ensureFreshToken() async {
    debugPrint('🔄 FamilySelectionScreen: Ensuring fresh token...');
    await _familyApiService.forceTokenRefresh();
    debugPrint('✅ FamilySelectionScreen: Token refreshed');
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    try {
      // Clear backend tokens and user profile
      await _tokenStorage.clearTokens();
      
      // Clear any pending verification
      await PendingVerificationHelper.clear();
      
      // Clear security cache so unlock screen doesn't show on next login
      await BiometricService().clearSecurityCache();
      
      // Sign out from Supabase (if there's a session)
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.signOut();
      }
      
      // Navigate to sign in screen and clear all routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.signOutFailed ?? 'Sign out failed'}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCreateFamily() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🏠 Creating family...');
      
      // Get user's last name for family name
      final lastName = await _tokenStorage.getUserLastName();
      final familyName = lastName ?? AppLocalizations.of(context)!.myFamily;
      
      final family = await _familyApiService.createFamily(
        CreateFamilyRequest(name: familyName),
      );

      debugPrint('✅ Family created: ${family.id}, Invite: ${family.inviteCode}');

      // Track family creation
      AnalyticsService().trackCreateFamily(familyId: family.id);

      if (!mounted) return;

      // Show success dialog with invite code
      await _showInviteCodeDialog(family.inviteCode!);
      
      // Verify family ownership by fetching family info
      final verifiedFamily = await _familyApiService.getMyFamily();
      debugPrint('👨‍👩‍👧‍👦 Family verified: ${verifiedFamily != null ? "Yes (Owner: ${verifiedFamily.isOwner})" : "No"}');

      // Navigate to owner home screen and clear all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const FamilyOwnerHomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.failedToCreateFamily}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleJoinFamily() async {
    final code = _inviteCodeController.text.trim().replaceAll('-', '');
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterInviteCode),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🎫 Joining family with code: $code');
      
      await _familyApiService.joinFamily(
        JoinFamilyRequest(inviteCode: code),
      );

      debugPrint('✅ Successfully joined family');
      
      // Track join family
      AnalyticsService().trackJoinFamily();
      
      // Verify family membership by fetching family info
      final family = await _familyApiService.getMyFamily();
      debugPrint('👨‍👩‍👧‍👦 Family verified: ${family != null ? "Yes (${family.name})" : "No"}');

      if (!mounted) return;

      // Navigate to member home screen and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const FamilyMemberHomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.failedToJoinFamily}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showInviteCodeDialog(String code) async {
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                l10n.familyInviteCode,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              
              // Subtitle
              Text(
                l10n.shareThisCode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 20),
              
              // Code display card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: code));
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.codeCopied),
                            backgroundColor: AppColors.secondary,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Note
              Text(
                '⚡ ${l10n.codeExpiresAfterUse}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              
              // Got it button - Primary gradient
              Container(
                width: double.infinity,
                height: 48,
                decoration: ShapeDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.gotIt,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo
                Image.asset(
                  'assets/icons/horisental.png',
                  width: MediaQuery.of(context).size.width * 0.65,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 48),
                
                // Title
                Text(
                  AppLocalizations.of(context)!.joinOrCreateFamily,
                  style: AppTextStyles.heading1.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  AppLocalizations.of(context)!.chooseHowToProceed,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),
                
                // Create Family Button
                GestureDetector(
                  onTap: _isLoading ? null : _handleCreateFamily,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: ShapeDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadows: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading && !_showJoinInput
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.createAFamily,
                              style: AppTextStyles.bodyMedium,
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // OR divider
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        AppLocalizations.of(context)!.orDivider,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // Join Family Button or Input
                if (!_showJoinInput)
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => setState(() => _showJoinInput = true),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 2,
                            color: AppColors.secondary,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadows: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.joinAFamily,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Invite Code Input
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _inviteCodeController,
                          inputFormatters: [
                            InviteCodeFormatter(),
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                          ],
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterInviteCode,
                            hintStyle: AppTextStyles.body.copyWith(
                              color: Colors.grey.shade400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.secondary,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.secondary,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.secondary,
                                width: 2.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            letterSpacing: 4,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Join Button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleJoinFamily,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: ShapeDecoration(
                            color: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadows: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading && _showJoinInput
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.joinNow,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Cancel Button
                      TextButton(
                        onPressed: () => setState(() {
                          _showJoinInput = false;
                          _inviteCodeController.clear();
                        }),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const Spacer(flex: 3),
                
                // Sign Out Link
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: TextButton(
                    onPressed: _handleSignOut,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.signOut,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
