import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_platform.dart';

/// Показывает вознаграждаемую рекламу.
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

  RewardedAd.load(
    adUnitId: adUnitId,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (RewardedAd loadedAd) {
        onAdReadyToShow?.call();
        loadedAd.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (Ad a) {
            a.dispose();
            onDismissed?.call();
          },
          onAdFailedToShowFullScreenContent: (Ad a, AdError error) {
            a.dispose();
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
      },
      onAdFailedToLoad: (LoadAdError error) {
        debugPrint('RewardedAd failed to load: $error');
        if (context.mounted) onNotAvailable?.call();
      },
    ),
  );
}
