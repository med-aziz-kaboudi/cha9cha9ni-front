import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/family_model.dart';
import '../../core/services/family_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_toast.dart';
import '../../l10n/app_localizations.dart';

/// Screen for transferring family ownership to another member
class TransferOwnershipScreen extends StatefulWidget {
  final List<FamilyMember> members;
  final String currentUserId;

  const TransferOwnershipScreen({
    super.key,
    required this.members,
    required this.currentUserId,
  });

  @override
  State<TransferOwnershipScreen> createState() =>
      _TransferOwnershipScreenState();
}

class _TransferOwnershipScreenState extends State<TransferOwnershipScreen> {
  final _familyApi = FamilyApiService();
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  // Rate limiting constants
  static const String _transferAttemptKey = 'transfer_ownership_attempts';
  static const String _transferBlockedUntilKey =
      'transfer_ownership_blocked_until';
  static const int _maxTransferAttempts = 3;
  static const int _blockDurationMinutes = 15;

  bool _isLoading = true;
  bool _canTransfer = false;
  String? _blockedReason;
  FamilyMember? _selectedMember;
  String? _requestId;
  bool _isCodeStep = false;
  bool _isProcessing = false;
  String? _error;
  bool _isRateLimited = false;
  int _rateLimitRemainingMinutes = 0;

