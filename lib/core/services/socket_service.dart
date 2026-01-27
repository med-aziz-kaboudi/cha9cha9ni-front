import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import './token_storage_service.dart';

/// Events that can be emitted by the SocketService
enum SocketEvent {
  connected,
  disconnected,
  forceLogout,
  familyMemberJoined,
  pointsEarned,
  adsStatsUpdated,
  aidSelected,
  error,
}

/// Data class for force logout event
class ForceLogoutData {
  final String reason;
  final String message;
  final DateTime timestamp;

  ForceLogoutData({
    required this.reason,
    required this.message,
    required this.timestamp,
  });

  factory ForceLogoutData.fromJson(Map<String, dynamic> json) {
    return ForceLogoutData(
      reason: json['reason'] ?? 'unknown',
      message: json['message'] ?? 'Session terminated',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for family member joined event
class FamilyMemberJoinedData {
  final String memberId;
  final String memberName;
  final String memberEmail;
  final String newInviteCode;
  final DateTime timestamp;

  FamilyMemberJoinedData({
    required this.memberId,
    required this.memberName,
    required this.memberEmail,
    required this.newInviteCode,
    required this.timestamp,
  });

  factory FamilyMemberJoinedData.fromJson(Map<String, dynamic> json) {
    return FamilyMemberJoinedData(
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      memberEmail: json['memberEmail'] ?? '',
      newInviteCode: json['newInviteCode'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for points earned event (family rewards)
class PointsEarnedData {
  final String earnerId;
  final String memberName;
  final int pointsEarned;
  final int slotIndex;
  final int newTotalPoints;
  final double newTndValue;
  final String? source; // 'ad_watch' or 'daily_checkin'
  final int? streakDay; // For daily check-in
  final DateTime timestamp;

  PointsEarnedData({
    required this.earnerId,
    required this.memberName,
    required this.pointsEarned,
    required this.slotIndex,
    required this.newTotalPoints,
    required this.newTndValue,
    this.source,
    this.streakDay,
    required this.timestamp,
  });

  factory PointsEarnedData.fromJson(Map<String, dynamic> json) {
    return PointsEarnedData(
      earnerId: json['earnerId'] ?? json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      pointsEarned: json['pointsEarned'] ?? 0,
      slotIndex: json['slotIndex'] ?? 0,
      newTotalPoints: json['newTotalPoints'] ?? 0,
      newTndValue: (json['newTndValue'] ?? 0).toDouble(),
      source: json['source'],
      streakDay: json['streakDay'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for aid selected event (pack/aid selection)
class AidSelectedData {
  final String aidId;
  final String aidName;
  final String aidDisplayName;
  final int maxWithdrawal;
  final String? windowStart;
  final String? windowEnd;
  final DateTime timestamp;

  AidSelectedData({
    required this.aidId,
    required this.aidName,
    required this.aidDisplayName,
    required this.maxWithdrawal,
    this.windowStart,
    this.windowEnd,
    required this.timestamp,
  });

  factory AidSelectedData.fromJson(Map<String, dynamic> json) {
    return AidSelectedData(
      aidId: json['aidId'] ?? '',
      aidName: json['aidName'] ?? '',
      aidDisplayName: json['aidDisplayName'] ?? '',
      maxWithdrawal: json['maxWithdrawal'] ?? 0,
      windowStart: json['windowStart'],
      windowEnd: json['windowEnd'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for ads stats update event
class AdsStatsUpdatedData {
  final int familyTotalAdsToday;
  final int familyMaxAdsToday;
  final int memberCount;
  final String? userId; // The user who triggered the update
  final int? userAdsToday; // That user's personal ads count
  final DateTime timestamp;

  AdsStatsUpdatedData({
    required this.familyTotalAdsToday,
    required this.familyMaxAdsToday,
    required this.memberCount,
    this.userId,
    this.userAdsToday,
    required this.timestamp,
  });

  factory AdsStatsUpdatedData.fromJson(Map<String, dynamic> json) {
    return AdsStatsUpdatedData(
      familyTotalAdsToday: json['familyTotalAdsToday'] ?? 0,
      familyMaxAdsToday: json['familyMaxAdsToday'] ?? 25,
      memberCount: json['memberCount'] ?? 1,
      userId: json['userId'],
      userAdsToday: json['userAdsToday'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Service for managing WebSocket connection for real-time session monitoring
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  final _tokenStorage = TokenStorageService();
  io.Socket? _socket;
  String? _currentToken;
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  // Stream controllers for events
  final _eventController = StreamController<SocketEvent>.broadcast();
  final _forceLogoutController = StreamController<ForceLogoutData>.broadcast();
  final _familyMemberJoinedController = StreamController<FamilyMemberJoinedData>.broadcast();
  final _pointsEarnedController = StreamController<PointsEarnedData>.broadcast();
  final _adsStatsUpdatedController = StreamController<AdsStatsUpdatedData>.broadcast();
  final _aidSelectedController = StreamController<AidSelectedData>.broadcast();

  /// Stream of socket events
  Stream<SocketEvent> get events => _eventController.stream;

  /// Stream of force logout events - listen to this to trigger logout
  Stream<ForceLogoutData> get onForceLogout => _forceLogoutController.stream;

  /// Stream of family member joined events - listen to this to update UI
  Stream<FamilyMemberJoinedData> get onFamilyMemberJoined => _familyMemberJoinedController.stream;

  /// Stream of points earned events - listen to this to update rewards UI
  Stream<PointsEarnedData> get onPointsEarned => _pointsEarnedController.stream;

  /// Stream of ads stats updated events - listen to this to update pack UI
  Stream<AdsStatsUpdatedData> get onAdsStatsUpdated => _adsStatsUpdatedController.stream;

  /// Stream of aid selected events - listen to this to update home screen
  Stream<AidSelectedData> get onAidSelected => _aidSelectedController.stream;

  /// Whether the socket is currently connected
  bool get isConnected => _socket?.connected ?? false;

  /// Whether currently attempting to connect
  bool get isConnecting => _isConnecting;

  /// Connect to the WebSocket server with the provided access token
  void connect(String accessToken) {
    // Don't reconnect if already connected with same token
    if (_socket != null && _currentToken == accessToken && isConnected) {
      debugPrint('🔌 Socket: Already connected');
      return;
    }

    // Disconnect existing connection if any
    disconnect();

    _currentToken = accessToken;
    _isConnecting = true;

    // Build WebSocket URL (same as API but with /session namespace)
    final wsUrl = ApiConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

    debugPrint('🔌 Socket: Connecting to $wsUrl/session');

    _socket = io.io(
      '$wsUrl/session',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(3)  // Limit retries to avoid spam
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    // Update auth token BEFORE each reconnection attempt
    _socket!.io.on('reconnect_attempt', (_) async {
      debugPrint('🔌 Socket: Reconnection attempt - updating token');
      final freshToken = await _tokenStorage.getAccessToken();
      if (freshToken != null) {
        _currentToken = freshToken;
        _socket?.auth = {'token': freshToken};
      }
    });

    // Connection event handlers
    _socket!.onConnect((_) {
      debugPrint('🔌 Socket: Connected - real-time session monitoring active');
      _isConnecting = false;
      _eventController.add(SocketEvent.connected);
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 Socket: Disconnected');
      _eventController.add(SocketEvent.disconnected);
    });

    _socket!.onConnectError((error) {
      debugPrint('🔌 Socket: Connection error (WebSocket may not be deployed yet)');
      _isConnecting = false;
      _eventController.add(SocketEvent.error);
    });

    _socket!.onError((error) {
      debugPrint('🔌 Socket: Error');
      _eventController.add(SocketEvent.error);
    });

    // Listen for force logout event
    _socket!.on('force_logout', (data) {
      debugPrint('🔐 Socket: Received force_logout event');
      if (data is Map<String, dynamic>) {
        final logoutData = ForceLogoutData.fromJson(data);
        _forceLogoutController.add(logoutData);
      } else {
        _forceLogoutController.add(ForceLogoutData(
          reason: 'new_login',
          message: 'You have been logged out because your account was accessed from another device.',
          timestamp: DateTime.now(),
        ));
      }
    });

    // Listen for family member joined event (for owners)
    _socket!.on('family_member_joined', (data) {
      debugPrint('👨‍👩‍👧 Socket: Received family_member_joined event');
      if (data is Map<String, dynamic>) {
        final memberData = FamilyMemberJoinedData.fromJson(data);
        _familyMemberJoinedController.add(memberData);
        _eventController.add(SocketEvent.familyMemberJoined);
      }
    });

    // Listen for points earned event (family rewards)
    _socket!.on('points_earned', (data) {
      debugPrint('🎁 Socket: Received points_earned event');
      if (data is Map<String, dynamic>) {
        final pointsData = PointsEarnedData.fromJson(data);
        _pointsEarnedController.add(pointsData);
        _eventController.add(SocketEvent.pointsEarned);
      }
    });

    // Listen for ads stats updated event (pack/ads tracking)
    _socket!.on('ads_stats_updated', (data) {
      debugPrint('📊 Socket: Received ads_stats_updated event');
      if (data is Map<String, dynamic>) {
        final statsData = AdsStatsUpdatedData.fromJson(data);
        _adsStatsUpdatedController.add(statsData);
        _eventController.add(SocketEvent.adsStatsUpdated);
      }
    });

    // Listen for aid selected event (real-time aid selection)
    _socket!.on('aid_selected', (data) {
      debugPrint('🎊 Socket: Received aid_selected event');
      if (data is Map<String, dynamic>) {
        final aidData = AidSelectedData.fromJson(data);
        _aidSelectedController.add(aidData);
        _eventController.add(SocketEvent.aidSelected);
      }
    });

    // Listen for connection acknowledgment
    _socket!.on('connected', (data) {
      debugPrint('🔌 Socket: Server acknowledged connection - $data');
    });

    // Ping/pong for keepalive
    _socket!.on('pong', (data) {
      debugPrint('🔌 Socket: Pong received');
    });
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_socket != null) {
      debugPrint('🔌 Socket: Disconnecting');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _currentToken = null;
    _isConnecting = false;
  }

  /// Reconnect with current token
  void reconnect() {
    if (_currentToken != null) {
      connect(_currentToken!);
    }
  }

  /// Send a ping to keep the connection alive
  void ping() {
    if (isConnected) {
      _socket!.emit('ping');
    }
  }

  /// Dispose the service and clean up resources
  void dispose() {
    disconnect();
    _eventController.close();
    _forceLogoutController.close();
    _familyMemberJoinedController.close();
    _pointsEarnedController.close();
    _adsStatsUpdatedController.close();
    _aidSelectedController.close();
  }
}
