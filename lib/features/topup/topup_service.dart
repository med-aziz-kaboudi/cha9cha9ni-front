import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/config/api_config.dart';

/// Cache keys for TopUp data
class _TopUpCacheKeys {
  static const String balanceInfo = 'topup_balance_info';
  static const String lastFetchTime = 'topup_last_fetch_time';
  static const String failedAttempts = 'topup_failed_attempts';
  static const String lockoutUntil = 'topup_lockout_until';
}

/// Rate limiting constants
class _RateLimitConfig {
  static const int maxFailedAttempts = 3;
  static const Duration lockoutDuration = Duration(hours: 1);
}

class TopUpService {
  final _tokenStorage = TokenStorageService();

  // In-memory cache
  static BalanceInfo? _cachedBalance;
  static DateTime? _lastFetchTime;

  // Cache duration - 5 minutes (but we mainly rely on invalidation after topup)
  static const _cacheDuration = Duration(minutes: 5);

  /// Get in-memory cached balance synchronously (instant, no await needed)
  /// Returns null only if balance was never loaded in this session
  static BalanceInfo? get cachedBalanceSync => _cachedBalance;

  /// Get balance from cache first, then optionally fetch from network
  Future<BalanceInfo?> getCachedBalance() async {
    // Return in-memory cache if available
    if (_cachedBalance != null) {
      return _cachedBalance;
    }

    // Try loading from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final balanceJson = prefs.getString(_TopUpCacheKeys.balanceInfo);

      if (balanceJson != null) {
        final data = jsonDecode(balanceJson) as Map<String, dynamic>;
        _cachedBalance = BalanceInfo.fromJson(data);

        final lastFetch = prefs.getInt(_TopUpCacheKeys.lastFetchTime);
        if (lastFetch != null) {
          _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
        }

        return _cachedBalance;
      }
    } catch (e) {
      // Ignore cache errors
    }

