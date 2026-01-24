import 'dart:io';

/// Helper class for AdMob ad unit IDs
/// Uses test IDs in debug mode and production IDs in release mode
class AdHelper {
  /// Test rewarded ad unit ID for Android
  static const String _testRewardedAdIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';

  /// Test rewarded ad unit ID for iOS
  static const String _testRewardedAdIdIOS =
      'ca-app-pub-3940256099942544/1712485313';

  // TODO: Replace with your production ad unit IDs
  static const String _prodRewardedAdIdAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodRewardedAdIdIOS =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  /// Whether to use test ads (set to false in production)
  static const bool useTestAds = true;

  /// Get the rewarded ad unit ID for the current platform
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds ? _testRewardedAdIdAndroid : _prodRewardedAdIdAndroid;
    } else if (Platform.isIOS) {
      return useTestAds ? _testRewardedAdIdIOS : _prodRewardedAdIdIOS;
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  /// Test banner ad unit IDs (if needed in future)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android test banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  /// Test interstitial ad unit IDs (if needed in future)
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android test interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS test interstitial
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }
}
