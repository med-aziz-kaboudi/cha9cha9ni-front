import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class HomeHeaderWidget extends StatelessWidget {
  final String balance;
  final int points;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;
  final VoidCallback onStatement;

  const HomeHeaderWidget({
    super.key,
    this.balance = '12,769.00 TND',
    this.points = 120,
    required this.onTopUp,
    required this.onWithdraw,
    required this.onStatement,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    // Responsive values based on screen height
    final headerHeight = screenHeight * 0.28; // 28% of screen height
    final backgroundHeight = headerHeight * 0.85;
    final balanceTop = topPadding + (screenHeight * 0.02);
    final quickActionsTop = headerHeight * 0.70;

    return SizedBox(
      height: headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Header background with circles
          _buildHeaderBackground(screenWidth, backgroundHeight, isRTL),

          // Balance section
          _buildBalanceSection(context, balanceTop, screenHeight),

          // Points badge
          _buildPointsBadge(balanceTop, isRTL),

          // Quick Actions Card
          Positioned(
            top: quickActionsTop,
            left: 0,
            right: 0,
            child: _buildQuickActionsCard(context, screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(double screenWidth, double height, bool isRTL) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main pink/red header background
          Container(
            width: screenWidth,
            height: height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFFEE3764), Color(0xFFEE3764)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
          ),

          // Teal circle (top right/left based on RTL) - responsive size
          Positioned(
            right: isRTL ? null : -20,
            left: isRTL ? -20 : null,
            top: -50,
            child: Container(
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CC3C7),
                  width: 20,
                ),
              ),
            ),
          ),

          // Teal circle (left/right based on RTL) - responsive size
          Positioned(
            left: isRTL ? null : -80,
            right: isRTL ? -80 : null,
            top: height * 0.20,
            child: Container(
              width: screenWidth * 0.45,
              height: screenWidth * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CC3C7),
                  width: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context, double top, double screenHeight) {
    // Responsive font sizes
    final balanceLabelSize = screenHeight * 0.020;
    final balanceAmountSize = screenHeight * 0.028;
    
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.balance,
            style: TextStyle(
              color: Colors.white,
              fontSize: balanceLabelSize.clamp(14.0, 20.0),
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Text(
            balance,
            style: TextStyle(
              color: const Color(0xFFFEBC11),
              fontSize: balanceAmountSize.clamp(20.0, 28.0),
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(double top, bool isRTL) {
    return Positioned(
      top: top,
      right: isRTL ? null : 20,
      left: isRTL ? 20 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEBC11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '🎁 $points points',
          style: const TextStyle(
            color: Color(0xFF141936),
            fontSize: 12,
            fontFamily: 'Nunito Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, double screenWidth) {
    // Responsive icon/button sizes - bigger icons only
    final buttonSize = (screenWidth * 0.10).clamp(36.0, 44.0);
    final iconSize = (screenWidth * 0.07).clamp(24.0, 32.0);
    final labelSize = (screenWidth * 0.028).clamp(10.0, 12.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3D566E).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.add_circle_outline,
              label: AppLocalizations.of(context)!.topUp,
              onTap: onTopUp,
              buttonSize: buttonSize,
              iconSize: iconSize,
              labelSize: labelSize,
            ),
            _buildActionButton(
              icon: Icons.account_balance_wallet_outlined,
              label: AppLocalizations.of(context)!.withdraw,
              onTap: onWithdraw,
              buttonSize: buttonSize,
              iconSize: iconSize,
              labelSize: labelSize,
            ),
            _buildActionButton(
              icon: Icons.receipt_long_outlined,
              label: AppLocalizations.of(context)!.statement,
              onTap: onStatement,
              buttonSize: buttonSize,
              iconSize: iconSize,
              labelSize: labelSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double buttonSize,
    required double iconSize,
    required double labelSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF23233F),
              fontSize: labelSize,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
