import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uses sample ad units in debug builds and the configured iOS units in release.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const _androidRewardedId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const _iosRewardedId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: 'ca-app-pub-7694497723149363/6627081469',
  );
  static const _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';
  static const _androidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const _iosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-7694497723149363/4454932430',
  );
  static const _iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  bool _initialized = false;
  InterstitialAd? _interstitial;
  Future<InterstitialAd?>? _interstitialLoad;
  bool _showingInterstitial = false;
  DateTime? _lastInterstitialShown;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String? _unitId({required String android, required String ios}) {
    if (!_isMobile) return null;
    return defaultTargetPlatform == TargetPlatform.iOS ? ios : android;
  }

  Future<void> initialize() async {
    if (!_isMobile || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(_loadInterstitial());
    } catch (_) {
      // Ads are optional; the puzzle remains playable when the SDK is absent.
    }
  }

  /// Returns true only after Google invokes the earned-reward callback.
  Future<bool> showRewardedHint() => showRewardedReward();

  /// Each invocation loads and shows a new rewarded ad. Callers must grant
  /// gameplay benefits only when this returns true.
  Future<bool> showRewardedReward() async {
    if (!_initialized || !_isMobile) return false;
    final unitId = _unitId(
      android: _androidRewardedId,
      ios: kReleaseMode ? _iosRewardedId : _iosRewardedTestId,
    );
    if (unitId == null) return false;

    final loaded = Completer<RewardedAd?>();
    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: loaded.complete,
          onAdFailedToLoad: (_) => loaded.complete(null),
        ),
      );
      final ad = await loaded.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      if (ad == null) return false;

      final result = Completer<bool>();
      var earned = false;
      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!result.isCompleted) result.complete(earned);
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          if (!result.isCompleted) result.complete(false);
        },
      );
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
      return await result.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> showRewardedSkip() => showRewardedReward();

  /// Called from a level transition after the completion UI. It never runs
  /// while the player is solving a puzzle.
  Future<void> showInterstitialAtTransition() async {
    if (!_initialized || !_isMobile) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedLevels = Iterable<int>.generate(20)
          .where((index) => (prefs.getInt('level${index + 1}Stars') ?? 0) > 0)
          .length;
      const milestoneKey = 'lastInterstitialThreeMilestone';
      final milestone = (prefs.getInt(milestoneKey) ?? 0) + 3;
      if (completedLevels < milestone) return;

      if (await _showInterstitial()) {
        await prefs.setInt(milestoneKey, milestone);
      }
    } catch (_) {
      // A failed ad must never block level completion or progression.
    }
  }

  /// An interstitial due from navigation is shown only on a menu route.
  Future<bool> showNavigationInterstitial() => _showInterstitial();

  Future<bool> _showInterstitial() async {
    if (!_initialized || !_isMobile || _showingInterstitial) return false;
    final lastShown = _lastInterstitialShown;
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < const Duration(seconds: 20)) {
      return false;
    }
    _showingInterstitial = true;
    try {
      final ad = await _loadInterstitial();
      if (ad == null) return false;
      _interstitial = null;
      final dismissed = Completer<void>();
      var didShow = false;
      ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
        onAdShowedFullScreenContent: (_) => didShow = true,
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!dismissed.isCompleted) dismissed.complete();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          if (!dismissed.isCompleted) dismissed.complete();
        },
      );
      try {
        await ad.show();
        await dismissed.future.timeout(const Duration(minutes: 3));
      } catch (_) {
        ad.dispose();
        return false;
      }
      if (didShow) {
        _lastInterstitialShown = DateTime.now();
        unawaited(_loadInterstitial());
      }
      return didShow;
    } catch (_) {
      return false;
    } finally {
      _showingInterstitial = false;
    }
  }

  Future<InterstitialAd?> _loadInterstitial() {
    if (_interstitial != null) return Future.value(_interstitial);
    if (_interstitialLoad != null) return _interstitialLoad!;
    final unitId = _unitId(
      android: _androidInterstitialId,
      ios: kReleaseMode ? _iosInterstitialId : _iosInterstitialTestId,
    );
    if (unitId == null) return Future.value(null);

    final loaded = Completer<InterstitialAd?>();
    _interstitialLoad = loaded.future;
    unawaited(
      InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            _interstitialLoad = null;
            if (!loaded.isCompleted) loaded.complete(ad);
          },
          onAdFailedToLoad: (_) {
            _interstitialLoad = null;
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      ).catchError((Object _) {
        _interstitialLoad = null;
        if (!loaded.isCompleted) loaded.complete(null);
      }),
    );
    return loaded.future;
  }
}
