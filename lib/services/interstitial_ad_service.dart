import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_platform.dart';
import '../config/ad_config.dart';

/// Триггеры для межстраничной рекламы (см. план §4.3).
enum InterstitialTrigger {
  viewStatistics,
  continueGame,
  startNewGame,
  newGameInHeader,
  backToMenu,
  restartGameOver,
  restartYouWon,
  notes,
}

/// Сервис показа межстраничной рекламы с лимитами по времени и «каждое N-е».
/// Поддерживает предзагрузку: при показе используется кэш, если нет — загружается по требованию.
class InterstitialAdService {
  InterstitialAdService._();

  static DateTime? _lastShowTime;
  static int _continueCount = 0;
  static int _startNewGameCount = 0;
  static int _newGameInHeaderCount = 0;
  static int _backToMenuCount = 0;
  static int _notesCount = 0;

  static InterstitialAd? _cachedAd;
  static bool _isPreloading = false;

  /// Предзагрузка межстраничной рекламы (вызывается после инициализации AdMob).
  static void preload() {
    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty || _cachedAd != null || _isPreloading) return;
    _isPreloading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isPreloading = false;
          _cachedAd?.dispose();
          _cachedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd preload failed: $error');
          _isPreloading = false;
        },
      ),
    );
  }

  /// Пытается показать interstitial по триггеру. Если есть предзагруженная реклама — показывает сразу;
  /// иначе загружает, показывает, по закрытию вызывает [onDone]. Если показ не разрешён или реклама недоступна — сразу [onDone].
  static Future<void> tryShowInterstitial(
    BuildContext context,
    InterstitialTrigger trigger, {
    required VoidCallback onDone,
    Widget Function(BuildContext)? loadingDialog,
  }) async {
    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) {
      onDone();
      return;
    }

    final now = DateTime.now();
    final minInterval = Duration(minutes: AdConfig.interstitialMinIntervalMinutes);
    final restartMinInterval = Duration(minutes: AdConfig.interstitialRestartMinIntervalMinutes);

    final canShowByTime = _lastShowTime == null ||
        now.difference(_lastShowTime!) >= minInterval;

    final isRestart = trigger == InterstitialTrigger.restartGameOver ||
        trigger == InterstitialTrigger.restartYouWon;
    final canShowByRestartTime = !isRestart ||
        _lastShowTime == null ||
        now.difference(_lastShowTime!) >= restartMinInterval;

    bool shouldShow = false;
    switch (trigger) {
      case InterstitialTrigger.viewStatistics:
        shouldShow = canShowByTime && canShowByRestartTime;
        break;
      case InterstitialTrigger.continueGame:
        _continueCount++;
        shouldShow = canShowByTime &&
            canShowByRestartTime &&
            _continueCount % AdConfig.interstitialEveryNthContinue == 0;
        break;
      case InterstitialTrigger.startNewGame:
        _startNewGameCount++;
        shouldShow = canShowByTime &&
            canShowByRestartTime &&
            _startNewGameCount % AdConfig.interstitialEveryNthStartNewGame == 0;
        break;
      case InterstitialTrigger.newGameInHeader:
        _newGameInHeaderCount++;
        shouldShow = canShowByTime &&
            canShowByRestartTime &&
            _newGameInHeaderCount % AdConfig.interstitialEveryNthNewGameInHeader == 0;
        break;
      case InterstitialTrigger.backToMenu:
        _backToMenuCount++;
        shouldShow = canShowByTime &&
            canShowByRestartTime &&
            _backToMenuCount % AdConfig.interstitialEveryNthBackToMenu == 0;
        break;
      case InterstitialTrigger.restartGameOver:
      case InterstitialTrigger.restartYouWon:
        shouldShow = canShowByTime && canShowByRestartTime;
        break;
      case InterstitialTrigger.notes:
        _notesCount++;
        shouldShow = canShowByTime &&
            canShowByRestartTime &&
            _notesCount % AdConfig.interstitialEveryNthNotes == 0;
        break;
    }

    if (!shouldShow) {
      onDone();
      return;
    }

    void onAdDismissed(Ad a) {
      _lastShowTime = DateTime.now();
      a.dispose();
      preload();
      onDone();
    }

    void onAdFailedToShow(Ad a, AdError error) {
      debugPrint('InterstitialAd failed to show: $error');
      a.dispose();
      preload();
      onDone();
    }

    // Есть предзагруженная реклама — показываем сразу без диалога загрузки
    final cached = _cachedAd;
    if (cached != null) {
      _cachedAd = null;
      cached.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: onAdDismissed,
        onAdFailedToShowFullScreenContent: onAdFailedToShow,
      );
      cached.show();
      return;
    }

    // Нет кэша — показываем спиннер и загружаем по требованию
    final loader = loadingDialog ?? _defaultLoadingDialog;
    if (context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => loader(context),
      );
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (!context.mounted) {
            ad.dispose();
            onDone();
            return;
          }
          Navigator.of(context).pop();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: onAdDismissed,
            onAdFailedToShowFullScreenContent: onAdFailedToShow,
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          if (context.mounted) Navigator.of(context).pop();
          onDone();
        },
      ),
    );
  }

  static Widget _defaultLoadingDialog(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              'Loading ad…',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

