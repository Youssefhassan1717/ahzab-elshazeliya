import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages interstitial ad lifecycle — preloads, shows, and reloads.
class InterstitialAdService {
  static final InterstitialAdService _instance = InterstitialAdService._();
  static InterstitialAdService get instance => _instance;
  InterstitialAdService._();

  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _realAdUnitId = 'ca-app-pub-5932903511323482/6496604701';

  static String get _adUnitId => kDebugMode ? _testAdUnitId : _realAdUnitId;

  InterstitialAd? _interstitialAd;
  bool _isLoaded = false;

  /// Call once at app startup to begin preloading.
  void preload() {
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoaded = false;
        },
      ),
    );
  }

  /// Shows the interstitial if ready, then calls [onComplete].
  /// If not ready, calls [onComplete] immediately without blocking.
  void showAd({required VoidCallback onComplete}) {
    if (!_isLoaded || _interstitialAd == null) {
      // Ad not ready — don't block the user
      onComplete();
      _loadAd(); // Try loading for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
        _loadAd(); // Preload next ad
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
        _loadAd();
        onComplete();
      },
    );

    _interstitialAd!.show();
  }
}
