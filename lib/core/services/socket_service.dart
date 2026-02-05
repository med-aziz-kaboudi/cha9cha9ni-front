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
  familyMemberLeft,
  pointsEarned,
  adsStatsUpdated,
  aidSelected,
  aidRemoved,
  packUpdated,
  balanceUpdated,
  profilePictureUpdated,
  profileUpdated,
  removalInitiated,
  removalCancelled,
  rewardsRedeemed,
  ownershipTransferred,
  error,
}

/// Data class for balance updated event (top-up/redemption)
class BalanceUpdatedData {
  final double newBalance;
  final double amount;
  final String type; // 'topup' or 'redemption'
  final int? pointsAwarded;
  final int? newTotalPoints;
  final String? redeemedBy;
  final DateTime timestamp;

  BalanceUpdatedData({
    required this.newBalance,
    required this.amount,
    required this.type,
    this.pointsAwarded,
    this.newTotalPoints,
    this.redeemedBy,
    required this.timestamp,
  });

  factory BalanceUpdatedData.fromJson(Map<String, dynamic> json) {
    return BalanceUpdatedData(
      newBalance: (json['newBalance'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'topup',
      pointsAwarded: json['pointsAwarded'],
      newTotalPoints: json['newTotalPoints'],
      redeemedBy: json['redeemedBy'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
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
  final String? source; // 'ad_watch', 'daily_checkin', or 'topup'
  final int? streakDay; // For daily check-in
  final double? amount; // For topup - the TND amount
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
    this.amount,
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
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
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

/// Data class for aid removed event
class AidRemovedData {
  final String aidId;
  final String aidName;
  final String aidDisplayName;
  final DateTime timestamp;

  AidRemovedData({
    required this.aidId,
    required this.aidName,
    required this.aidDisplayName,
    required this.timestamp,
  });

  factory AidRemovedData.fromJson(Map<String, dynamic> json) {
    return AidRemovedData(
      aidId: json['aidId'] ?? '',
      aidName: json['aidName'] ?? '',
      aidDisplayName: json['aidDisplayName'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for pack updated event (generic refresh signal)
class PackUpdatedData {
  final String reason;
  final DateTime timestamp;

  PackUpdatedData({required this.reason, required this.timestamp});

  factory PackUpdatedData.fromJson(Map<String, dynamic> json) {
    return PackUpdatedData(
      reason: json['reason'] ?? 'unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for member left event (member voluntarily left the family)
class MemberLeftData {
  final String memberId;
  final String memberName;
  final DateTime timestamp;

  MemberLeftData({
    required this.memberId,
    required this.memberName,
    required this.timestamp,
  });

  factory MemberLeftData.fromJson(Map<String, dynamic> json) {
    return MemberLeftData(
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
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

/// Data class for profile picture updated event
class ProfilePictureUpdatedData {
  final String memberId;
  final String memberName;
  final String profilePictureUrl;
  final DateTime timestamp;

  ProfilePictureUpdatedData({
    required this.memberId,
    required this.memberName,
    required this.profilePictureUrl,
    required this.timestamp,
  });

  factory ProfilePictureUpdatedData.fromJson(Map<String, dynamic> json) {
    return ProfilePictureUpdatedData(
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for profile updated event (name, phone, etc.)
class ProfileUpdatedData {
  final String memberId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phone;
  final String? profilePictureUrl;
  final DateTime timestamp;

  ProfileUpdatedData({
    required this.memberId,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phone,
    this.profilePictureUrl,
    required this.timestamp,
  });

  factory ProfileUpdatedData.fromJson(Map<String, dynamic> json) {
    return ProfileUpdatedData(
      memberId: json['memberId'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      phone: json['phone'],
      profilePictureUrl: json['profilePictureUrl'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Get the display name from the profile data
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combined = '$first $last'.trim();
    return combined.isNotEmpty ? combined : 'Unknown';
  }
}

/// Data class for removal initiated event (owner confirmed member removal)
class RemovalInitiatedData {
  final String requestId;
  final String ownerName;
  final String familyId;
  final DateTime timestamp;

  RemovalInitiatedData({
    required this.requestId,
    required this.ownerName,
    required this.familyId,
    required this.timestamp,
  });

  factory RemovalInitiatedData.fromJson(Map<String, dynamic> json) {
    return RemovalInitiatedData(
      requestId: json['requestId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      familyId: json['familyId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for removal cancelled event (owner cancelled removal request)
class RemovalCancelledData {
  final String requestId;
  final String ownerName;
  final String familyId;
  final DateTime timestamp;

  RemovalCancelledData({
    required this.requestId,
    required this.ownerName,
    required this.familyId,
    required this.timestamp,
  });

  factory RemovalCancelledData.fromJson(Map<String, dynamic> json) {
    return RemovalCancelledData(
      requestId: json['requestId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      familyId: json['familyId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for rewards redeemed event (points converted to balance)
class RewardsRedeemedData {
  final String earnerId;
  final String memberName;
  final int pointsSpent;
  final double amountCredited;
  final double newBalance;
  final int newTotalPoints;
  final DateTime timestamp;

  RewardsRedeemedData({
    required this.earnerId,
    required this.memberName,
    required this.pointsSpent,
    required this.amountCredited,
    required this.newBalance,
    required this.newTotalPoints,
    required this.timestamp,
  });

  factory RewardsRedeemedData.fromJson(Map<String, dynamic> json) {
    return RewardsRedeemedData(
      earnerId: json['earnerId'] ?? '',
      memberName: json['memberName'] ?? '',
      pointsSpent: json['pointsSpent'] ?? 0,
      amountCredited: (json['amountCredited'] ?? 0).toDouble(),
      newBalance: (json['newBalance'] ?? 0).toDouble(),
      newTotalPoints: json['newTotalPoints'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Data class for ownership transferred event
class OwnershipTransferredData {
  final String oldOwnerId;
  final String oldOwnerName;
  final String newOwnerId;
  final String newOwnerName;
  final DateTime timestamp;

  OwnershipTransferredData({
    required this.oldOwnerId,
    required this.oldOwnerName,
    required this.newOwnerId,
    required this.newOwnerName,
    required this.timestamp,
  });

  factory OwnershipTransferredData.fromJson(Map<String, dynamic> json) {
    return OwnershipTransferredData(
      oldOwnerId: json['oldOwnerId'] ?? '',
      oldOwnerName: json['oldOwnerName'] ?? '',
      newOwnerId: json['newOwnerId'] ?? '',
      newOwnerName: json['newOwnerName'] ?? '',
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
  final _familyMemberJoinedController =
      StreamController<FamilyMemberJoinedData>.broadcast();
  final _pointsEarnedController =
      StreamController<PointsEarnedData>.broadcast();
  final _adsStatsUpdatedController =
      StreamController<AdsStatsUpdatedData>.broadcast();
  final _aidSelectedController = StreamController<AidSelectedData>.broadcast();
  final _aidRemovedController = StreamController<AidRemovedData>.broadcast();
  final _packUpdatedController = StreamController<PackUpdatedData>.broadcast();
  final _memberLeftController = StreamController<MemberLeftData>.broadcast();
  final _balanceUpdatedController =
      StreamController<BalanceUpdatedData>.broadcast();
  final _profilePictureUpdatedController =
      StreamController<ProfilePictureUpdatedData>.broadcast();
  final _profileUpdatedController =
      StreamController<ProfileUpdatedData>.broadcast();
  final _removalInitiatedController =
      StreamController<RemovalInitiatedData>.broadcast();
  final _removalCancelledController =
      StreamController<RemovalCancelledData>.broadcast();
  final _rewardsRedeemedController =
      StreamController<RewardsRedeemedData>.broadcast();
  final _ownershipTransferredController =
      StreamController<OwnershipTransferredData>.broadcast();

  /// Stream of socket events
  Stream<SocketEvent> get events => _eventController.stream;

  /// Stream of force logout events - listen to this to trigger logout
  Stream<ForceLogoutData> get onForceLogout => _forceLogoutController.stream;

  /// Stream of family member joined events - listen to this to update UI
  Stream<FamilyMemberJoinedData> get onFamilyMemberJoined =>
      _familyMemberJoinedController.stream;

  /// Stream of points earned events - listen to this to update rewards UI
  Stream<PointsEarnedData> get onPointsEarned => _pointsEarnedController.stream;

  /// Stream of ads stats updated events - listen to this to update pack UI
  Stream<AdsStatsUpdatedData> get onAdsStatsUpdated =>
      _adsStatsUpdatedController.stream;

  /// Stream of aid selected events - listen to this to update home screen
  Stream<AidSelectedData> get onAidSelected => _aidSelectedController.stream;

  /// Stream of aid removed events
  Stream<AidRemovedData> get onAidRemoved => _aidRemovedController.stream;

  /// Stream of pack updated events - listen to this to refresh pack data
  Stream<PackUpdatedData> get onPackUpdated => _packUpdatedController.stream;

  /// Stream of member left events - listen to this to update family member list
  Stream<MemberLeftData> get onMemberLeft => _memberLeftController.stream;

  /// Stream of balance updated events - listen to this to update balance display
  Stream<BalanceUpdatedData> get onBalanceUpdated =>
      _balanceUpdatedController.stream;

  /// Stream of profile picture updated events - listen to this to update UI
  Stream<ProfilePictureUpdatedData> get onProfilePictureUpdated =>
      _profilePictureUpdatedController.stream;

  /// Stream of profile updated events - listen to this to update member names/info
  Stream<ProfileUpdatedData> get onProfileUpdated =>
      _profileUpdatedController.stream;

  /// Stream of removal initiated events - listen to this when owner confirms removal
  Stream<RemovalInitiatedData> get onRemovalInitiated =>
      _removalInitiatedController.stream;

  /// Stream of removal cancelled events - listen to this when owner cancels removal
  Stream<RemovalCancelledData> get onRemovalCancelled =>
      _removalCancelledController.stream;

  /// Stream of rewards redeemed events - listen to this when points are converted to balance
  Stream<RewardsRedeemedData> get onRewardsRedeemed =>
      _rewardsRedeemedController.stream;

  /// Stream of ownership transferred events - listen to this when family owner changes
  Stream<OwnershipTransferredData> get onOwnershipTransferred =>
      _ownershipTransferredController.stream;

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
    final wsUrl = ApiConfig.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    debugPrint('🔌 Socket: Connecting to $wsUrl/session');

    _socket = io.io(
      '$wsUrl/session',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Add polling as fallback for Android
          .setAuth({'token': accessToken})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5) // Increased retries
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
      debugPrint(
        '🔌 Socket: Connection error (WebSocket may not be deployed yet)',
      );
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
        _forceLogoutController.add(
          ForceLogoutData(
            reason: 'new_login',
            message:
                'You have been logged out because your account was accessed from another device.',
            timestamp: DateTime.now(),
          ),
        );
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
      debugPrint('🎁 Socket: Received points_earned event - data: $data');
      if (data is Map<String, dynamic>) {
        final pointsData = PointsEarnedData.fromJson(data);
        debugPrint('🎁 Socket: Parsed points_earned - amount: ${pointsData.amount}, source: ${pointsData.source}');
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

    // Listen for aid removed event
    _socket!.on('aid_removed', (data) {
      debugPrint('🗑️ Socket: Received aid_removed event');
      if (data is Map<String, dynamic>) {
        final aidData = AidRemovedData.fromJson(data);
        _aidRemovedController.add(aidData);
        _eventController.add(SocketEvent.aidRemoved);
      }
    });

    // Listen for pack updated event (generic refresh signal)
    _socket!.on('pack_updated', (data) {
      debugPrint('📦 Socket: Received pack_updated event');
      if (data is Map<String, dynamic>) {
        final packData = PackUpdatedData.fromJson(data);
        _packUpdatedController.add(packData);
        _eventController.add(SocketEvent.packUpdated);
      }
    });

    // Listen for member left event (member voluntarily left the family)
    _socket!.on('member_left', (data) {
      debugPrint('👋 Socket: Received member_left event');
      if (data is Map<String, dynamic>) {
        final memberData = MemberLeftData.fromJson(data);
        _memberLeftController.add(memberData);
        _eventController.add(SocketEvent.familyMemberLeft);
      }
    });

    // Listen for balance updated event (top-up or rewards redemption)
    _socket!.on('balance_updated', (data) {
      debugPrint('💰 Socket: Received balance_updated event');
      if (data is Map<String, dynamic>) {
        final balanceData = BalanceUpdatedData.fromJson(data);
        _balanceUpdatedController.add(balanceData);
        _eventController.add(SocketEvent.balanceUpdated);
      }
    });

    // Listen for profile picture updated event (family member changed their picture)
    _socket!.on('profile_picture_updated', (data) {
      debugPrint('📸 Socket: Received profile_picture_updated event');
      if (data is Map<String, dynamic>) {
        final pictureData = ProfilePictureUpdatedData.fromJson(data);
        _profilePictureUpdatedController.add(pictureData);
        _eventController.add(SocketEvent.profilePictureUpdated);
      }
    });

    // Listen for profile updated event (family member changed name, phone, etc.)
    _socket!.on('profile_updated', (data) {
      debugPrint('👤 Socket: Received profile_updated event');
      if (data is Map<String, dynamic>) {
        final profileData = ProfileUpdatedData.fromJson(data);
        _profileUpdatedController.add(profileData);
        _eventController.add(SocketEvent.profileUpdated);
      }
    });

    // Listen for removal initiated event (owner confirmed removal request)
    _socket!.on('removal_initiated', (data) {
      debugPrint('⚠️ Socket: Received removal_initiated event');
      if (data is Map<String, dynamic>) {
        final removalData = RemovalInitiatedData.fromJson(data);
        _removalInitiatedController.add(removalData);
        _eventController.add(SocketEvent.removalInitiated);
      }
    });

    // Listen for removal cancelled event (owner cancelled removal request)
    _socket!.on('removal_cancelled', (data) {
      debugPrint('✅ Socket: Received removal_cancelled event');
      if (data is Map<String, dynamic>) {
        final cancellationData = RemovalCancelledData.fromJson(data);
        _removalCancelledController.add(cancellationData);
        _eventController.add(SocketEvent.removalCancelled);
      }
    });

    // Listen for rewards redeemed event (points converted to balance)
    _socket!.on('rewards_redeemed', (data) {
      debugPrint('🎁 Socket: Received rewards_redeemed event');
      if (data is Map<String, dynamic>) {
        final rewardsData = RewardsRedeemedData.fromJson(data);
        _rewardsRedeemedController.add(rewardsData);
        _eventController.add(SocketEvent.rewardsRedeemed);
      }
    });

    // Listen for ownership transferred event (family owner changed)
    _socket!.on('ownership_transferred', (data) {
      debugPrint('👑 Socket: Received ownership_transferred event');
      if (data is Map<String, dynamic>) {
        final transferData = OwnershipTransferredData.fromJson(data);
        _ownershipTransferredController.add(transferData);
        _eventController.add(SocketEvent.ownershipTransferred);
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
    _aidRemovedController.close();
    _packUpdatedController.close();
    _memberLeftController.close();
    _balanceUpdatedController.close();
    _profilePictureUpdatedController.close();
    _profileUpdatedController.close();
    _removalInitiatedController.close();
    _removalCancelledController.close();
    _rewardsRedeemedController.close();
    _ownershipTransferredController.close();
  }
}