    return null;
  }

  /// Check if we need to fetch fresh data
  bool shouldFetchFresh() {
    if (_cachedBalance == null || _lastFetchTime == null) {
      return true;
    }
    return DateTime.now().difference(_lastFetchTime!) > _cacheDuration;
  }

  /// Save balance to cache
  Future<void> _saveToCache(BalanceInfo balance) async {
    _cachedBalance = balance;
    _lastFetchTime = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _TopUpCacheKeys.balanceInfo,
        jsonEncode(balance.toJson()),
      );
      await prefs.setInt(
        _TopUpCacheKeys.lastFetchTime,
        _lastFetchTime!.millisecondsSinceEpoch,
      );
    } catch (e) {
      // Ignore cache save errors
    }
  }

  /// Clear the cache (useful on logout)
  static void clearCache() {
    debugPrint('💰 TopUpService: Clearing balance cache');
    _cachedBalance = null;
    _lastFetchTime = null;
  }

  /// Update cache from socket event (called when balance_updated event is received)
  /// This keeps the TopUp screen cache in sync with real-time updates
  static void updateCacheFromSocket({
    required double newBalance,
    required int newTotalPoints,
  }) {
    debugPrint('💰 TopUpService: Socket update - balance: $newBalance, points: $newTotalPoints');
    _cachedBalance = BalanceInfo(
      balance: newBalance,
      hasTopUp: true,
      totalPoints: newTotalPoints,
    );
    _lastFetchTime = DateTime.now();
  }

  /// Invalidate cache to force fresh fetch next time
  static void invalidateCache() {
    _lastFetchTime = null;
  }

  // ============ RATE LIMITING FOR FAILED ATTEMPTS ============

  /// Check if user is currently locked out from redemptions
  static Future<RateLimitStatus> checkRateLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutUntilMs = prefs.getInt(_TopUpCacheKeys.lockoutUntil);
      
      if (lockoutUntilMs != null) {
        final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs);
        if (DateTime.now().isBefore(lockoutUntil)) {
          final remaining = lockoutUntil.difference(DateTime.now());
          return RateLimitStatus(
            isLocked: true,
            remainingAttempts: 0,
            lockoutRemaining: remaining,
          );
        } else {
          // Lockout expired, clear it
          await _clearRateLimitData();
        }
      }

      final failedAttempts = prefs.getInt(_TopUpCacheKeys.failedAttempts) ?? 0;
      return RateLimitStatus(
        isLocked: false,
        remainingAttempts: _RateLimitConfig.maxFailedAttempts - failedAttempts,
        lockoutRemaining: null,
      );
    } catch (e) {
      return RateLimitStatus(isLocked: false, remainingAttempts: 3, lockoutRemaining: null);
    }
  }

  /// Record a failed redemption attempt
  static Future<RateLimitStatus> recordFailedAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentAttempts = (prefs.getInt(_TopUpCacheKeys.failedAttempts) ?? 0) + 1;
      await prefs.setInt(_TopUpCacheKeys.failedAttempts, currentAttempts);

      if (currentAttempts >= _RateLimitConfig.maxFailedAttempts) {
        // Lock the user out
        final lockoutUntil = DateTime.now().add(_RateLimitConfig.lockoutDuration);
        await prefs.setInt(_TopUpCacheKeys.lockoutUntil, lockoutUntil.millisecondsSinceEpoch);
        return RateLimitStatus(
          isLocked: true,
          remainingAttempts: 0,
          lockoutRemaining: _RateLimitConfig.lockoutDuration,
        );
      }

      return RateLimitStatus(
        isLocked: false,
        remainingAttempts: _RateLimitConfig.maxFailedAttempts - currentAttempts,
        lockoutRemaining: null,
      );
    } catch (e) {
      return RateLimitStatus(isLocked: false, remainingAttempts: 0, lockoutRemaining: null);
    }
  }

  /// Clear rate limit on successful redemption
  static Future<void> clearRateLimitOnSuccess() async {
    await _clearRateLimitData();
  }

  static Future<void> _clearRateLimitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_TopUpCacheKeys.failedAttempts);
      await prefs.remove(_TopUpCacheKeys.lockoutUntil);
    } catch (e) {
      // Ignore
    }
  }

  // ============ END RATE LIMITING ============

  /// Redeem a scratch card code
  /// Returns: amount, points, newBalance, newTotalPoints
  Future<TopUpResult> redeemScratchCard(String code) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Normalize code: remove dashes, spaces, uppercase
    final normalizedCode = code.replaceAll(RegExp(r'[-\s]'), '').toUpperCase();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/topup/redeem'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': normalizedCode}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final result = TopUpResult(
        success: true,
        amount: (data['data']['amount'] as num).toDouble(),
        points: data['data']['points'] as int,
        newBalance: (data['data']['newBalance'] as num).toDouble(),
        newTotalPoints: data['data']['newTotalPoints'] as int,
        message: data['message'] ?? 'Top-up successful!',
      );

      // Update the cache with new balance after successful topup
      await _saveToCache(
        BalanceInfo(
          balance: result.newBalance,
          hasTopUp: true,
          totalPoints: result.newTotalPoints,
        ),
      );

      return result;
    } else {
      throw Exception(data['message'] ?? 'Failed to redeem scratch card');
    }
  }

  /// Get family balance (always fetches from network and updates cache)
  Future<BalanceInfo> getBalance({bool forceRefresh = false}) async {
    debugPrint('💰 TopUpService.getBalance() - fetching from API...');
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/topup/balance'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final balance = BalanceInfo(
        balance: (data['data']['balance'] as num).toDouble(),
        hasTopUp: data['data']['hasTopUp'] as bool,
        totalPoints: data['data']['totalPoints'] as int,
      );

      debugPrint('\ud83d\udcb0 TopUpService.getBalance() - got balance: ${balance.balance}');
      
      // Update in-memory cache only (for TopUp screen)
      _cachedBalance = balance;
      _lastFetchTime = DateTime.now();

      return balance;
    } else {
      throw Exception(data['message'] ?? 'Failed to get balance');
    }
  }

  /// Check if user can redeem rewards
  Future<bool> canRedeemRewards() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/topup/can-redeem-rewards'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data['success'] == true && data['data']['canRedeem'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get top-up history
  Future<List<TopUpTransaction>> getHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/topup/history?limit=$limit&offset=$offset',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((t) => TopUpTransaction.fromJson(t))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to get history');
    }
  }

  /// Convenience method to get just the family balance as a double
  Future<double> getFamilyBalance() async {
    final balanceInfo = await getBalance();
    return balanceInfo.balance;
  }
}

class TopUpResult {
  final bool success;
  final double amount;
  final int points;
  final double newBalance;
  final int newTotalPoints;
  final String message;

  TopUpResult({
    required this.success,
    required this.amount,
    required this.points,
    required this.newBalance,
    required this.newTotalPoints,
    required this.message,
  });
}

class BalanceInfo {
  final double balance;
  final bool hasTopUp;
  final int totalPoints;

  BalanceInfo({
    required this.balance,
    required this.hasTopUp,
    required this.totalPoints,
  });

  factory BalanceInfo.fromJson(Map<String, dynamic> json) {
    return BalanceInfo(
      balance: (json['balance'] as num).toDouble(),
      hasTopUp: json['hasTopUp'] as bool,
      totalPoints: json['totalPoints'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'hasTopUp': hasTopUp,
      'totalPoints': totalPoints,
    };
  }
}

class TopUpTransaction {
  final String id;
  final String type;
  final double amount;
  final int pointsAwarded;
  final double balanceAfter;
  final String status;
  final DateTime createdAt;

  TopUpTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.pointsAwarded,
    required this.balanceAfter,
    required this.status,
    required this.createdAt,
  });

  factory TopUpTransaction.fromJson(Map<String, dynamic> json) {
    return TopUpTransaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      pointsAwarded: json['pointsAwarded'] as int,
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Rate limit status for scratch card redemption
class RateLimitStatus {
  final bool isLocked;
  final int remainingAttempts;
  final Duration? lockoutRemaining;

  RateLimitStatus({
    required this.isLocked,
    required this.remainingAttempts,
    this.lockoutRemaining,
  });

  String get lockoutRemainingFormatted {
    if (lockoutRemaining == null) return '';
    final minutes = lockoutRemaining!.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}
