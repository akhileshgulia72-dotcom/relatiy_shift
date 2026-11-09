import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads mobile ads using the configured ad units for each platform.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const _androidRewardedId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: 'ca-app-pub-7694497723149363/2379319467',
  );
  static const _androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';
  static const _iosRewardedId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: 'ca-app-pub-7694497723149363/6627081469',
  );
  static const _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';
  static const _androidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-7694497723149363/1752633507',
  );
  static const _androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-7694497723149363/4454932430',
  );
  static const _iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  bool _initialized = false;
  Future<void>? _initializing;
  InterstitialAd? _interstitial;
  Future<InterstitialAd?>? _interstitialLoad;
  bool _showingInterstitial = false;
  DateTime? _lastInterstitialShown;
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String? _unitId({required String android, required String ios}) {
    if (!_isMobile) return null;
    return defaultTargetPlatform == TargetPlatform.iOS ? ios : android;
  }

  Future<void> initialize() {
    if (!_isMobile || _initialized) return Future.value();
    return _initializing ??= _initialize().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initialize() async {
    try {
      final updated = Completer<bool>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!updated.isCompleted) updated.complete(true);
        },
        (_) {
          if (!updated.isCompleted) updated.complete(false);
        },
      );
      final didUpdate = await updated.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
      if (didUpdate) {
        privacyOptionsRequired.value =
            await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {}).timeout(
          const Duration(minutes: 2),
        );
      }
      if (!await _mayRequestAds()) return;
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
    if (!await _mayRequestAds()) return false;
    final unitId = _unitId(
      android: kProfileMode ? _androidRewardedTestId : _androidRewardedId,
      ios: kProfileMode ? _iosRewardedTestId : _iosRewardedId,
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

  static const _completionAdLevels = {3, 7, 10, 13, 16, 19};

  /// Shows an interstitial at most once per eligible level, after completion.
  Future<void> showInterstitialAtTransition(int completedLevel) async {
    if (!_initialized ||
        !_isMobile ||
        !_completionAdLevels.contains(completedLevel)) {
      return;
    }
    if (_interstitial == null) {
      unawaited(_loadInterstitial());
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownKey = 'level${completedLevel}CompletionInterstitialShown';
      if (prefs.getBool(shownKey) ?? false) return;

      if (await _showInterstitial(readyOnly: true)) {
        await prefs.setBool(shownKey, true);
      }
    } catch (_) {
      // A failed ad must never block level completion or progression.
    }
  }

  /// An interstitial due from navigation is shown only on a menu route.
  Future<bool> showNavigationInterstitial() => _showInterstitial();

  Future<bool> _showInterstitial({bool readyOnly = false}) async {
    if (!_initialized || !_isMobile || _showingInterstitial) return false;
    if (readyOnly && _interstitial == null) return false;
    final lastShown = _lastInterstitialShown;
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < const Duration(seconds: 20)) {
      return false;
    }
    _showingInterstitial = true;
    try {
      if (!await _mayRequestAds()) return false;
      final ad = readyOnly ? _interstitial : await _loadInterstitial();
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

  Future<InterstitialAd?> _loadInterstitial() async {
    if (!await _mayRequestAds()) return null;
    if (_interstitial != null) return Future.value(_interstitial);
    if (_interstitialLoad != null) return _interstitialLoad!;
    final unitId = _unitId(
      android: kProfileMode
          ? _androidInterstitialTestId
          : _androidInterstitialId,
      ios: kProfileMode ? _iosInterstitialTestId : _iosInterstitialId,
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

  Future<bool> _mayRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  Future<bool> showPrivacyOptions() async {
    if (!_isMobile || !privacyOptionsRequired.value) return false;
    try {
      FormError? error;
      await ConsentForm.showPrivacyOptionsForm((value) => error = value);
      _interstitial?.dispose();
      _interstitial = null;
      if (error != null) return false;
      if (!_initialized) unawaited(initialize());
      return true;
    } catch (_) {
      return false;
    }
  }
}
