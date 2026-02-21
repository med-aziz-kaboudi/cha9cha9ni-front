import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../pack_models.dart';
import '../pack_api_service.dart';
import '../pack_service.dart';

/// Screen for selecting Tunisian aids for withdrawal
class AidSelectionScreen extends StatefulWidget {
  final List<AidModel> allAids;
  final List<SelectedAidModel> selectedAids;
  final int maxAidsSelectable;

  const AidSelectionScreen({
    super.key,
    required this.allAids,
    required this.selectedAids,
    required this.maxAidsSelectable,
  });

  @override
  State<AidSelectionScreen> createState() => _AidSelectionScreenState();
}

class _AidSelectionScreenState extends State<AidSelectionScreen> {
  final _apiService = PackApiService();
  final _packService = PackService();

  late List<SelectedAidModel> _selectedAids;
  late List<AidModel> _allAids;
  bool _isSelecting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAids = List.from(widget.selectedAids);
    _allAids = List.from(widget.allAids);

    // If allAids is empty, fetch from API (fallback)
    if (_allAids.isEmpty) {
      _fetchAids();
    }
  }

  Future<void> _fetchAids() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAllAids();
      if (mounted) {
        setState(() {
          _allAids = data.aids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load aids');
      }
    }
  }

  IconData _getAidIcon(String aidName) {
    switch (aidName) {
      case 'aid_kbir':
      case 'aid_sghir':
        return Icons.mosque_rounded;
      case 'ramadan':
        return Icons.nightlight_round;
      case 'valentine':
        return Icons.favorite_rounded;
      case 'new_year':
        return Icons.celebration_rounded;
      case 'back_to_school':
        return Icons.school_rounded;
      case 'mothers_day':
        return Icons.favorite_rounded;
      case 'womens_day':
        return Icons.female_rounded;
      case 'mouled':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  Color _getAidColor(String aidName) {
    switch (aidName) {
      case 'aid_kbir':
      case 'aid_sghir':
        return const Color(0xFF10B981);
      case 'ramadan':
        return const Color(0xFF8B5CF6);
      case 'valentine':
        return const Color(0xFFEC4899);
      case 'new_year':
        return const Color(0xFFF59E0B);
      case 'back_to_school':
        return const Color(0xFF3B82F6);
      case 'mothers_day':
        return const Color(0xFFF472B6);
      case 'womens_day':
        return const Color(0xFFEC4899);
      case 'mouled':
        return const Color(0xFF14B8A6);
      default:
        return AppColors.primary;
    }
  }

  bool _isAidSelected(AidModel aid) {
    return _selectedAids.any((s) => s.aidId == aid.id);
  }

  Future<void> _selectAid(AidModel aid) async {
    if (_isSelecting) return;

    if (_isAidSelected(aid)) {
      AppToast.warning(
        context,
        AppLocalizations.of(context)!.aidAlreadySelected,
      );
      return;
    }

    if (_selectedAids.length >= widget.maxAidsSelectable) {
      AppToast.warning(
        context,
        AppLocalizations.of(context)!.maxAidsReached(widget.maxAidsSelectable),
      );
      return;
    }

    final confirmed = await _showConfirmationSheet(aid);
    if (confirmed != true) return;

    setState(() => _isSelecting = true);
    HapticFeedback.mediumImpact();

    try {
      await _apiService.selectAid(aid.id);

      final newSelectedAid = SelectedAidModel(
        id: '',
        aidId: aid.id,
        aidName: aid.name,
        aidDisplayName: aid.displayName,
        maxWithdrawal: aid.maxWithdrawal,
        aidStartDate: aid.aidStartDate,
        aidEndDate: aid.aidEndDate,
        withdrawalStartDate: aid.withdrawalStartDate,
        withdrawalEndDate: aid.withdrawalEndDate,
        status: 'selected',
      );

      setState(() {
        _selectedAids.add(newSelectedAid);
      });

      await _packService.fetchCurrentPack(forceRefresh: true);

      if (mounted) {
        HapticFeedback.heavyImpact();
        AppToast.success(
          context,
          AppLocalizations.of(context)!.aidSelectedSuccess(aid.displayName),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSelecting = false);
      }
    }
  }

  Future<bool?> _showConfirmationSheet(AidModel aid) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getAidColor(aid.name);
    // Next year selection: either backend says so, or deadline passed for current year
    final isNextYearSelection = aid.canSelectForNextYear || !aid.canSelect;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 28),

            // Next year badge at top if applicable
            if (isNextYearSelection) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.selectForYear(aid.selectionForYear ?? (DateTime.now().year + 1)),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(_getAidIcon(aid.name), color: color, size: 44),
            ),
            const SizedBox(height: 24),

            Text(
              l10n.selectAidConfirmTitle,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              aid.displayName,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Show next year withdrawal window if applicable
            if (isNextYearSelection) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.withdrawalWindow,
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            aid.getNextYearWithdrawalWindowDisplay(),
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Max withdrawal box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.maxWithdrawal,
                          style: TextStyle(
                            color: AppColors.dark.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${aid.maxWithdrawal} DT',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Next year savings hint or warning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isNextYearSelection 
                    ? Colors.blue.withOpacity(0.08)
                    : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isNextYearSelection 
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isNextYearSelection 
                        ? Icons.event_available_rounded
                        : Icons.info_outline_rounded,
                    color: isNextYearSelection 
                        ? Colors.blue[700]
                        : Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isNextYearSelection 
                          ? l10n.savingForNextYearHint
                          : l10n.aidSelectionWarning,
                      style: TextStyle(
                        fontSize: 13,
                        color: isNextYearSelection 
                            ? Colors.blue[800]
                            : Colors.orange[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Buttons - stacked vertically for better look
            GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: isNextYearSelection ? Colors.blue : AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isNextYearSelection ? Colors.blue : AppColors.secondary).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isNextYearSelection 
                          ? Icons.event_available_rounded
                          : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isNextYearSelection 
                          ? l10n.saveForNextYear
                          : l10n.confirmSelection,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                ),
                child: Center(
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
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isRTL = locale.languageCode == 'ar';
    final remainingSelections = widget.maxAidsSelectable - _selectedAids.length;

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
                          color: AppColors.primary,
                        ),
                      )
                    : _buildContent(l10n, remainingSelections),
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
            l10n.selectAid,
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

  Widget _buildContent(AppLocalizations l10n, int remainingSelections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _buildHeaderCard(l10n, remainingSelections),
          const SizedBox(height: 28),

          // Selected aids section
          if (_selectedAids.isNotEmpty) ...[
            _buildSectionHeader(
              l10n.yourSelectedAids,
              Icons.check_circle_rounded,
              AppColors.secondary,
            ),
            const SizedBox(height: 14),
            ..._selectedAids.map((selected) {
              final aid = _allAids.firstWhere(
                (a) => a.id == selected.aidId,
                orElse: () => AidModel(
                  id: selected.aidId,
                  name: selected.aidName,
                  displayName: selected.aidDisplayName,
                  maxWithdrawal: selected.maxWithdrawal,
                  isWithinWindow: true,
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSelectedAidCard(aid, selected, l10n),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Available aids section
          _buildSectionHeader(
            l10n.availableAids,
            Icons.card_giftcard_rounded,
            AppColors.primary,
          ),
          const SizedBox(height: 14),

          if (_allAids.isEmpty)
            _buildEmptyState(l10n)
          else
            ..._allAids.map(
              (aid) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAidCard(aid, l10n, remainingSelections > 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n, int remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.secondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tunisianAids,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: remaining > 0
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.selectionsRemaining(
                          remaining,
                          widget.maxAidsSelectable,
                        ),
                        style: TextStyle(
                          color: remaining > 0
                              ? const Color(0xFF10B981)
                              : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE4B5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.amber[700],
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.aidSelectionHint,
                    style: TextStyle(
                      color: Colors.amber[900],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.packBasedWithdrawalHint,
                    style: TextStyle(
                      color: AppColors.secondary.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.4,
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAidCard(
    AidModel aid,
    SelectedAidModel selected,
    AppLocalizations l10n,
  ) {
    final color = _getAidColor(aid.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getAidIcon(aid.name), color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        aid.displayName,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.selected,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.maxWithdrawal}: ',
                        style: TextStyle(
                          color: AppColors.dark.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${selected.maxWithdrawal} DT',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected.withdrawalStartDate != null &&
                    selected.withdrawalEndDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.withdrawWindowLabel(
                            selected
                                .getWithdrawalWindowDisplay()
                                .split(' - ')
                                .first,
                            selected
                                .getWithdrawalWindowDisplay()
                                .split(' - ')
                                .last,
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Show if withdrawal window is open
                  if (selected.isWithinWithdrawalWindow)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.withdrawWindowOpen,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAidCard(
    AidModel aid,
    AppLocalizations l10n,
    bool canSelectMore,
  ) {
    final isSelected = _isAidSelected(aid);
    final color = _getAidColor(aid.name);
    // Check if this is a next year selection (deadline for current year passed)
    final isNextYearSelection = aid.canSelectForNextYear || (!aid.canSelect && canSelectMore);
    // User can select if: not already selected, has remaining slots, and aid allows selection (current or next year)
    final canSelectThisAid = !isSelected && canSelectMore && (aid.canSelect || isNextYearSelection);

    return GestureDetector(
      onTap: canSelectThisAid && !_isSelecting ? () => _selectAid(aid) : null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top section with aid info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(isSelected ? 0.06 : 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getAidIcon(aid.name),
                      color: isSelected ? color.withOpacity(0.4) : color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aid.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.dark.withOpacity(0.4)
                                : AppColors.dark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Show aid dates (next year dates if selecting for next year)
                        if (aid.aidStartDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 12,
                                color: isSelected
                                    ? Colors.grey[300]
                                    : color.withOpacity(0.7),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isNextYearSelection
                                    ? aid.getNextYearAidDatesDisplay()
                                    : aid.getAidDatesDisplay(),
                                style: TextStyle(
                                  color: isSelected ? Colors.grey[400] : color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Show withdrawal window with "Withdraw from ... to ..."
                        if (aid.withdrawalStartDate != null &&
                            aid.withdrawalEndDate != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: isSelected
                                    ? Colors.grey[300]
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  isNextYearSelection
                                      ? l10n.withdrawWindowLabel(
                                          aid.getNextYearWithdrawalWindowDisplay().split(' - ').first,
                                          aid.getNextYearWithdrawalWindowDisplay().split(' - ').last.split(',').first,
                                        )
                                      : l10n.withdrawWindowLabel(
                                          aid
                                              .getWithdrawalWindowDisplay()
                                              .split(' - ')
                                              .first,
                                          aid
                                              .getWithdrawalWindowDisplay()
                                              .split(' - ')
                                              .last,
                                        ),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Show next year badge if this is a next year selection
                        if (isNextYearSelection && !isSelected) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.selectForYear(aid.selectionForYear ?? (DateTime.now().year + 1)),
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Show days until aid or withdrawal window status
                        if (!isSelected && aid.daysUntilAid != null && !isNextYearSelection) ...[
                          const SizedBox(height: 2),
                          Text(
                            aid.isWithinWindow
                                ? l10n.withdrawWindowOpen
                                : aid.getDaysUntilAidDisplay(),
                            style: TextStyle(
                              color: aid.isWithinWindow
                                  ? AppColors.secondary
                                  : Colors.orange[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B981),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.selected,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom section - withdrawal amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.grey[50] : AppColors.gray,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.withdrawalLimit,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${aid.maxWithdrawal}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.grey[400]
                                    : AppColors.dark,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'DT',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Selection button - allow selection for current year OR next year
                  if (!isSelected && canSelectMore) ...[
                    // Can select (either for this year or next year)
                    if (canSelectThisAid)
                      GestureDetector(
                        onTap: _isSelecting ? null : () => _selectAid(aid),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isNextYearSelection 
                                ? Colors.blue 
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isSelecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isNextYearSelection) ...[
                                      const Icon(
                                        Icons.event_available_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      isNextYearSelection 
                                          ? l10n.saveForNextYear 
                                          : l10n.select,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )
                    // Deadline fully passed, aid already ended this year - can't select anymore
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.deadlinePassed,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ] else if (!isSelected && !canSelectMore)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.limitReached,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No aids available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchAids,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
