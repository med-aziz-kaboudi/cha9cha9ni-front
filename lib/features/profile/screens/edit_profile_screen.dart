import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../services/profile_api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileApiService = ProfileApiService();
  final _tokenStorage = TokenStorageService();
  final _fullNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _profile;
  String? _errorMessage;

  // Email change flow states
  bool _isEditingEmail = false;
  bool _isVerifyingCurrentEmail = false;
  bool _currentEmailVerified = false;
  bool _isVerifyingNewEmail = false;
  bool _isSendingCode = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _newEmailController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _countdownTimer?.cancel();
    _profileApiService.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadProfile() async {
    // First, load from cache for instant display
    final cachedProfile = await _tokenStorage.getCachedUserProfile();
    final hasCachedData = cachedProfile['email'] != null;
    
    if (hasCachedData) {
      // Show cached data immediately (no loading spinner)
      setState(() {
        _isLoading = false;
        _fullNameController.text = cachedProfile['fullName'] ?? '';
        _firstNameController.text = cachedProfile['firstName'] ?? '';
        _lastNameController.text = cachedProfile['lastName'] ?? '';
        _emailController.text = cachedProfile['email'] ?? '';
        
        // Handle phone - strip +216 prefix if present
        String phone = cachedProfile['phone'] ?? '';
        if (phone.startsWith('+216')) {
          phone = phone.substring(4);
        }
        _phoneController.text = phone;
      });
    }

    // Check if data is fresh (fetched within last 60 seconds)
    final isFresh = await _tokenStorage.isProfileDataFresh(thresholdSeconds: 60);
    if (isFresh && hasCachedData) {
      debugPrint('📦 Profile data is fresh, skipping API fetch');
      return;
    }

    // Fetch fresh data from API in background
    try {
      if (!hasCachedData) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final profile = await _profileApiService.getProfile();
      
      // Save to cache for next time
      await _tokenStorage.saveUserProfile(
        firstName: profile.firstName,
        lastName: profile.lastName,
        fullName: profile.fullName,
        email: profile.email,
        phone: profile.phone,
      );
      
      setState(() {
        _profile = profile;
        _isLoading = false;
        
        // Fill all name fields with their values (empty if null)
        _fullNameController.text = profile.fullName ?? '';
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        
        _emailController.text = profile.email;
        
        // Handle phone - strip +216 prefix if present
        String phone = profile.phone ?? '';
        if (phone.startsWith('+216')) {
          phone = phone.substring(4);
        }
        _phoneController.text = phone;
      });
    } catch (e) {
      // Only show error if we don't have cached data
      if (!hasCachedData) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } else {
        debugPrint('⚠️ Failed to refresh profile, using cached data: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Validate phone number if provided (must be exactly 8 digits)
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && phone.length != 8) {
      AppToast.error(context, l10n.phoneNumberMustBe8Digits);
      return;
    }
    
    // Check if phone contains only digits
    if (phone.isNotEmpty && !RegExp(r'^[0-9]{8}$').hasMatch(phone)) {
      AppToast.error(context, l10n.phoneNumberMustBe8Digits);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedProfile = await _profileApiService.updateProfile(
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        phone: phone.isEmpty ? null : '+216$phone',
      );

      // Update cache with new profile data
      await _tokenStorage.saveUserProfile(
        firstName: updatedProfile.firstName,
        lastName: updatedProfile.lastName,
        fullName: updatedProfile.fullName,
        email: updatedProfile.email,
        phone: updatedProfile.phone,
      );

      setState(() {
        _profile = updatedProfile;
        _isSaving = false;
      });

      // Track profile updated
      AnalyticsService().trackProfileUpdated();

      if (mounted) {
        AppToast.success(context, l10n.profileUpdatedSuccessfully);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _sendVerificationCodeToCurrentEmail() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSendingCode = true);
    
    try {
      await _profileApiService.sendEmailChangeCode();
      _startCountdown();
      setState(() {
        _isSendingCode = false;
        _isVerifyingCurrentEmail = true;
      });
      if (mounted) {
        AppToast.success(context, l10n.codeSentSuccessfully);
      }
    } catch (e) {
      setState(() => _isSendingCode = false);
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _verifyCurrentEmailCode() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _verificationCodeController.text.trim();
    
    if (code.length != 6) {
      AppToast.error(context, l10n.enterAllDigits);
      return;
    }

    setState(() => _isSendingCode = true);
    
    try {
      await _profileApiService.verifyEmailChangeCode(code);
      // Reset countdown timer so user can send to new email immediately
      _countdownTimer?.cancel();
      setState(() {
        _isSendingCode = false;
        _currentEmailVerified = true;
        _isVerifyingCurrentEmail = false;
        _verificationCodeController.clear();
        _resendCountdown = 0; // Reset countdown for new email step
      });
      if (mounted) {
        AppToast.success(context, l10n.verificationSuccess);
      }
    } catch (e) {
      setState(() => _isSendingCode = false);
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _sendVerificationCodeToNewEmail() async {
    final l10n = AppLocalizations.of(context)!;
    final newEmail = _newEmailController.text.trim();
    
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      AppToast.error(context, l10n.invalidEmailFormat);
      return;
    }

    setState(() => _isSendingCode = true);
    
    try {
      await _profileApiService.sendNewEmailCode(newEmail);
      _startCountdown();
      setState(() {
        _isSendingCode = false;
        _isVerifyingNewEmail = true;
      });
      if (mounted) {
        AppToast.success(context, l10n.codeSentSuccessfully);
      }
    } catch (e) {
      setState(() => _isSendingCode = false);
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _verifyNewEmailAndChange() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _verificationCodeController.text.trim();
    
    if (code.length != 6) {
      AppToast.error(context, l10n.enterAllDigits);
      return;
    }

    setState(() => _isSendingCode = true);
    
    try {
      final updatedProfile = await _profileApiService.confirmEmailChange(
        _newEmailController.text.trim(),
        code,
      );
      setState(() {
        _profile = updatedProfile;
        _emailController.text = updatedProfile.email;
        _isSendingCode = false;
        _isEditingEmail = false;
        _currentEmailVerified = false;
        _isVerifyingNewEmail = false;
        _verificationCodeController.clear();
        _newEmailController.clear();
      });
      if (mounted) {
        AppToast.success(context, l10n.emailUpdatedSuccessfully);
      }
    } catch (e) {
      setState(() => _isSendingCode = false);
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _cancelEmailEdit() {
    setState(() {
      _isEditingEmail = false;
      _isVerifyingCurrentEmail = false;
      _currentEmailVerified = false;
      _isVerifyingNewEmail = false;
      _verificationCodeController.clear();
      _newEmailController.clear();
      _countdownTimer?.cancel();
      _resendCountdown = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
              _buildAppBar(l10n),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _errorMessage != null
                        ? _buildErrorState(l10n)
                        : _buildProfileForm(l10n),
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
            l10n.editProfile,
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

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? l10n.anErrorOccurred,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(AppLocalizations l10n) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 32),
              
              // Full Name field - always shown and editable
              _buildTextField(
                label: l10n.fullName,
                controller: _fullNameController,
                isEditable: true,
              ),
              const SizedBox(height: 16),
              
              // First Name field - always shown and editable
              _buildTextField(
                label: l10n.firstNameLabel,
                controller: _firstNameController,
                isEditable: true,
              ),
              const SizedBox(height: 16),
              
              // Last Name field - always shown and editable
              _buildTextField(
                label: l10n.lastNameLabel,
                controller: _lastNameController,
                isEditable: true,
              ),
              const SizedBox(height: 16),
              
              // Email field with edit functionality
              _buildEmailField(l10n),
              const SizedBox(height: 16),
              
              // Phone field
              _buildPhoneField(l10n),
            ],
          ),
        ),
        
        // Save button at bottom (only if not editing email)
        if (!_isEditingEmail)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gray.withValues(alpha: 0),
                    AppColors.gray,
                  ],
                ),
              ),
              child: _buildSaveButton(l10n),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    final initials = _getInitials();
    
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [AppColors.secondary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [AppColors.primary, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    // Priority: fullName > firstName+lastName > email
    final fullName = _fullNameController.text.trim();
    if (fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName[0].toUpperCase();
    }
    
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (_profile?.email != null) {
      return _profile!.email[0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A7A90),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEditable ? AppColors.secondary : const Color(0xFFE0E0E6),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: isEditable,
            style: TextStyle(
              color: isEditable ? AppColors.dark : Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    if (_isEditingEmail) {
      return _buildEmailChangeFlow(l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.email,
              style: const TextStyle(
                color: Color(0xFF7A7A90),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isEditingEmail = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.edit,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E6),
              width: 1,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _emailController.text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailChangeFlow(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with cancel button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.changeEmail,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: _cancelEmailEdit,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1: Verify current email
          if (!_currentEmailVerified) ...[
            // Current email display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _emailController.text,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            if (!_isVerifyingCurrentEmail) ...[
              Text(
                l10n.verifyCurrentEmailDesc,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: l10n.sendVerificationCode,
                onTap: _sendVerificationCodeToCurrentEmail,
                isLoading: _isSendingCode,
              ),
            ] else ...[
              Text(
                l10n.enterCodeSentTo(_emailController.text),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildCodeInput(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: l10n.verify,
                      onTap: _verifyCurrentEmailCode,
                      isLoading: _isSendingCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildResendButton(l10n, _sendVerificationCodeToCurrentEmail),
                ],
              ),
            ],
          ]
          
          // Step 2: Enter and verify new email
          else ...[
            // Success indicator for step 1
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.currentEmailVerified,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (!_isVerifyingNewEmail) ...[
              Text(
                l10n.enterNewEmail,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: TextField(
                  controller: _newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.newEmailPlaceholder,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: l10n.sendVerificationCode,
                onTap: _sendVerificationCodeToNewEmail,
                isLoading: _isSendingCode,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _newEmailController.text,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.enterCodeSentTo(_newEmailController.text),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildCodeInput(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: l10n.confirmChange,
                      onTap: _verifyNewEmailAndChange,
                      isLoading: _isSendingCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildResendButton(l10n, _sendVerificationCodeToNewEmail),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary),
      ),
      child: TextField(
        controller: _verificationCodeController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          color: AppColors.dark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: '------',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: 20,
            letterSpacing: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResendButton(AppLocalizations l10n, VoidCallback onResend) {
    final canResend = _resendCountdown == 0;
    
    return GestureDetector(
      onTap: canResend ? onResend : null,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: canResend ? AppColors.secondary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canResend ? AppColors.secondary : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            canResend ? l10n.resendOTP : '${_resendCountdown}s',
            style: TextStyle(
              color: canResend ? AppColors.secondary : Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.phoneNumberLabel,
          style: const TextStyle(
            color: Color(0xFF7A7A90),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondary,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Tunisia flag and code
              Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Color(0xFFE0E0E6),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tunisia flag - proper design
                    _buildTunisiaFlag(),
                    const SizedBox(width: 8),
                    const Text(
                      '+216',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Phone input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    hintText: '12 345 678',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a proper Tunisia flag using CustomPaint
  Widget _buildTunisiaFlag() {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CustomPaint(
          size: const Size(28, 20),
          painter: TunisiaFlagPainter(),
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: _isSaving 
                ? [AppColors.primary.withValues(alpha: 0.6), AppColors.primary.withValues(alpha: 0.6)]
                : [AppColors.primary, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  l10n.saveChanges,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Custom painter for Tunisia flag
class TunisiaFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final redPaint = Paint()..color = const Color(0xFFE70013);
    final whitePaint = Paint()..color = Colors.white;
    
    // Red background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      redPaint,
    );
    
    // White circle in center
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final circleRadius = size.height * 0.35;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      whitePaint,
    );
    
    // Red crescent (using two circles)
    final crescentOuterRadius = circleRadius * 0.85;
    final crescentInnerRadius = circleRadius * 0.65;
    final crescentOffset = circleRadius * 0.2;
    
    // Draw outer red circle for crescent
    canvas.drawCircle(
      Offset(centerX, centerY),
      crescentOuterRadius,
      redPaint,
    );
    
    // Cut out inner white circle to form crescent
    canvas.drawCircle(
      Offset(centerX + crescentOffset, centerY),
      crescentInnerRadius,
      whitePaint,
    );
    
    // Red star (5-pointed)
    _drawStar(
      canvas,
      Offset(centerX + circleRadius * 0.2, centerY),
      circleRadius * 0.35,
      redPaint,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final innerRadius = radius * 0.4;
    
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;
      
      final outerX = center.dx + radius * math.cos(outerAngle);
      final outerY = center.dy + radius * math.sin(outerAngle);
      final innerX = center.dx + innerRadius * math.cos(innerAngle);
      final innerY = center.dy + innerRadius * math.sin(innerAngle);
      
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
