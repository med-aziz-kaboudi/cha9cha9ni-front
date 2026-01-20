import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

/// Events that can be emitted by the SocketService
enum SocketEvent {
  connected,
  disconnected,
  forceLogout,
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

/// Service for managing WebSocket connection for real-time session monitoring
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  String? _currentToken;
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  // Stream controllers for events
  final _eventController = StreamController<SocketEvent>.broadcast();
  final _forceLogoutController = StreamController<ForceLogoutData>.broadcast();

  /// Stream of socket events
  Stream<SocketEvent> get events => _eventController.stream;

  /// Stream of force logout events - listen to this to trigger logout
  Stream<ForceLogoutData> get onForceLogout => _forceLogoutController.stream;

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
  }
}
