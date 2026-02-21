import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_sanitizer.dart';
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
  bool _isIdentityVerified = false;

  // Profile picture state
  final _imagePicker = ImagePicker();
  bool _isUploadingPicture = false;
  String? _profilePictureUrl;

  // Profile picture rate limiting (1 change per day)
  bool _canUpdateProfilePicture = true;
  DateTime? _nextAllowedProfilePictureUpdate;
  Timer? _profilePictureRateLimitTimer;

  // Email change flow states
  bool _isEditingEmail = false;
  bool _isVerifyingCurrentEmail = false;
  bool _currentEmailVerified = false;
  bool _isVerifyingNewEmail = false;
  bool _isSendingCode = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  // Pull-to-refresh rate limiting
  static const int _maxRefreshes = 5;
  static const int _rateLimitMinutes = 10;
  int _refreshCount = 0;
  DateTime? _rateLimitEndTime;
  Timer? _rateLimitTimer;

  // Socket subscriptions for real-time updates
  StreamSubscription<ProfileUpdatedData>? _profileUpdatedSub;
  StreamSubscription<ProfilePictureUpdatedData>? _profilePictureUpdatedSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProfilePictureRateLimitStatus();
    _listenToSocketUpdates();
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
    _rateLimitTimer?.cancel();
    _profilePictureRateLimitTimer?.cancel();
    _profileUpdatedSub?.cancel();
    _profilePictureUpdatedSub?.cancel();
    _profileApiService.dispose();
    super.dispose();
  }

  /// Listen to socket events for real-time profile updates
  void _listenToSocketUpdates() {
    final socketService = SocketService();

    _profileUpdatedSub = socketService.onProfileUpdated.listen((data) {
      if (!mounted) return;
      debugPrint('👤 Edit profile: received profile_updated via socket');

      setState(() {
        if (data.firstName != null) _firstNameController.text = data.firstName!;
        if (data.lastName != null) _lastNameController.text = data.lastName!;
        if (data.fullName != null) _fullNameController.text = data.fullName!;
        if (data.phone != null) {
          String phone = data.phone!;
          if (phone.startsWith('+216')) phone = phone.substring(4);
          _phoneController.text = phone;
        }
        if (data.profilePictureUrl != null) {
          _profilePictureUrl = data.profilePictureUrl;
        }
      });

      // Update cache with new data
      _tokenStorage.saveUserProfile(
        firstName: data.firstName,
        lastName: data.lastName,
        fullName: data.fullName,
        phone: data.phone,
        profilePictureUrl: data.profilePictureUrl,
      );
    });

    _profilePictureUpdatedSub =
        socketService.onProfilePictureUpdated.listen((data) {
      if (!mounted) return;
      debugPrint('📸 Edit profile: received profile_picture_updated via socket');

      setState(() {
        _profilePictureUrl = data.profilePictureUrl;
      });

      // Update cache
      _tokenStorage.saveUserProfile(
        profilePictureUrl: data.profilePictureUrl,
      );
    });
  }

  /// Load profile picture rate limit status from API
  Future<void> _loadProfilePictureRateLimitStatus() async {
    try {
      final status = await _profileApiService
          .getProfilePictureRateLimitStatus();
      if (mounted) {
        setState(() {
          _canUpdateProfilePicture = status.canUpdate;
          _nextAllowedProfilePictureUpdate = status.nextAllowedUpdate;
        });

        // Start timer to update UI if rate limited
        if (!status.canUpdate && status.nextAllowedUpdate != null) {
          _startProfilePictureRateLimitTimer();
        }
      }
    } catch (e) {
      debugPrint('📸 Error loading rate limit status: $e');
    }
  }

  /// Start timer to update remaining time for profile picture rate limit
  void _startProfilePictureRateLimitTimer() {
    _profilePictureRateLimitTimer?.cancel();
    _profilePictureRateLimitTimer = Timer.periodic(const Duration(minutes: 1), (
      _,
    ) {
      if (mounted) {
        if (_nextAllowedProfilePictureUpdate != null &&
            DateTime.now().isAfter(_nextAllowedProfilePictureUpdate!)) {
          // Rate limit expired
          setState(() {
            _canUpdateProfilePicture = true;
            _nextAllowedProfilePictureUpdate = null;
          });
          _profilePictureRateLimitTimer?.cancel();
        } else {
          setState(() {}); // Refresh UI to update remaining time
        }
      }
    });
  }

  /// Get remaining time string for profile picture rate limit
  String get _profilePictureRateLimitRemainingTime {
    if (_nextAllowedProfilePictureUpdate == null) return '';
    final remaining = _nextAllowedProfilePictureUpdate!.difference(
      DateTime.now(),
    );
    if (remaining.isNegative) return '';
    final hours = remaining.inHours;
    final mins = remaining.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  // Rate limiting helpers for pull-to-refresh
  bool get _isRateLimited {
    if (_rateLimitEndTime == null) return false;
    return DateTime.now().isBefore(_rateLimitEndTime!);
  }

  String get _rateLimitRemainingTime {
    if (_rateLimitEndTime == null) return '';
    final remaining = _rateLimitEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  void _startRateLimitTimer() {
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        if (!_isRateLimited) {
          _rateLimitTimer?.cancel();
          setState(() {
            _rateLimitEndTime = null;
            _refreshCount = 0;
          });
        }
      }
    });
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

  Future<void> _loadProfile({bool fromRefresh = false}) async {
    // Check rate limit for pull-to-refresh
    if (fromRefresh) {
      if (_isRateLimited) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          AppToast.warning(
            context,
            'Rate limited. Please wait $_rateLimitRemainingTime',
          );
        }
        return;
      }

      _refreshCount++;
      if (_refreshCount >= _maxRefreshes) {
        _rateLimitEndTime = DateTime.now().add(
          const Duration(minutes: _rateLimitMinutes),
        );
        _startRateLimitTimer();
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          AppToast.warning(
            context,
            'Too many refreshes. Please wait $_rateLimitMinutes minutes.',
          );
        }
      }
    }

    // First, load from cache for instant display
    final cachedProfile = await _tokenStorage.getCachedUserProfile();
    final hasCachedData = cachedProfile['email'] != null;

    if (hasCachedData && !fromRefresh) {
      // Show cached data immediately (no loading spinner)
      setState(() {
        _isLoading = false;
        _isIdentityVerified = cachedProfile['identityVerified'] == true;
        _fullNameController.text = cachedProfile['fullName'] ?? '';
        _firstNameController.text = cachedProfile['firstName'] ?? '';
        _lastNameController.text = cachedProfile['lastName'] ?? '';
        _emailController.text = cachedProfile['email'] ?? '';
        _profilePictureUrl = cachedProfile['profilePictureUrl'];

        // Handle phone - strip +216 prefix if present
        String phone = cachedProfile['phone'] ?? '';
        if (phone.startsWith('+216')) {
          phone = phone.substring(4);
        }
        _phoneController.text = phone;

        debugPrint('📱 Phone from cache: ${cachedProfile['phone']}');
        debugPrint(
          '📸 Profile picture from cache: ${cachedProfile['profilePictureUrl']}',
        );
      });
    }

    // Check if data is fresh (fetched within last 60 seconds) - skip for manual refresh
    if (!fromRefresh) {
      final isFresh = await _tokenStorage.isProfileDataFresh(
        thresholdSeconds: 60,
      );
      if (isFresh && hasCachedData) {
        debugPrint('📦 Profile data is fresh, skipping API fetch');
        return;
      }
    }

    // Fetch fresh data from API in background
    try {
      if (!hasCachedData && !fromRefresh) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final profile = await _profileApiService.getProfile();

      debugPrint('📱 Phone from API: ${profile.phone}');
      debugPrint('📸 Profile picture from API: ${profile.profilePictureUrl}');

      // Save to cache for next time
      await _tokenStorage.saveUserProfile(
        firstName: profile.firstName,
        lastName: profile.lastName,
        fullName: profile.fullName,
        email: profile.email,
        phone: profile.phone,
        profilePictureUrl: profile.profilePictureUrl,
        identityVerified: profile.identityVerified,
      );

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          _isIdentityVerified = profile.identityVerified;
          _profilePictureUrl = profile.profilePictureUrl;

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
      }
    } catch (e) {
      // Only show error if we don't have cached data
      if (!hasCachedData) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = ErrorSanitizer.message(e);
          });
        }
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
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        firstName: _firstNameController.text.trim().isEmpty
            ? null
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
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
        AppToast.error(context, ErrorSanitizer.message(e));
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
        AppToast.error(context, ErrorSanitizer.message(e));
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
        AppToast.error(context, ErrorSanitizer.message(e));
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
        AppToast.error(context, ErrorSanitizer.message(e));
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
        AppToast.error(context, ErrorSanitizer.message(e));
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
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
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
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
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
        RefreshIndicator(
          onRefresh: () => _loadProfile(fromRefresh: true),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            child: Column(
              children: [
                _buildAvatar(),
                const SizedBox(height: 32),

                // Full Name field - locked after identity verification
                _buildTextField(
                  label: l10n.fullName,
                  controller: _fullNameController,
                  isEditable: !_isIdentityVerified,
                  lockedReason: _isIdentityVerified ? l10n.nameLockedAfterVerification : null,
                ),
                const SizedBox(height: 16),

                // First Name field - locked after identity verification
                _buildTextField(
                  label: l10n.firstNameLabel,
                  controller: _firstNameController,
                  isEditable: !_isIdentityVerified,
                  lockedReason: _isIdentityVerified ? l10n.nameLockedAfterVerification : null,
                ),
                const SizedBox(height: 16),

                // Last Name field - locked after identity verification
                _buildTextField(
                  label: l10n.lastNameLabel,
                  controller: _lastNameController,
                  isEditable: !_isIdentityVerified,
                  lockedReason: _isIdentityVerified ? l10n.nameLockedAfterVerification : null,
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
                  colors: [AppColors.gray.withValues(alpha: 0), AppColors.gray],
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
      child: GestureDetector(
        onTap: _isUploadingPicture ? null : _showImagePickerOptions,
        child: Stack(
          children: [
            // Avatar container with profile picture or initials
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: _profilePictureUrl == null
                    ? const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [AppColors.secondary, AppColors.secondary],
                      )
                    : null,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _profilePictureUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: CachedNetworkImage(
                        imageUrl: _profilePictureUrl!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                        placeholder: (context, url) => Container(
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
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
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
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
                      ),
                    )
                  : Center(
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
            // Camera button or loading indicator
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
                child: _isUploadingPicture
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    final l10n = AppLocalizations.of(context)!;
    final hasPhoto = _profilePictureUrl != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  l10n.changeProfilePhoto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Rate limit warning if applicable
                if (!_canUpdateProfilePicture) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.profilePictureRateLimitWarning(
                              _profilePictureRateLimitRemainingTime,
                            ),
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (!_canUpdateProfilePicture) ...[
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 12),
                ],

                // Show add photo options only if no photo OR if can update
                if (!hasPhoto && _canUpdateProfilePicture) ...[
                  // Camera option
                  _buildPhotoOptionTile(
                    icon: Icons.camera_alt_rounded,
                    title: l10n.takePhoto,
                    subtitle: l10n.useCamera,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Gallery option
                  _buildPhotoOptionTile(
                    icon: Icons.photo_library_rounded,
                    title: l10n.chooseFromGallery,
                    subtitle: l10n.browsePhotos,
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],

                // Show remove option if has photo (delete is ALWAYS allowed, no rate limit)
                if (hasPhoto) ...[
                  _buildPhotoOptionTile(
                    icon: Icons.delete_outline_rounded,
                    title: l10n.removePhoto,
                    subtitle: l10n.deleteCurrentPhoto,
                    color: const Color(0xFFE53935),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmRemoveProfilePicture();
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: Colors.grey[600],
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
      ),
    );
  }

  /// Show confirmation dialog before removing profile picture
  void _confirmRemoveProfilePicture() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Warning icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFE53935),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n.removePhoto,
              style: const TextStyle(
                color: Color(0xFF13123A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.removeProfilePictureConfirmation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Remove button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.remove,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // Pick image with proper error handling
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024, // Allow larger size for better cropping
        maxHeight: 1024,
        imageQuality: 90,
        requestFullMetadata: false, // Helps with simulator issues
      );

      // User cancelled the picker
      if (pickedFile == null) {
        debugPrint('📸 Image picker: User cancelled');
        return;
      }

      debugPrint('📸 Image picked: ${pickedFile.path}');

      // Crop the image
      final croppedFile = await _cropImage(pickedFile.path);

      // User cancelled cropping
      if (croppedFile == null) {
        debugPrint('📸 Image cropper: User cancelled');
        return;
      }

      debugPrint('📸 Image cropped: ${croppedFile.path}');

      // Check if widget is still mounted before setState
      if (!mounted) return;

      setState(() => _isUploadingPicture = true);

      // Read the file bytes for upload
      final bytes = await croppedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Failed to read image file');
      }

      debugPrint('📸 Image size: ${bytes.length} bytes');

      final userId = await _tokenStorage.getUserId();
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final supabase = Supabase.instance.client;

      // Upload to the profile-pictures bucket using bytes
      final uploadPath = 'public/$fileName';
      await supabase.storage
          .from('profile-pictures')
          .uploadBinary(
            uploadPath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
              upsert: true,
            ),
          );

      debugPrint('📸 Upload successful: $uploadPath');

      // Get the public URL
      final publicUrl = supabase.storage
          .from('profile-pictures')
          .getPublicUrl(uploadPath);

      debugPrint('📸 Public URL: $publicUrl');

      // Delete old profile picture from Supabase if exists
      final oldUrl = _profilePictureUrl;
      if (oldUrl != null && oldUrl.contains('supabase.co/storage')) {
        try {
          final uri = Uri.parse(oldUrl);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('profile-pictures');
          if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await supabase.storage.from('profile-pictures').remove([filePath]);
            debugPrint('📸 Deleted old profile picture: $filePath');
          }
        } catch (e) {
          debugPrint('📸 Warning: Could not delete old image: $e');
        }
      }

      // Update the profile picture URL in backend
      final updatedProfile = await _profileApiService.updateProfilePicture(
        publicUrl,
      );

      if (mounted) {
        setState(() {
          _profilePictureUrl = updatedProfile.profilePictureUrl;
          _isUploadingPicture = false;
          // Update rate limit status - can't change again for 24h
          _canUpdateProfilePicture = false;
          _nextAllowedProfilePictureUpdate = DateTime.now().add(
            const Duration(hours: 24),
          );
        });
        _startProfilePictureRateLimitTimer();

        AppToast.success(context, l10n.profilePictureUpdated);
      }
    } catch (e, stackTrace) {
      debugPrint('📸 Error picking/uploading image: $e');
      debugPrint('📸 Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isUploadingPicture = false);
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // Provide user-friendly error messages
        if (errorMessage.contains('permission') ||
            errorMessage.contains('denied')) {
          errorMessage = l10n.photoPermissionDenied;
        } else if (errorMessage.contains('storage') ||
            errorMessage.contains('bucket')) {
          errorMessage = l10n.uploadFailed;
        }

        AppToast.error(context, errorMessage);
      }
    }
  }

  /// Crop the selected image with a circular preview
  Future<CroppedFile?> _cropImage(String imagePath) async {
    return await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLocalizations.of(context)?.cropPhoto ?? 'Crop Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.secondary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: AppLocalizations.of(context)?.cropPhoto ?? 'Crop Photo',
          doneButtonTitle: AppLocalizations.of(context)?.done ?? 'Done',
          cancelButtonTitle: AppLocalizations.of(context)?.cancel ?? 'Cancel',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
  }

  Future<void> _removeProfilePicture() async {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) return;
    setState(() => _isUploadingPicture = true);

    try {
      // Get the current profile picture URL before removal (to delete from Supabase)
      final oldUrl = _profilePictureUrl;

      // Call API to remove profile picture
      final updatedProfile = await _profileApiService.removeProfilePicture();

      // Try to delete the old image from Supabase storage
      if (oldUrl != null && oldUrl.contains('supabase.co/storage')) {
        try {
          // Extract the file path from the URL
          final uri = Uri.parse(oldUrl);
          final pathSegments = uri.pathSegments;
          // Path format: storage/v1/object/public/profile-pictures/public/filename.jpg
          final bucketIndex = pathSegments.indexOf('profile-pictures');
          if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await Supabase.instance.client.storage
                .from('profile-pictures')
                .remove([filePath]);
            debugPrint(
              '📸 Deleted old profile picture from storage: $filePath',
            );
          }
        } catch (e) {
          // Ignore storage deletion errors - the main operation succeeded
          debugPrint('📸 Warning: Could not delete old image from storage: $e');
        }
      }

      if (mounted) {
        setState(() {
          _profilePictureUrl = updatedProfile.profilePictureUrl;
          _isUploadingPicture = false;
          // Delete does NOT update rate limit - only upload does
          // The rate limit timer stays based on last UPLOAD time
        });

        AppToast.success(context, l10n.profilePictureRemoved);
        
        // Refresh rate limit status from backend to get accurate state
        _loadProfilePictureRateLimitStatus();
      }
    } catch (e) {
      debugPrint('📸 Error removing profile picture: $e');

      if (mounted) {
        setState(() => _isUploadingPicture = false);
        String errorMessage = ErrorSanitizer.message(e, fallback: l10n.anErrorOccurred);
        AppToast.error(context, errorMessage);
      }
    }
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
    String? lockedReason,
  }) {
    final isLocked = lockedReason != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (isLocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      lockedReason,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
          child: Row(
            children: [
              Expanded(
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
              if (isLocked)
                Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
            border: Border.all(color: const Color(0xFFE0E0E6), width: 1),
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
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (!_isVerifyingCurrentEmail) ...[
              Text(
                l10n.verifyCurrentEmailDesc,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                  style: const TextStyle(color: AppColors.dark, fontSize: 14),
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
                    Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.primary,
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
          color: canResend
              ? AppColors.secondary.withValues(alpha: 0.1)
              : Colors.grey[100],
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
            border: Border.all(color: AppColors.secondary, width: 1),
          ),
          child: Row(
            children: [
              // Tunisia flag and code
              Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE0E0E6), width: 1),
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
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                ? [
                    AppColors.primary.withValues(alpha: 0.6),
                    AppColors.primary.withValues(alpha: 0.6),
                  ]
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
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), redPaint);

    // White circle in center
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final circleRadius = size.height * 0.35;

    canvas.drawCircle(Offset(centerX, centerY), circleRadius, whitePaint);

    // Red crescent (using two circles)
    final crescentOuterRadius = circleRadius * 0.85;
    final crescentInnerRadius = circleRadius * 0.65;
    final crescentOffset = circleRadius * 0.2;

    // Draw outer red circle for crescent
    canvas.drawCircle(Offset(centerX, centerY), crescentOuterRadius, redPaint);

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
