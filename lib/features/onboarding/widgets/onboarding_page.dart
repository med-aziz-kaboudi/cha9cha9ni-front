import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingPageContent extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image Section
          Image.asset(
            imagePath,
            width: double.infinity,
            height: 350,
            fit: BoxFit.cover,
          ),

          const SizedBox(height: 24),

          // Text Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading1),
                const SizedBox(height: 16),
                Opacity(
                  opacity: 0.80,
                  child: Text(description, style: AppTextStyles.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
