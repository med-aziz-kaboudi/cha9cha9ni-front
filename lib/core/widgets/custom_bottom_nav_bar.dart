import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // On Android, add bottom padding to push nav bar above system navigation
    // On iOS, no extra padding needed as bottomNavigationBar handles it
    final bottomPadding = Platform.isAndroid 
        ? MediaQuery.of(context).viewPadding.bottom 
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 80),
            painter: _NavBarPainter(),
          ),
          // Force LTR to keep Home on left and Reward on right regardless of language
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _NavBarItem(
                      context: context,
                      icon: Icons.home_outlined,
                      label: AppLocalizations.of(context)!.home,
                      isSelected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  const SizedBox(width: 100),
                  Expanded(
                    child: _NavBarItem(
                      context: context,
                      icon: Icons.emoji_events_outlined,
                      label: AppLocalizations.of(context)!.reward,
                      isSelected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            child: GestureDetector(
              onTap: () => onTap(1),
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Left section - curve up to the center notch
    path.lineTo(0, 20);
    path.quadraticBezierTo(0, 0, 20, 0);
    path.lineTo(size.width * 0.35, 0);
    
    // Create the center circular notch
    path.quadraticBezierTo(
      size.width * 0.40, 0,
      size.width * 0.42, 10,
    );
    path.arcToPoint(
      Offset(size.width * 0.58, 10),
      radius: const Radius.circular(40),
      clockwise: false,
    );
    path.quadraticBezierTo(
      size.width * 0.60, 0,
      size.width * 0.65, 0,
    );
    
    // Right section - from notch to corner
    path.lineTo(size.width - 20, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 20);
    path.lineTo(size.width, size.height);
    
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Add subtle shadow/depth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavBarItem extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.context,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