  @override
  void initState() {
    super.initState();
    _checkRateLimitAndCanTransfer();
    // Note: Don't listen to ownership transfer here - home screen handles the navigation
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Check rate limiting first, then check if user can transfer
  Future<void> _checkRateLimitAndCanTransfer() async {
    setState(() => _isLoading = true);

    // Check rate limit first
    final prefs = await SharedPreferences.getInstance();
    final blockedUntil = prefs.getInt(_transferBlockedUntilKey);

    if (blockedUntil != null) {
      final blockedUntilTime = DateTime.fromMillisecondsSinceEpoch(
        blockedUntil,
      );
      if (DateTime.now().isBefore(blockedUntilTime)) {
        // Still blocked
        final remaining = blockedUntilTime.difference(DateTime.now()).inMinutes;
        if (mounted) {
          setState(() {
            _isRateLimited = true;
            _rateLimitRemainingMinutes = remaining > 0 ? remaining + 1 : 1;
            _canTransfer = false;
            _isLoading = false;
          });
        }
        return;
      } else {
        // Block expired, clear it
        await prefs.remove(_transferBlockedUntilKey);
        await prefs.remove(_transferAttemptKey);
      }
    }

    // Now check if transfer is allowed from backend
    await _checkCanTransfer();
  }

  Future<void> _checkCanTransfer() async {
    try {
      final result = await _familyApi.canTransferOwnership();
      if (mounted) {
        setState(() {
          _canTransfer = result['canTransfer'] == true;
          _blockedReason = result['reason'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canTransfer = false;
          _blockedReason = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Increment transfer attempt and check if should block
  Future<bool> _incrementTransferAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = prefs.getInt(_transferAttemptKey) ?? 0;
    attempts++;
    await prefs.setInt(_transferAttemptKey, attempts);

    if (attempts >= _maxTransferAttempts) {
      // Block for 15 minutes
      final blockedUntil = DateTime.now().add(
        Duration(minutes: _blockDurationMinutes),
      );
      await prefs.setInt(
        _transferBlockedUntilKey,
        blockedUntil.millisecondsSinceEpoch,
      );
      return true; // Now blocked
    }
    return false;
  }

  /// Reset transfer attempts on successful transfer
  Future<void> _resetTransferAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transferAttemptKey);
    await prefs.remove(_transferBlockedUntilKey);
  }

  List<FamilyMember> get _eligibleMembers {
    return widget.members
        .where((m) => m.id != widget.currentUserId && !m.isOwner)
        .toList();
  }

  Future<void> _initiateTransfer() async {
    if (_selectedMember == null) return;

    // Check rate limit before initiating
    final prefs = await SharedPreferences.getInstance();
    final blockedUntil = prefs.getInt(_transferBlockedUntilKey);
    if (blockedUntil != null) {
      final blockedUntilTime = DateTime.fromMillisecondsSinceEpoch(
        blockedUntil,
      );
      if (DateTime.now().isBefore(blockedUntilTime)) {
        final remaining = blockedUntilTime.difference(DateTime.now()).inMinutes;
        if (mounted) {
          setState(() {
            _isRateLimited = true;
            _rateLimitRemainingMinutes = remaining > 0 ? remaining + 1 : 1;
            _canTransfer = false;
          });
          AppToast.error(
            context,
            'Trop de tentatives. Réessayez dans $_rateLimitRemainingMinutes minutes.',
          );
        }
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await _familyApi.initiateTransfer(_selectedMember!.id);

      // Increment attempt counter
      final nowBlocked = await _incrementTransferAttempt();

      if (mounted) {
        setState(() {
          _requestId = result['requestId'] as String?;
          _isCodeStep = true;
          _isProcessing = false;
          if (nowBlocked) {
            _isRateLimited = true;
            _rateLimitRemainingMinutes = _blockDurationMinutes;
          }
        });
        // Focus the code input
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmTransfer() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(
        () => _error =
            AppLocalizations.of(context)?.enterAllDigits ??
            'Please enter all 6 digits',
      );
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await _familyApi.confirmTransfer(_requestId!, code);

      // Reset rate limiting on successful transfer
      await _resetTransferAttempts();

      if (mounted) {
        HapticFeedback.mediumImpact();
        AppToast.success(
          context,
          AppLocalizations.of(context)?.ownershipTransferredSuccess ??
              'Ownership transferred successfully!',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isProcessing = false;
        });
        _codeController.clear();
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _cancelTransfer() async {
    if (_requestId != null) {
      try {
        await _familyApi.cancelTransfer(_requestId!);
      } catch (e) {
        debugPrint('Failed to cancel transfer: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isCodeStep = false;
        _requestId = null;
        _codeController.clear();
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () {
            if (_isCodeStep) {
              _cancelTransfer();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          l10n.transferOwnership,
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: screenHeight * 0.022,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _isRateLimited
            ? _buildRateLimitedView(l10n, screenHeight, screenWidth)
            : !_canTransfer
            ? _buildBlockedView(l10n, screenHeight, screenWidth)
            : _isCodeStep
            ? _buildCodeStep(l10n, screenHeight, screenWidth)
            : _buildMemberSelection(l10n, screenHeight, screenWidth),
      ),
    );
  }

  Widget _buildBlockedView(
    AppLocalizations l10n,
    double screenHeight,
    double screenWidth,
  ) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenHeight * 0.12,
            height: screenHeight * 0.12,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: screenHeight * 0.06,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            l10n.transferOwnershipBlocked,
            style: TextStyle(
              fontSize: screenHeight * 0.024,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            _blockedReason ?? l10n.transferOwnershipBlockedDesc,
            style: TextStyle(
              fontSize: screenHeight * 0.016,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.04),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber[700],
                  size: screenHeight * 0.025,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    l10n.transferOwnershipWithdrawalNote,
                    style: TextStyle(
                      fontSize: screenHeight * 0.014,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitedView(
    AppLocalizations l10n,
    double screenHeight,
    double screenWidth,
  ) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenHeight * 0.12,
            height: screenHeight * 0.12,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              size: screenHeight * 0.06,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            l10n.tooManyAttemptsTitle,
            style: TextStyle(
              fontSize: screenHeight * 0.024,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            l10n.tooManyAttempts(_rateLimitRemainingMinutes),
            style: TextStyle(
              fontSize: screenHeight * 0.016,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.04),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: screenHeight * 0.025,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    'Vous avez effectué trop de tentatives de transfert. Veuillez patienter avant de réessayer.',
                    style: TextStyle(
                      fontSize: screenHeight * 0.014,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.06,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.back,
                style: TextStyle(
                  fontSize: screenHeight * 0.018,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSelection(
    AppLocalizations l10n,
    double screenHeight,
    double screenWidth,
  ) {
    final eligibleMembers = _eligibleMembers;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning box
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primary,
                  size: screenHeight * 0.03,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    l10n.transferOwnershipWarning,
                    style: TextStyle(
                      fontSize: screenHeight * 0.014,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.03),

          Text(
            l10n.selectNewOwner,
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),

          SizedBox(height: screenHeight * 0.015),

          if (eligibleMembers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: screenHeight * 0.08,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      l10n.noEligibleMembers,
                      style: TextStyle(
                        fontSize: screenHeight * 0.016,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: eligibleMembers.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: screenHeight * 0.01),
                itemBuilder: (context, index) {
                  final member = eligibleMembers[index];
                  final isSelected = _selectedMember?.id == member.id;

                  return InkWell(
                    onTap: () => setState(() => _selectedMember = member),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: screenHeight * 0.028,
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: member.profilePictureUrl != null
                                ? NetworkImage(member.profilePictureUrl!)
                                : null,
                            child: member.profilePictureUrl == null
                                ? Text(
                                    member.name.isNotEmpty
                                        ? member.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenHeight * 0.02,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.016,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                Text(
                                  member.email,
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.013,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: screenHeight * 0.028,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.015),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenHeight * 0.014,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.06,
            child: ElevatedButton(
              onPressed: _selectedMember != null && !_isProcessing
                  ? _initiateTransfer
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: screenHeight * 0.025,
                      height: screenHeight * 0.025,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.continueButton,
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(
    AppLocalizations l10n,
    double screenHeight,
    double screenWidth,
  ) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.03),

          Icon(
            Icons.email_outlined,
            size: screenHeight * 0.08,
            color: AppColors.primary,
          ),

          SizedBox(height: screenHeight * 0.02),

          Text(
            l10n.verifyTransfer,
            style: TextStyle(
              fontSize: screenHeight * 0.024,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: screenHeight * 0.015),

          Text(
            l10n.transferCodeSent,
            style: TextStyle(
              fontSize: screenHeight * 0.015,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: screenHeight * 0.04),

          // Code input
          TextField(
            controller: _codeController,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: TextStyle(
              fontSize: screenHeight * 0.035,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
              color: AppColors.secondary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: TextStyle(
                fontSize: screenHeight * 0.035,
                fontWeight: FontWeight.w400,
                letterSpacing: 8,
                color: Colors.grey[300],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.length == 6) {
                _confirmTransfer();
              }
            },
          ),

          if (_error != null)
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.015),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenHeight * 0.014,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          SizedBox(height: screenHeight * 0.015),

          Text(
            l10n.codeExpiresInfo,
            style: TextStyle(
              fontSize: screenHeight * 0.013,
              color: Colors.grey[500],
            ),
          ),

          const Spacer(),

          // Transfer to info box
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: screenHeight * 0.025,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  backgroundImage: _selectedMember?.profilePictureUrl != null
                      ? NetworkImage(_selectedMember!.profilePictureUrl!)
                      : null,
                  child: _selectedMember?.profilePictureUrl == null
                      ? Text(
                          _selectedMember?.name.isNotEmpty == true
                              ? _selectedMember!.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transferringTo,
                        style: TextStyle(
                          fontSize: screenHeight * 0.012,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _selectedMember?.name ?? '',
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.06,
            child: ElevatedButton(
              onPressed: !_isProcessing ? _confirmTransfer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: screenHeight * 0.025,
                      height: screenHeight * 0.025,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.confirmTransfer,
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          SizedBox(height: screenHeight * 0.015),

          TextButton(
            onPressed: !_isProcessing ? _cancelTransfer : null,
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: screenHeight * 0.015,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
