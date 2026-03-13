import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_platform.dart';

/// Кэш и предзагрузка вознаграждаемой рекламы.
RewardedAd? _cachedRewardedAd;
bool _isPreloadingRewarded = false;

/// Предзагрузка вознаграждаемой рекламы (вызывается после инициализации AdMob).
void preloadRewardedAd() {
  final adUnitId = rewardedAdUnitId;
  if (adUnitId.isEmpty || _cachedRewardedAd != null || _isPreloadingRewarded) return;
  _isPreloadingRewarded = true;
  RewardedAd.load(
    adUnitId: adUnitId,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (RewardedAd ad) {
        _isPreloadingRewarded = false;
        _cachedRewardedAd?.dispose();
        _cachedRewardedAd = ad;
      },
      onAdFailedToLoad: (LoadAdError error) {
        debugPrint('RewardedAd preload failed: $error');
        _isPreloadingRewarded = false;
      },
    ),
  );
}

/// Показывает вознаграждаемую рекламу. Если есть предзагруженная — показывает сразу; иначе загружает в момент вызова.
/// [onRewarded] — пользователь досмотрел и получил награду.
/// [onAdReadyToShow] — реклама загружена и сейчас будет показана (удобно скрыть спиннер).
/// [onDismissed] — реклама закрыта (вызвать в любом случае после показа, например onAppResumed).
/// [onNotAvailable] — реклама недоступна (нет платформы, ошибка загрузки).
Future<void> showRewardedAd(
  BuildContext context, {
  required VoidCallback onRewarded,
  VoidCallback? onAdReadyToShow,
  VoidCallback? onDismissed,
  VoidCallback? onNotAvailable,
}) async {
  final adUnitId = rewardedAdUnitId;
  if (adUnitId.isEmpty) {
    onNotAvailable?.call();
    return;
  }

  void showAd(RewardedAd loadedAd) {
    onAdReadyToShow?.call();
    loadedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad a) {
        a.dispose();
        preloadRewardedAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (Ad a, AdError error) {
        a.dispose();
        preloadRewardedAd();
        if (context.mounted) {
          onNotAvailable?.call();
          onDismissed?.call();
        }
      },
    );
    loadedAd.show(
      onUserEarnedReward: (AdWithoutView a, RewardItem reward) {
        onRewarded();
      },
    );
  }

  // Есть предзагруженная реклама — показываем сразу
  final cached = _cachedRewardedAd;
  if (cached != null) {
    _cachedRewardedAd = null;
    showAd(cached);
    return;
  }

  // Нет кэша — загружаем по требованию
  RewardedAd.load(
    adUnitId: adUnitId,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (RewardedAd loadedAd) {
        showAd(loadedAd);
      },
      onAdFailedToLoad: (LoadAdError error) {
        debugPrint('RewardedAd failed to load: $error');
        if (context.mounted) onNotAvailable?.call();
      },
    ),
  );
}
