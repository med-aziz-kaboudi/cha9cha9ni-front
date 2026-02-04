import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/token_storage_service.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class CustomDrawer extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback? onPersonalInfo;
  final VoidCallback? onCurrentPack;
  final VoidCallback? onLoginSecurity;
  final VoidCallback? onLanguages;
  final VoidCallback? onNotifications;
  final VoidCallback? onHelp;
  final VoidCallback? onLegalAgreements;
  final VoidCallback? onLeaveFamily;
  final bool isOwner;

  const CustomDrawer({
    super.key,
    required this.onLogout,
    this.onPersonalInfo,
    this.onCurrentPack,
    this.onLoginSecurity,
    this.onLanguages,
    this.onNotifications,
    this.onHelp,
    this.onLegalAgreements,
    this.onLeaveFamily,
    this.isOwner = true,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> with SingleTickerProviderStateMixin {
  String _userName = '';
  String? _profilePictureUrl;
  final _tokenStorage = TokenStorageService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    // Start the animation when drawer opens
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final name = await _tokenStorage.getUserDisplayName();
    final profilePicture = await _tokenStorage.getProfilePictureUrl();
    if (mounted) {
      setState(() {
        _userName = name;
        _profilePictureUrl = profilePicture;
      });
    }
  }

  String _getInitials() {
    if (_userName.isEmpty) return 'U';
    final parts = _userName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _userName[0].toUpperCase();
  }

  void _closeDrawer() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Check locale directly for RTL languages
    final locale = Localizations.localeOf(context);
    final isRTL = locale.languageCode == 'ar';
    
    // Responsive values
    final drawerWidth = screenWidth * 0.75;
    final headerHeight = (screenHeight * 0.25).clamp(180.0, 240.0);
    final logoWidth = (drawerWidth * 0.50).clamp(120.0, 170.0);
    final avatarSize = (screenHeight * 0.05).clamp(36.0, 50.0);
    final closeButtonSize = (screenHeight * 0.04).clamp(28.0, 36.0);
    final closeIconSize = (closeButtonSize * 0.5).clamp(12.0, 16.0);
    final avatarIconSize = (avatarSize * 0.52).clamp(18.0, 26.0);
    final userNameFontSize = (screenHeight * 0.017).clamp(13.0, 16.0);
    final logoutFontSize = (screenHeight * 0.020).clamp(15.0, 19.0);
    final logoutIconSize = (screenHeight * 0.022).clamp(16.0, 20.0);
    final menuItemFontSize = (screenHeight * 0.016).clamp(13.0, 15.0);
    final menuIconSize = (screenHeight * 0.022).clamp(18.0, 22.0);
    final headerPadding = (screenWidth * 0.035).clamp(10.0, 16.0);
    final avatarTopSpacing = (screenHeight * 0.015).clamp(8.0, 16.0);
    final nameTopSpacing = (screenHeight * 0.008).clamp(4.0, 10.0);
    final menuItemPaddingV = (screenHeight * 0.014).clamp(10.0, 14.0);
    final menuItemPaddingH = (screenWidth * 0.04).clamp(14.0, 20.0);
    
    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header with curved dark background
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                // Curved dark background
                CustomPaint(
                  size: Size(drawerWidth, headerHeight),
                  painter: _DrawerHeaderPainter(),
                ),
                // Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: headerPadding, vertical: headerPadding * 0.75),
                    child: Column(
                      children: [
                        // Logo and close button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/icons/horisental.png',
                              width: logoWidth,
                              fit: BoxFit.contain,
                            ),
                            // Animated close button
                            GestureDetector(
                              onTap: _closeDrawer,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Container(
                                    width: closeButtonSize,
                                    height: closeButtonSize,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(closeButtonSize * 0.28),
                                    ),
                                    child: Icon(
                                      isRTL ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: closeIconSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: avatarTopSpacing),
                        // Avatar with profile picture
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            color: _profilePictureUrl == null ? const Color(0xFF4CC3C7) : null,
                            borderRadius: BorderRadius.circular(avatarSize),
                          ),
                          child: _profilePictureUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(avatarSize),
                                  child: CachedNetworkImage(
                                    imageUrl: _profilePictureUrl!,
                                    fit: BoxFit.cover,
                                    width: avatarSize,
                                    height: avatarSize,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFF4CC3C7),
                                      child: Icon(
                                        Icons.person_outline,
                                        color: Colors.white,
                                        size: avatarIconSize,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFF4CC3C7),
                                      child: Center(
                                        child: Text(
                                          _getInitials(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: avatarIconSize * 0.7,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: avatarIconSize,
                                ),
                        ),
                        SizedBox(height: nameTopSpacing),
                        // User name
                        Text(
                          _userName,
                          style: TextStyle(
                            color: const Color(0xFF252934),
                            fontSize: userNameFontSize,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w700,
                            height: 1.31,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider after header
          Container(
            width: double.infinity,
            height: 1.5,
            color: const Color(0x334CC3C7),
          ),
          
          // Menu items - fixed, non-scrollable
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: menuItemPaddingV * 0.7),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: l10n.personalInformation,
                    onTap: widget.onPersonalInfo,
                    fontSize: menuItemFontSize,
                    iconSize: menuIconSize,
                    paddingH: menuItemPaddingH,
                    paddingV: menuItemPaddingV,
                    isRTL: isRTL,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.yourCurrentPack,
                    onTap: widget.onCurrentPack,
                    fontSize: menuItemFontSize,
                    iconSize: menuIconSize,
                    paddingH: menuItemPaddingH,
                    paddingV: menuItemPaddingV,
                    isRTL: isRTL,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: l10n.loginAndSecurity,
                    onTap: widget.onLoginSecurity,
                    fontSize: menuItemFontSize,
                    iconSize: menuIconSize,
                    paddingH: menuItemPaddingH,
                    paddingV: menuItemPaddingV,
                    isRTL: isRTL,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: l10n.languages,
                    onTap: widget.onLanguages,
                    fontSize: menuItemFontSize,
                    iconSize: menuIconSize,
                    paddingH: menuItemPaddingH,
                    paddingV: menuItemPaddingV,
                    isRTL: isRTL,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: l10n.notifications,
                    onTap: widget.onNotifications,
                    fontSize: menuItemFontSize,
                    iconSize: menuIconSize,
                    paddingH: menuItemPaddingH,
                    paddingV: menuItemPaddingV,
                    isRTL: isRTL,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: l10n.help,
                    onTap: widget.onHelp,
                    fontSize: menuItemFontSize,
                    iconSize: menuIconSize,
                    paddingH: menuItemPaddingH,
                    paddingV: menuItemPaddingV,
                    isRTL: isRTL,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: l10n.legalAgreements,
                    onTap: widget.onLegalAgreements,
                    fontSize: menuItemFontSize,
                    iconSize: menuIconSize,
                    paddingH: menuItemPaddingH,
                    paddingV: menuItemPaddingV,
                    isRTL: isRTL,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          
          // Logout section
          Container(
            width: double.infinity,
            height: 1.5,
            color: const Color(0x334CC3C7),
          ),
          // Add padding for system navigation bar
          Padding(
            padding: EdgeInsets.only(
              left: menuItemPaddingH,
              right: menuItemPaddingH,
              top: menuItemPaddingV,
              bottom: MediaQuery.of(context).viewPadding.bottom + menuItemPaddingV * 0.5,
            ),
            child: GestureDetector(
              onTap: widget.onLogout,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    color: const Color(0xFF4CC3C7),
                    size: logoutIconSize,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    l10n.logout,
                    style: TextStyle(
                      color: const Color(0xFF4CC3C7),
                      fontSize: logoutFontSize,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w800,
                      height: 1.33,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    required double fontSize,
    required double iconSize,
    required double paddingH,
    required double paddingV,
    bool isRTL = false,
    bool isDanger = false,
  }) {
    final itemColor = isDanger ? AppColors.primary : Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        child: Row(
          children: [
            Icon(
              icon,
              color: itemColor,
              size: iconSize,
            ),
            SizedBox(width: paddingH * 0.8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: itemColor,
                  fontSize: fontSize,
                  fontFamily: 'Nunito Sans',
                  fontWeight: isDanger ? FontWeight.w700 : FontWeight.w600,
                  height: 1.50,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Icon(
              isRTL ? Icons.chevron_left : Icons.chevron_right,
              color: isDanger ? itemColor.withValues(alpha: 0.7) : Colors.black45,
              size: iconSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: const Color(0x1A4CC3C7),
    );
  }
}

class _DrawerHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.27)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.55);
    
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.85,
      size.width * 0.45,
      size.height * 0.70,
    );
    path.quadraticBezierTo(
      size.width * 0.20,
      size.height * 0.50,
      0,
      size.height * 0.75,
    );
    
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
