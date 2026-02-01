import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Format points with K/M suffix
String _formatPoints(int points) {
  if (points >= 1000000) {
    final value = points / 1000000;
    return value == value.truncate()
        ? '${value.truncate()}M'
        : '${value.toStringAsFixed(1)}M';
  } else if (points >= 1000) {
    final value = points / 1000;
    return value == value.truncate()
        ? '${value.truncate()}K'
        : '${value.toStringAsFixed(1)}K';
  }
  return points.toString();
}

class HomeHeaderWidget extends StatelessWidget {
  final String balance;
  final int points;
  final VoidCallback onTopUp;
  final VoidCallback? onWithdraw;
  final VoidCallback onStatement;
  final VoidCallback? onNotification;
  final VoidCallback? onPoints;
  final int notificationCount;
  final bool showWithdraw;
  // Tutorial keys
  final GlobalKey? topUpKey;
  final GlobalKey? withdrawKey;
  final GlobalKey? statementKey;
  final GlobalKey? pointsKey;
  final GlobalKey? notificationKey;

  const HomeHeaderWidget({
    super.key,
    this.balance = '12,769.00 TND',
    this.points = 120,
    required this.onTopUp,
    this.onWithdraw,
    required this.onStatement,
    this.onNotification,
    this.onPoints,
    this.notificationCount = 0,
    this.showWithdraw = true,
    this.topUpKey,
    this.withdrawKey,
    this.statementKey,
    this.pointsKey,
    this.notificationKey,
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

          // Notification bell
          _buildNotificationBell(balanceTop, isRTL),

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
                border: Border.all(color: const Color(0xFF4CC3C7), width: 20),
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
                border: Border.all(color: const Color(0xFF4CC3C7), width: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(
    BuildContext context,
    double top,
    double screenHeight,
  ) {
    // Responsive font sizes
    final balanceLabelSize = screenHeight * 0.020;
    final balanceAmountSize = screenHeight * 0.028;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive values for points badge
    final badgeFontSize = (screenHeight * 0.014).clamp(10.0, 14.0);
    final badgePaddingH = (screenWidth * 0.025).clamp(8.0, 12.0);
    final badgePaddingV = (screenHeight * 0.005).clamp(3.0, 6.0);
    final badgeMargin = (screenWidth * 0.02).clamp(6.0, 12.0);
    final badgeRadius = (screenHeight * 0.015).clamp(10.0, 14.0);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.balance,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: balanceLabelSize.clamp(14.0, 20.0),
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.012),
          Stack(
            alignment: Alignment.center,
            children: [
              // Centered balance
              Center(
                child: Text(
                  balance,
                  style: TextStyle(
                    color: const Color(0xFFFEBC11),
                    fontSize: balanceAmountSize.clamp(20.0, 28.0),
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Points badge - positioned based on RTL
              Positioned(
                right: isRTL ? null : badgeMargin,
                left: isRTL ? badgeMargin : null,
                child: GestureDetector(
                  onTap: onPoints,
                  child: Container(
                    key: pointsKey,
                    padding: EdgeInsets.symmetric(
                      horizontal: badgePaddingH,
                      vertical: badgePaddingV,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEBC11),
                      borderRadius: BorderRadius.circular(badgeRadius),
                    ),
                    child: Text(
                      '🎁 ${_formatPoints(points)} ${l10n.pts}',
                      style: TextStyle(
                        color: const Color(0xFF141936),
                        fontSize: badgeFontSize,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              // Invisible points badge on opposite side for symmetry
              Positioned(
                left: isRTL ? null : badgeMargin,
                right: isRTL ? badgeMargin : null,
                child: Opacity(
                  opacity: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: badgePaddingH,
                      vertical: badgePaddingV,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEBC11),
                      borderRadius: BorderRadius.circular(badgeRadius),
                    ),
                    child: Text(
                      '🎁 ${_formatPoints(points)} ${l10n.pts}',
                      style: TextStyle(
                        color: const Color(0xFF141936),
                        fontSize: badgeFontSize,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Points badge is now inline with balance, so this is a no-op
  Widget _buildPointsBadge(double top, bool isRTL) {
    return const SizedBox.shrink();
  }

  Widget _buildNotificationBell(double top, bool isRTL) {
    return Positioned(
      top: top,
      right: isRTL ? null : 20,
      left: isRTL ? 20 : null,
      child: GestureDetector(
        key: notificationKey,
        onTap: onNotification,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFFEBC11),
              size: 26,
            ),
            // Notification badge (small red dot with count)
            if (notificationCount > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    notificationCount > 9 ? '9+' : '$notificationCount',
                    style: const TextStyle(
                      color: Color(0xFF141936),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
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
              color: const Color(0xFF3D566E).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              key: topUpKey,
              icon: Icons.add_circle_outline,
              label: AppLocalizations.of(context)!.topUp,
              onTap: onTopUp,
              buttonSize: buttonSize,
              iconSize: iconSize,
              labelSize: labelSize,
            ),
            if (showWithdraw && onWithdraw != null)
              _buildActionButton(
                key: withdrawKey,
                icon: Icons.account_balance_wallet_outlined,
                label: AppLocalizations.of(context)!.withdraw,
                onTap: onWithdraw!,
                buttonSize: buttonSize,
                iconSize: iconSize,
                labelSize: labelSize,
              ),
            _buildActionButton(
              key: statementKey,
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
    GlobalKey? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double buttonSize,
    required double iconSize,
    required double labelSize,
  }) {
    return GestureDetector(
      key: key,
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
            child: Icon(icon, color: AppColors.primary, size: iconSize),
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
