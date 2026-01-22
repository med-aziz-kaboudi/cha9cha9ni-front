import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/token_storage_service.dart';

/// Notification model
class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? actionType;
  final String? actionRoute;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.actionType,
    this.actionRoute,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'custom',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      actionType: json['actionType'],
      actionRoute: json['actionRoute'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'actionType': actionType,
      'actionRoute': actionRoute,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? actionType,
    String? actionRoute,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      actionType: actionType ?? this.actionType,
      actionRoute: actionRoute ?? this.actionRoute,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Cache keys
const String _notificationsCacheKey = 'notifications_cache';
const String _unreadCountCacheKey = 'notifications_unread_count';

/// Service for managing notifications and WebSocket connection
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _loadFromCache();
  }

  final _baseUrl = ApiConfig.baseUrl;
  final _tokenStorage = TokenStorageService();

  io.Socket? _socket;
  String? _currentToken;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  bool _cacheLoaded = false;

  // Cached notifications
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  // Stream controllers for events
  final _notificationsController = StreamController<List<NotificationItem>>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();
  final _newNotificationController = StreamController<NotificationItem>.broadcast();

  /// Stream of all notifications
  Stream<List<NotificationItem>> get notifications => _notificationsController.stream;

  /// Stream of unread count updates
  Stream<int> get unreadCount => _unreadCountController.stream;

  /// Stream of new notification events (for real-time updates)
  Stream<NotificationItem> get onNewNotification => _newNotificationController.stream;

  /// Get current cached notifications
  List<NotificationItem> get cachedNotifications => List.unmodifiable(_notifications);

  /// Get current cached unread count
  int get cachedUnreadCount => _unreadCount;

  /// Whether cache is loaded
  bool get isCacheLoaded => _cacheLoaded;

  /// Whether the socket is currently connected
  bool get isConnected => _socket?.connected ?? false;

  /// Load notifications from local cache (SharedPreferences)
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cached notifications
      final cachedJson = prefs.getString(_notificationsCacheKey);
      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        _notifications = decoded
            .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
            .toList();
        _notificationsController.add(List.from(_notifications));
      }
      
      // Load cached unread count
      _unreadCount = prefs.getInt(_unreadCountCacheKey) ?? 0;
      _unreadCountController.add(_unreadCount);
      
      _cacheLoaded = true;
      debugPrint('🔔 Loaded ${_notifications.length} notifications from cache');
    } catch (e) {
      debugPrint('❌ Error loading notifications cache: $e');
      _cacheLoaded = true;
    }
  }

  /// Save notifications to local cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save notifications
      final notificationsJson = json.encode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_notificationsCacheKey, notificationsJson);
      
      // Save unread count
      await prefs.setInt(_unreadCountCacheKey, _unreadCount);
      
      debugPrint('🔔 Saved ${_notifications.length} notifications to cache');
    } catch (e) {
      debugPrint('❌ Error saving notifications cache: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Refresh access token using session token
  Future<bool> _refreshToken() async {
    try {
      final sessionToken = await _tokenStorage.getSessionToken();
      if (sessionToken == null) {
        debugPrint('🔔 No session token available for refresh');
        return false;
      }

      debugPrint('🔔 Refreshing token...');
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.refreshPath}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sessionToken': sessionToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final newAccessToken = data['accessToken'];
        final newSessionToken = data['sessionToken'];
        
        if (newAccessToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            sessionToken: newSessionToken ?? sessionToken,
            expiresIn: data['expiresIn']?.toString(),
          );
          // Update socket with new token
          _currentToken = newAccessToken;
          debugPrint('🔔 Token refreshed successfully');
          return true;
        }
      }
      
      debugPrint('🔔 Token refresh failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('🔔 Token refresh error: $e');
      return false;
    }
  }

  /// Connect to the WebSocket server for real-time updates
  void connect(String accessToken) {
    // Don't reconnect if already connected with same token
    if (_socket != null && _currentToken == accessToken && isConnected) {
      debugPrint('🔔 NotificationSocket: Already connected');
      return;
    }

    // Disconnect existing connection if any
    disconnectSocket();

    _currentToken = accessToken;
    _isConnecting = true;

    // Build WebSocket URL
    final wsUrl = ApiConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

    debugPrint('🔔 NotificationSocket: Connecting to $wsUrl/notifications');

    _socket = io.io(
      '$wsUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(3)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    // Update auth token BEFORE each reconnection attempt
    _socket!.io.on('reconnect_attempt', (_) async {
      debugPrint('🔔 NotificationSocket: Reconnection attempt - updating token');
      final freshToken = await _tokenStorage.getAccessToken();
      if (freshToken != null) {
        _currentToken = freshToken;
        _socket?.auth = {'token': freshToken};
      }
    });

    // Connection event handlers
    _socket!.onConnect((_) {
      debugPrint('🔔 NotificationSocket: Connected');
      _isConnecting = false;
      // Fetch initial notifications after connecting
      fetchNotifications();
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔔 NotificationSocket: Disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('🔔 NotificationSocket: Connection error');
      _isConnecting = false;
    });

    _socket!.onError((error) {
      debugPrint('🔔 NotificationSocket: Error');
    });

    // Listen for new notification event
    _socket!.on('notifications:new', (data) {
      debugPrint('🔔 NotificationSocket: New notification received');
      if (data is Map<String, dynamic>) {
        // Handle single notification
        if (data['notification'] != null) {
          final notification = NotificationItem.fromJson(data['notification'] as Map<String, dynamic>);
          _notifications.insert(0, notification);
          _newNotificationController.add(notification);
        }
        // Handle multiple notifications (for new users)
        if (data['notifications'] != null) {
          final notifications = (data['notifications'] as List)
              .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
              .toList();
          _notifications = [...notifications, ..._notifications];
        }
        // Update unread count
        if (data['unreadCount'] != null) {
          _unreadCount = data['unreadCount'] as int;
        }
        _notificationsController.add(List.from(_notifications));
        _unreadCountController.add(_unreadCount);
        _saveToCache(); // Save to local cache
      }
    });

    // Listen for notification read event (real-time sync)
    _socket!.on('notifications:read', (data) {
      debugPrint('🔔 NotificationSocket: Notification read - $data');
      if (data is Map<String, dynamic>) {
        final notificationId = data['notificationId'] as String?;
        final unreadCount = data['unreadCount'] as int?;
        
        if (notificationId != null) {
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
            _notificationsController.add(List.from(_notifications));
          }
        }
        
        if (unreadCount != null) {
          _unreadCount = unreadCount;
          _unreadCountController.add(_unreadCount);
        }
        _saveToCache(); // Save to local cache
      }
    });

    // Listen for all notifications read event
    _socket!.on('notifications:all-read', (data) {
      debugPrint('🔔 NotificationSocket: All notifications read');
      _notifications = _notifications.map((n) => n.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      )).toList();
      _unreadCount = 0;
      _notificationsController.add(List.from(_notifications));
      _unreadCountController.add(_unreadCount);
      _saveToCache(); // Save to local cache
    });

    // Listen for unread count update
    _socket!.on('unread_count', (data) {
      debugPrint('🔔 NotificationSocket: Unread count update - $data');
      if (data is Map<String, dynamic> && data['count'] != null) {
        _unreadCount = data['count'] as int;
        _unreadCountController.add(_unreadCount);
      }
    });

    // Listen for connection acknowledgment
    _socket!.on('connected', (data) {
      debugPrint('🔔 NotificationSocket: Server acknowledged - $data');
    });

    // Ping/pong for keepalive
    _socket!.on('pong', (data) {
      debugPrint('🔔 NotificationSocket: Pong received');
    });
  }

  /// Disconnect WebSocket
  void disconnectSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_socket != null) {
      debugPrint('🔔 NotificationSocket: Disconnecting');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _currentToken = null;
    _isConnecting = false;
  }

  /// Fetch all notifications from the API
  Future<List<NotificationItem>> fetchNotifications() async {
    try {
      var headers = await _getHeaders();
      
      var response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: headers,
      );

      // Handle 401 - try to refresh token once
      if (response.statusCode == 401) {
        debugPrint('🔔 401: Attempting token refresh for notifications');
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry with new token
          headers = await _getHeaders();
          response = await http.get(
            Uri.parse('$_baseUrl/notifications'),
            headers: headers,
          );
        }
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notificationsList = data['notifications'] as List? ?? [];
        _notifications = notificationsList
            .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
            .toList();
        _unreadCount = data['unreadCount'] as int? ?? 0;

        _notificationsController.add(List.from(_notifications));
        _unreadCountController.add(_unreadCount);

        // Save to local cache
        await _saveToCache();

        debugPrint('🔔 Fetched ${_notifications.length} notifications, $_unreadCount unread');
        return _notifications;
      } else {
        debugPrint('❌ Failed to fetch notifications: ${response.statusCode}');
        return _notifications; // Return cached data on error
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return _notifications; // Return cached data on error
    }
  }

  /// Get unread count from API
  Future<int> fetchUnreadCount() async {
    try {
      var headers = await _getHeaders();
      
      var response = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: headers,
      );

      // Handle 401 - try to refresh token once
      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          headers = await _getHeaders();
          response = await http.get(
            Uri.parse('$_baseUrl/notifications/unread-count'),
            headers: headers,
          );
        }
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _unreadCount = data['count'] as int? ?? 0;
        _unreadCountController.add(_unreadCount);
        await _saveToCache();
        return _unreadCount;
      }
      return _unreadCount; // Return cached count on error
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return _unreadCount; // Return cached count on error
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local cache
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          if (!notification.isRead) {
            _notifications[index] = notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
            _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
            _notificationsController.add(List.from(_notifications));
            _unreadCountController.add(_unreadCount);
            // Save to local cache
            await _saveToCache();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local cache
        _notifications = _notifications.map((n) => n.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        )).toList();
        _unreadCount = 0;
        _notificationsController.add(List.from(_notifications));
        _unreadCountController.add(_unreadCount);
        // Save to local cache
        await _saveToCache();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Clear cached data (call on logout)
  Future<void> clearCache() async {
    _notifications = [];
    _unreadCount = 0;
    _notificationsController.add([]);
    _unreadCountController.add(0);
    
    // Clear SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsCacheKey);
      await prefs.remove(_unreadCountCacheKey);
    } catch (e) {
      debugPrint('❌ Error clearing notifications cache: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    disconnectSocket();
    _notificationsController.close();
    _unreadCountController.close();
    _newNotificationController.close();
  }
}
