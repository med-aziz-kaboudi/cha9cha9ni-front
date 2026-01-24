import 'dart:async';
import 'package:flutter/material.dart';
import 'socket_service.dart';
import '../../features/rewards/rewards_service.dart';
import '../../features/activity/activity_service.dart';

/// Singleton service to manage session state and notify when session expires
/// This is triggered by:
/// 1. Any API call that returns 401 (session invalid)
/// 2. WebSocket force_logout event (another device logged in)
/// Also handles real-time family updates via WebSocket
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Stream controller to broadcast session expiration events
  final _sessionExpiredController = StreamController<String>.broadcast();
  
  // Flag to prevent multiple logout dialogs
  bool _isHandlingExpiration = false;

  // Socket service subscription
  StreamSubscription<ForceLogoutData>? _forceLogoutSubscription;
  StreamSubscription<FamilyMemberJoinedData>? _familyMemberJoinedSubscription;

  /// Stream that emits when session expires (message contains reason)
  Stream<String> get onSessionExpired => _sessionExpiredController.stream;

  /// Stream that emits when a new family member joins (for owners)
  Stream<FamilyMemberJoinedData> get onFamilyMemberJoined => SocketService().onFamilyMemberJoined;

  /// Get the socket service instance for direct access to streams
  SocketService get socketService => SocketService();

  /// Check if currently handling an expiration (to prevent duplicate dialogs)
  bool get isHandlingExpiration => _isHandlingExpiration;

  /// Initialize WebSocket connection with access token
  /// Call this after successful login
  void initializeSocket(String accessToken) {
    final socketService = SocketService();
    socketService.connect(accessToken);

    // Initialize RewardsService to listen for points_earned events
    RewardsService().initialize();

    // Initialize ActivityService to receive real-time activity updates
    ActivityService().initialize();

    // Listen for force logout events from WebSocket
    _forceLogoutSubscription?.cancel();
    _forceLogoutSubscription = socketService.onForceLogout.listen((data) {
      debugPrint('🔐 SessionManager: Received force logout via WebSocket');
      notifySessionExpired(data.message);
    });

    debugPrint('🔌 SessionManager: Socket initialized');
  }

  /// Disconnect WebSocket
  /// Call this on logout
  void disconnectSocket() {
    _forceLogoutSubscription?.cancel();
    _forceLogoutSubscription = null;
    _familyMemberJoinedSubscription?.cancel();
    _familyMemberJoinedSubscription = null;
    SocketService().disconnect();
    debugPrint('🔌 SessionManager: Socket disconnected');
  }

  /// Call this when any API returns 401 or session invalid error
  /// [reason] - The reason for expiration (e.g., "Another device logged in")
  void notifySessionExpired(String reason) {
    // Only emit if not already handling - prevents duplicate notifications
    if (!_isHandlingExpiration) {
      debugPrint('🚫 SessionManager: Session expired - $reason');
      _sessionExpiredController.add(reason);
    }
  }

  /// Mark that we're now handling the expiration (showing dialog)
  /// Call this BEFORE showing the dialog
  void markHandling() {
    _isHandlingExpiration = true;
    debugPrint('🔒 SessionManager: Marking as handling expiration');
  }

  /// Reset the handling flag (call after logout is complete)
  void resetHandlingFlag() {
    _isHandlingExpiration = false;
    debugPrint('🔓 SessionManager: Reset handling flag');
  }

  /// Dispose the stream controller and socket
  void dispose() {
    _forceLogoutSubscription?.cancel();
    _familyMemberJoinedSubscription?.cancel();
    SocketService().disconnect();
    _sessionExpiredController.close();
  }
}
