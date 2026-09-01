import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'rewarded_ad_service.dart';

/// Kept out of `main()` because the SDK's native init stutters the intro screen.
class AdsBootstrap {
  static bool _started = false;

  static void start() {
    if (_started) return;
    _started = true;
    MobileAds.instance.initialize();
    RewardedAdService.instance.preload();
  }
}
