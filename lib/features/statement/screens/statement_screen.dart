import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../../rewards/rewards_model.dart';
import '../../activity/activity_service.dart';
import '../../profile/services/profile_api_service.dart';
import '../../rewards/rewards_service.dart';
import '../services/pdf_statement_service.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen>
    with SingleTickerProviderStateMixin {
  final _activityService = ActivityService();
  final _profileService = ProfileApiService();
  final _rewardsService = RewardsService();
  final _pdfService = PdfStatementService();
  final _analytics = AnalyticsService();

  List<RewardActivity> _allActivities = [];
  StreamSubscription<List<RewardActivity>>? _subscription;

  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  String _userName = '';
  String _userEmail = '';
  String _familyName = '';
  int _currentBalance = 0;
  DateTime? _accountCreatedAt;

  int? _selectedYear;
  int? _selectedMonth;

  List<int> _availableYears = [];
  List<int> _availableMonths = [];

  // Rate limiting - max 2 emails per day (per user)
  static const int _maxEmailsPerDay = 2;
  static const String _emailCountKeyPrefix = 'statement_email_count_';
  static const String _emailDateKeyPrefix = 'statement_email_date_';
  int _emailsSentToday = 0;

  // Get user-specific key for rate limiting
  String get _emailCountKey => '$_emailCountKeyPrefix$_userEmail';
  String get _emailDateKey => '$_emailDateKeyPrefix$_userEmail';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _analytics.trackScreenView('statement_screen');

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _initializeData();

    _subscription = _activityService.activitiesStream.listen((activities) {
      if (mounted) {
        setState(() {
          _allActivities = activities;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animController.dispose();
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final profile = await _profileService.getProfile();
      final rewardsData = await _rewardsService.fetchRewardsData();

      await _activityService.initialize();
      await _activityService.refresh();

      if (mounted) {
        setState(() {
          _userName = profile.displayName;
          _userEmail = profile.email;
          _accountCreatedAt = profile.createdAt;
          _currentBalance = rewardsData.totalPoints;
          _familyName = rewardsData.familyName;
          _allActivities = _activityService.activities;

          _buildAvailableYears();
          _isLoading = false;
        });
        // Load rate limit after email is set (user-specific)
        await _loadEmailRateLimit();
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context)!;
        AppToast.error(context, l10n.statementLoadError);
      }
    }
  }

  /// Load rate limit data from SharedPreferences
  Future<void> _loadEmailRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_emailDateKey);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    if (savedDate == today) {
      // Same day, load the count
      setState(() {
        _emailsSentToday = prefs.getInt(_emailCountKey) ?? 0;
      });
    } else {
      // New day, reset the count
      await prefs.setString(_emailDateKey, today);
      await prefs.setInt(_emailCountKey, 0);
      setState(() {
        _emailsSentToday = 0;
      });
    }
  }

  /// Check if user can send more emails today
  bool _canSendEmail() {
    return _emailsSentToday < _maxEmailsPerDay;
  }

  /// Get remaining email sends for today
  int _getRemainingEmails() {
    return _maxEmailsPerDay - _emailsSentToday;
  }

  /// Increment the email count after successful send
  Future<void> _incrementEmailCount() async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = _emailsSentToday + 1;
    await prefs.setInt(_emailCountKey, newCount);
    setState(() {
      _emailsSentToday = newCount;
    });
  }

  void _buildAvailableYears() {
    if (_accountCreatedAt == null) return;

    final startYear = _accountCreatedAt!.year;
    final currentYear = DateTime.now().year;

    _availableYears = List.generate(
      currentYear - startYear + 1,
      (index) => startYear + index,
    );

    _selectedYear = startYear;
    _buildAvailableMonths();
  }

  void _buildAvailableMonths() {
    if (_selectedYear == null || _accountCreatedAt == null) return;

    final now = DateTime.now();
    final isCreationYear = _selectedYear == _accountCreatedAt!.year;
    final isCurrentYear = _selectedYear == now.year;

    int startMonth = isCreationYear ? _accountCreatedAt!.month : 1;
    int endMonth = isCurrentYear ? now.month : 12;

    _availableMonths = List.generate(
      endMonth - startMonth + 1,
      (index) => startMonth + index,
    );

    if (isCreationYear) {
      _selectedMonth = _accountCreatedAt!.month;
    } else if (_availableMonths.isNotEmpty) {
      _selectedMonth = _availableMonths.first;
    }
  }

  List<RewardActivity> _getActivitiesFromStartDate() {
    if (_selectedYear == null || _selectedMonth == null) return [];

    final startDate = DateTime(_selectedYear!, _selectedMonth!, 1);
    final endDate = DateTime.now();

    // Filter by date range AND by user (only user's own activities)
    return _allActivities.where((activity) {
      final isInDateRange = activity.createdAt.isAfter(
            startDate.subtract(const Duration(seconds: 1)),
          ) &&
          activity.createdAt.isBefore(endDate.add(const Duration(seconds: 1)));
      
      // Only include activities that belong to this user
      final isUserActivity = activity.memberName == _userName;
      
      return isInDateRange && isUserActivity;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _getMonthName(int month) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('MMMM', locale).format(DateTime(2024, month));
  }

  String _getFormattedStartDate() {
    if (_selectedYear == null || _selectedMonth == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat(
      'MMMM yyyy',
      locale,
    ).format(DateTime(_selectedYear!, _selectedMonth!));
  }

  Future<void> _generateStatement() async {
    final l10n = AppLocalizations.of(context)!;

    // Check rate limit first
    if (!_canSendEmail()) {
      _analytics.trackStatementRateLimited(emailsSentToday: _emailsSentToday);
      AppToast.error(context, l10n.statementRateLimitError);
      return;
    }

    if (_selectedYear == null || _selectedMonth == null) {
      AppToast.warning(context, l10n.statementSelectDate);
      return;
    }

    final activities = _getActivitiesFromStartDate();

    if (activities.isEmpty) {
      AppToast.error(context, l10n.statementNoActivity);
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final startDate = DateTime(_selectedYear!, _selectedMonth!, 1);
      final endDate = DateTime.now();

      final totalPoints = activities.fold<int>(
        0,
        (sum, a) => sum + a.pointsEarned,
      );

      final pdfData = await _pdfService.generateStatement(
        userName: _userName,
        userEmail: _userEmail,
        familyName: _familyName,
        startDate: startDate,
        endDate: endDate,
        activities: activities,
        totalPoints: totalPoints,
        currentBalance: _currentBalance,
      );

      if (!mounted) return;

      await _pdfService.sendStatementToEmail(
        pdfData: pdfData,
        userEmail: _userEmail,
        month: _getFormattedStartDate(),
        year: _selectedYear!,
      );

      // Track successful statement send
      _analytics.trackStatementSent(
        month: _selectedMonth,
        year: _selectedYear,
        activitiesCount: activities.length,
        totalPoints: totalPoints,
      );

      // Increment rate limit counter after successful send
      await _incrementEmailCount();

      if (mounted) _showSuccessDialog();
    } catch (e, stackTrace) {
      print('❌ Statement generation error: $e');
      print('📍 Stack trace: $stackTrace');
      
      // Track statement error
      _analytics.trackStatementError(error: e.toString());
      
      if (mounted) {
        AppToast.error(context, l10n.statementGenerateError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.statementSentTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.statementSentDescription(_getFormattedStartDate()),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userEmail,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.statementGotIt,
                    style: const TextStyle(
                      fontSize: 14,
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
                    ? _buildSkeletonLoading()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildContent(l10n),
                      ),
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
            l10n.statement,
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

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      child: SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 150,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary,
                  AppColors.secondary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.statementTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.statementSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statementSelectStartDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: l10n.statementYear,
                        value: _selectedYear,
                        items: _availableYears,
                        displayBuilder: (year) => year.toString(),
                        onChanged: (year) {
                          setState(() {
                            _selectedYear = year;
                            _buildAvailableMonths();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: l10n.statementMonth,
                        value: _selectedMonth,
                        items: _availableMonths,
                        displayBuilder: (month) => _getMonthName(month),
                        onChanged: (month) {
                          setState(() {
                            _selectedMonth = month;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_selectedYear != null && _selectedMonth != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.statementPeriod,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_getFormattedStartDate()} → ${l10n.statementToday}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: (_isGeneratingPdf || !_canSendEmail())
                    ? [Colors.grey[400]!, Colors.grey[500]!]
                    : [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.85),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: (_isGeneratingPdf || !_canSendEmail())
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (_isGeneratingPdf || !_canSendEmail()) ? null : _generateStatement,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: _isGeneratingPdf
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.statementSendButton,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rate limit note
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _canSendEmail() 
                    ? Colors.grey[100] 
                    : const Color(0xFFEE3764).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _canSendEmail() ? Icons.info_outline : Icons.warning_amber_rounded,
                    size: 14,
                    color: _canSendEmail() ? Colors.grey[600] : const Color(0xFFEE3764),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _canSendEmail()
                        ? l10n.statementRemainingEmails(_getRemainingEmails())
                        : l10n.statementRateLimitNote,
                    style: TextStyle(
                      fontSize: 11,
                      color: _canSendEmail() ? Colors.grey[600] : const Color(0xFFEE3764),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.statementDateHint,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) displayBuilder,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    displayBuilder(item),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
