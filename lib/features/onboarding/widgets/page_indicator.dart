import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PageIndicator extends StatefulWidget {
  final PageController pageController;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.pageController,
    required this.totalPages,
  });

  @override
  State<PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<PageIndicator> {
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_pageListener);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_pageListener);
    super.dispose();
  }

  void _pageListener() {
    setState(() {
      _currentPageValue = widget.pageController.page ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.totalPages,
        (index) {
          double progress = (_currentPageValue - index).abs();
          progress = progress.clamp(0.0, 1.0);
          
          bool isActive = progress < 0.5;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 6,
              width: 32,
              decoration: BoxDecoration(
                gradient: isActive
                    ? AppColors.secondaryGradient
                    : null,
                color: isActive
                    ? null
                    : AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(360),
              ),
            ),
          );
        },
      ),
    );
  }
}
