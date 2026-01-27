import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../pack_models.dart';
import '../pack_api_service.dart';

/// Screen for selecting Tunisian aids for withdrawal
class AidSelectionScreen extends StatefulWidget {
  const AidSelectionScreen({super.key});

  @override
  State<AidSelectionScreen> createState() => _AidSelectionScreenState();
}

class _AidSelectionScreenState extends State<AidSelectionScreen> {
  final _apiService = PackApiService();
  
  List<AidModel>? _aids;
  List<SelectedAidModel>? _selectedAids;
  int _maxAidsSelectable = 1;
  bool _isLoading = true;
  bool _isSelecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getAllAids(),
        _apiService.getCurrentPack(),
      ]);
      
      if (mounted) {
        final aidsData = results[0] as AllAidsData;
        final packData = results[1] as CurrentPackData;
        
        setState(() {
          _aids = aidsData.aids;
          _selectedAids = packData.selectedAids;
          _maxAidsSelectable = packData.pack.maxAidsSelectable;
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
      case 'independence_day':
      case 'revolution_day':
        return Icons.flag_rounded;
      case 'mothers_day':
      case 'womens_day':
        return Icons.female_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  Color _getAidColor(String aidName) {
    switch (aidName) {
      case 'aid_kbir':
      case 'aid_sghir':
        return const Color(0xFF10B981); // Green
      case 'ramadan':
        return const Color(0xFF8B5CF6); // Purple
      case 'valentine':
        return const Color(0xFFEC4899); // Pink
      case 'new_year':
        return const Color(0xFFF59E0B); // Amber
      case 'back_to_school':
        return const Color(0xFF3B82F6); // Blue
      case 'independence_day':
      case 'revolution_day':
        return const Color(0xFFEF4444); // Red
      case 'mothers_day':
      case 'womens_day':
        return const Color(0xFFEC4899); // Pink
      default:
        return AppColors.primary;
    }
  }

  bool _isAidSelected(AidModel aid) {
    return _selectedAids?.any((s) => s.aidId == aid.id) ?? false;
  }

  Future<void> _selectAid(AidModel aid) async {
    if (_isSelecting) return;
    
    // Check if already selected
    if (_isAidSelected(aid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.aidAlreadySelected),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if max aids reached
    if ((_selectedAids?.length ?? 0) >= _maxAidsSelectable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.maxAidsReached(_maxAidsSelectable)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirm selection
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.selectAidConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.selectAidConfirmMessage(aid.displayName)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.aidSelectionWarning,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSelecting = true);

    try {
      await _apiService.selectAid(aid.id);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.aidSelectedSuccess(aid.displayName)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEF1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.selectAid,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(l10n),
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
    if (_aids == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            Text(
                              l10n.selectionsRemaining(
                                _maxAidsSelectable - (_selectedAids?.length ?? 0),
                                _maxAidsSelectable,
                              ),
                              style: TextStyle(
                                color: AppColors.dark.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.aidSelectionDescription,
                    style: TextStyle(
                      color: AppColors.dark.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selected Aids
            if (_selectedAids != null && _selectedAids!.isNotEmpty) ...[
              Text(
                l10n.yourSelectedAids,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ..._selectedAids!.map((selected) {
                final aid = _aids!.firstWhere(
                  (a) => a.id == selected.aidId,
                  orElse: () => AidModel(
                    id: selected.aidId,
                    name: selected.aidName,
                    displayName: selected.aidDisplayName,
                    description: '',
                    maxWithdrawal: selected.maxWithdrawal,
                    isWithinWindow: true,
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSelectedAidCard(aid, selected),
                );
              }),
              const SizedBox(height: 16),
            ],
            
            // Available Aids
            Text(
              l10n.availableAids,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            
            ..._aids!.map((aid) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAidCard(aid),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAidCard(AidModel aid, SelectedAidModel selected) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getAidColor(aid.name);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getAidIcon(aid.name), color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        aid.displayName,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          l10n.selected,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.maxWithdrawal}: ${selected.maxWithdrawal} DT',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (selected.windowStart != null && selected.windowEnd != null)
                    Text(
                      '${l10n.window}: ${_formatWindow(selected.windowStart!, selected.windowEnd!)}',
                      style: TextStyle(
                        color: AppColors.dark.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: AppColors.secondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAidCard(AidModel aid) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _isAidSelected(aid);
    final color = _getAidColor(aid.name);
    final canSelect = !isSelected && (_selectedAids?.length ?? 0) < _maxAidsSelectable;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSelect ? () => _selectAid(aid) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getAidIcon(aid.name), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aid.displayName,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.dark.withOpacity(0.5)
                              : AppColors.dark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (aid.description != null && aid.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          aid.description!,
                          style: TextStyle(
                            color: AppColors.dark.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (aid.windowStart != null && aid.windowEnd != null)
                        Text(
                          '${l10n.window}: ${_formatWindow(aid.windowStart!, aid.windowEnd!)}',
                          style: TextStyle(
                            color: AppColors.dark.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.secondary,
                    size: 24,
                  )
                else if (canSelect)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      l10n.select,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.block,
                    color: Colors.grey[400],
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatWindow(String start, String end) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final startParts = start.split('-');
    final endParts = end.split('-');
    
    if (startParts.length >= 2 && endParts.length >= 2) {
      final startMonth = int.parse(startParts[0]);
      final startDay = int.parse(startParts[1]);
      final endMonth = int.parse(endParts[0]);
      final endDay = int.parse(endParts[1]);
      
      return '${months[startMonth - 1]} $startDay - ${months[endMonth - 1]} $endDay';
    }
    
    return '$start - $end';
  }
}
