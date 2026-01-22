import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/services/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<NotificationItem> _notifications = [];
  StreamSubscription<List<NotificationItem>>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    // Load cached data immediately - no loading indicator
    _notifications = _notificationService.cachedNotifications;
    
    // Listen for real-time updates
    _notificationsSubscription = _notificationService.notifications.listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    });
    
    // Fetch fresh data in background (silently updates via stream)
    _notificationService.fetchNotifications();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    await _notificationService.fetchNotifications();
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.isRead) return;
    
    await _notificationService.markAsRead(notification.id);
    
    // Refresh local state
    if (mounted) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    
    if (success && mounted) {
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        )).toList();
      });
      
      final l10n = AppLocalizations.of(context)!;
      AppToast.success(context, l10n.allNotificationsRead);
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Mark as read when tapped
    _markAsRead(notification);
    
    // Navigate to detail screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: notification),
      ),
    );
  }

  String _getLocalizedTitle(NotificationItem notification, AppLocalizations l10n) {
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

  IconData _getNotificationIcon(String type) {
    switch (type) {
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

  Color _getNotificationIconColor(String type) {
    switch (type) {
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

  String _formatTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? l10n.monthAgo(months) : l10n.monthsAgo(months);
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? l10n.dayAgo(difference.inDays) : l10n.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? l10n.hourAgo(difference.inHours) : l10n.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? l10n.minAgo(difference.inMinutes) : l10n.minsAgo(difference.inMinutes);
    } else {
      return l10n.justNow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

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
              // Custom App Bar
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
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: _markAllAsRead,
                        child: Text(
                          l10n.markAllRead,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48), // Balance the layout
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _notifications.isEmpty
                    ? _buildEmptyState(l10n)
                    : RefreshIndicator(
                        onRefresh: _refreshNotifications,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(_notifications[index], l10n);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.secondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noNotifications,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noNotificationsDesc,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.dark.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, AppLocalizations l10n) {
    final iconColor = notification.isRead 
        ? Colors.grey 
        : _getNotificationIconColor(notification.type);

    return Opacity(
      opacity: notification.isRead ? 0.7 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? Colors.grey.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.withOpacity(0.15)
                : AppColors.secondary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: notification.isRead 
              ? [] 
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor.withOpacity(0.15),
                          iconColor.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title only
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLocalizedTitle(notification, l10n),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatTimeAgo(notification.createdAt, l10n),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.dark.withOpacity(0.5),
                              ),
                            ),
                            if (notification.isRead) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Unread indicator or arrow
                  if (!notification.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
