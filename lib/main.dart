import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'services/rewarded_ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  RewardedAdService.instance.preload();
  runApp(const AhzabApp());
}
