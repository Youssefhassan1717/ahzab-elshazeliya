import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._();
  static RewardedAdService get instance => _instance;
  RewardedAdService._();

  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _realAdUnitId = 'ca-app-pub-5932903511323482/7698005739';

  static String get _adUnitId => kDebugMode ? _testAdUnitId : _realAdUnitId;

  RewardedAd? _rewardedAd;
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  void preload() {
    _loadAd();
  }

  void _loadAd() {
    _isLoaded = false;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoaded = false;
        },
      ),
    );
  }

  void showAd({
    required VoidCallback onRewarded,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  }) {
    if (!_isLoaded || _rewardedAd == null) {
      onFailed();
      _loadAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
        _loadAd();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
        _loadAd();
        onFailed();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (_, __) {
      onRewarded();
    });
  }
}
