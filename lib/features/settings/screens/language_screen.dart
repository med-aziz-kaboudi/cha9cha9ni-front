import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/language_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  final _languageService = LanguageService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String languageCode) async {
    final currentCode = _languageService.locale.languageCode;
    if (currentCode == languageCode) return;

    HapticFeedback.mediumImpact();

    // Simply change the language - Flutter will handle the rebuild smoothly
    await _languageService.setLanguage(languageCode);

    if (mounted) {
      // Show success toast after a brief delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          AppToast.success(
            context,
            AppLocalizations.of(context)?.languageChanged ??
                'Language changed successfully',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              // Header bar matching edit profile
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
                    // Back button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
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
                          isRTL
                              ? Icons.arrow_forward_ios
                              : Icons.arrow_back_ios_new,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Text(
                        l10n?.languages ?? 'Languages',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtitle
                          Text(
                            l10n?.choosePreferredLanguage ??
                                'Choose your preferred language',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Language options
                          ValueListenableBuilder<Locale>(
                            valueListenable: _languageService.currentLocale,
                            builder: (context, currentLocale, _) {
                              return Column(
                                children: [
                                  _buildLanguageCard(
                                    flag: '🇬🇧',
                                    languageName: 'English',
                                    nativeName: 'English',
                                    languageCode: 'en',
                                    isSelected:
                                        currentLocale.languageCode == 'en',
                                    delay: 0,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLanguageCard(
                                    flag: '🇹🇳',
                                    languageName:
                                        l10n?.languageArabic ?? 'العربية',
                                    nativeName: 'العربية',
                                    languageCode: 'ar',
                                    isSelected:
                                        currentLocale.languageCode == 'ar',
                                    delay: 1,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLanguageCard(
                                    flag: '🇫🇷',
                                    languageName:
                                        l10n?.languageFrench ?? 'Français',
                                    nativeName: 'Français',
                                    languageCode: 'fr',
                                    isSelected:
                                        currentLocale.languageCode == 'fr',
                                    delay: 2,
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Info section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: AppColors.secondary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getInfoText(locale.languageCode),
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  String _getInfoText(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'سيتم تطبيق اللغة المختارة على جميع شاشات التطبيق فوراً';
      case 'fr':
        return 'La langue sélectionnée sera appliquée immédiatement à tous les écrans de l\'application';
      default:
        return 'The selected language will be applied immediately across all app screens';
    }
  }

  Widget _buildLanguageCard({
    required String flag,
    required String languageName,
    required String nativeName,
    required String languageCode,
    required bool isSelected,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (delay * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _selectLanguage(languageCode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Flag
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(flag, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLanguageSubtitle(languageCode),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.grey[200],
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageSubtitle(String languageCode) {
    final currentLang = Localizations.localeOf(context).languageCode;

    // Subtitles in the current app language
    switch (currentLang) {
      case 'ar':
        switch (languageCode) {
          case 'en':
            return 'الإنجليزية';
          case 'ar':
            return 'العربية';
          case 'fr':
            return 'الفرنسية';
        }
        break;
      case 'fr':
        switch (languageCode) {
          case 'en':
            return 'Anglais';
          case 'ar':
            return 'Arabe';
          case 'fr':
            return 'Français';
        }
        break;
      default:
        switch (languageCode) {
          case 'en':
            return 'English';
          case 'ar':
            return 'Arabic';
          case 'fr':
            return 'French';
        }
    }
    return '';
  }
}
