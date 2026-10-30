import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reality_shift/screens/splash/splash_screen.dart';
import 'package:reality_shift/services/ads_service.dart';
import 'package:reality_shift/services/menu_music_service.dart';
import 'package:reality_shift/services/navigation_ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RealityShiftApp());
  unawaited(AdsService.instance.initialize());
  unawaited(MenuMusicService.instance.initialize());
}

class RealityShiftApp extends StatelessWidget {
  const RealityShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reality Shift',
      theme: ThemeData.dark(),
      navigatorObservers: [navigationAdObserver, menuMusicRouteObserver],
      home: const SplashScreen(),
    );
  }
}
