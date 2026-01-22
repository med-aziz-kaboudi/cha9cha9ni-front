import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../settings/screens/login_security_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  String _getLocalizedTitle(AppLocalizations l10n) {
    switch (notification.title) {
      case 'notification_welcome_title':
        return l10n.notificationWelcomeTitle;
      case 'notification_profile_title':
        return l10n.notificationProfileTitle;
      case 'notification_security_title':
        return l10n.notificationSecurityTitle;
      default:
        return notification.title;
    }
  }

  String _getLocalizedMessage(AppLocalizations l10n) {
    switch (notification.message) {
      case 'notification_welcome_message':
        return l10n.notificationWelcomeMessage;
      case 'notification_profile_message':
        return l10n.notificationProfileMessage;
      case 'notification_security_message':
        return l10n.notificationSecurityMessage;
      default:
        return notification.message;
    }
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'welcome':
        return Icons.celebration_outlined;
      case 'profile_complete':
        return Icons.person_outline;
      case 'security_setup':
        return Icons.security_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case 'welcome':
        return AppColors.secondary;
      case 'profile_complete':
        return AppColors.primary;
      case 'security_setup':
        return Colors.orange;
      default:
        return AppColors.secondary;
    }
  }

  String _getActionButtonText(AppLocalizations l10n) {
    switch (notification.type) {
      case 'profile_complete':
        return l10n.completeProfile;
      case 'security_setup':
        return l10n.setupSecurity;
      default:
        return l10n.viewDetails;
    }
  }

  void _navigateToAction(BuildContext context) {
    if (notification.actionRoute == null) return;

    Widget? screen;
    switch (notification.actionRoute) {
      case '/settings/personal-info':
      case '/profile':
      case '/edit-profile':
        screen = const EditProfileScreen();
        break;
      case '/settings/security':
      case '/security':
      case '/login-security':
        screen = const LoginSecurityScreen();
        break;
    }

    if (screen != null) {
      // Pop back to notifications list, then navigate
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screen!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final color = _getNotificationColor();
    final hasAction = notification.actionType != null && notification.actionRoute != null;

    return Scaffold(
      backgroundColor: AppColors.gray,
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                        color: AppColors.secondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        l10n.notifications,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the layout
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(),
                          color: color,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title
                      Text(
                        _getLocalizedTitle(l10n),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Message Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _getLocalizedMessage(l10n),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.dark.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Action Button
                      if (hasAction)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _navigateToAction(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getActionButtonText(l10n),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
