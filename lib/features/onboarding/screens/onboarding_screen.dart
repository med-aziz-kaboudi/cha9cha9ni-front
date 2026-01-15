import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../pages/onboarding1.dart';
import '../pages/onboarding2.dart';
import '../widgets/page_indicator.dart';
import '../../auth/screens/signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = const [
    Onboarding1(),
    Onboarding2(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  void _skipToSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage == 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _skipToSignUp,
                      child: Row(
                        children: [
                          Text(AppLocalizations.of(context)!.skip, style: AppTextStyles.link),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _goBack,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.back,
                            style: AppTextStyles.link,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _pages[index];
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 6,
                    child: PageIndicator(
                      pageController: _pageController,
                      totalPages: _pages.length,
                    ),
                  ),

                  const SizedBox(height: 60),

                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? AppLocalizations.of(context)!.getStarted
                              : AppLocalizations.of(context)!.next,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
