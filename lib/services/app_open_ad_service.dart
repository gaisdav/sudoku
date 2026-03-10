import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_platform.dart';
import '../config/ad_config.dart';
import 'game_storage.dart';

/// Реклама при открытии приложения (cold start и возврат из фона).
/// Счётчики и время ухода в фон хранятся в Hive (тот же box, что и GameStorage).
class AppOpenAdService {
  AppOpenAdService._();

  static const _keyColdStartCount = 'app_open_cold_start_count';
  static const _keyResumeCount = 'app_open_resume_count';
  static const _keyLastBackgroundMillis = 'app_open_last_background_millis';

  static int _getInt(String key) =>
      (GameStorage.box.get(key) as num?)?.toInt() ?? 0;

  static Future<void> _setInt(String key, int value) async =>
      GameStorage.box.put(key, value);

  static int? _getLastBackgroundMillis() {
    final v = GameStorage.box.get(_keyLastBackgroundMillis);
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static Future<void> _setLastBackgroundMillis(int? millis) async {
    if (millis == null) {
      await GameStorage.box.delete(_keyLastBackgroundMillis);
    } else {
      await GameStorage.box.put(_keyLastBackgroundMillis, millis);
    }
  }

  /// Вызывать при первом кадре после запуска приложения (cold start).
  static void maybeShowColdStart() {
    final adUnitId = appOpenAdUnitId;
    if (adUnitId.isEmpty) return;
    try {
      final count = _getInt(_keyColdStartCount) + 1;
      _setInt(_keyColdStartCount, count);
      final everyNth = AdConfig.appOpenEveryNthColdStart;
      if (everyNth <= 0 || count % everyNth != 0) return;
      _loadAndShow(adUnitId);
    } catch (_) {}
  }

  /// Вызывать при переходе приложения в фон (paused).
  static void onAppPaused() {
    try {
      _setLastBackgroundMillis(DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Вызывать при возврате из фона (resumed). Показывает рекламу, если в фоне были не менее N секунд и счётчик resume кратен N.
  static void maybeShowResume() {
    final adUnitId = appOpenAdUnitId;
    if (adUnitId.isEmpty) return;
    try {
      final lastMillis = _getLastBackgroundMillis();
      if (lastMillis == null) return;
      final minSeconds = AdConfig.appOpenResumeMinBackgroundSeconds;
      final elapsedSeconds =
          (DateTime.now().millisecondsSinceEpoch - lastMillis) / 1000;
      if (elapsedSeconds < minSeconds) return;

      final count = _getInt(_keyResumeCount) + 1;
      _setInt(_keyResumeCount, count);
      final everyNth = AdConfig.appOpenEveryNthResume;
      if (everyNth <= 0 || count % everyNth != 0) return;
      _loadAndShow(adUnitId);
    } catch (_) {}
  }

  static void _loadAndShow(String adUnitId) {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (Ad a) => a.dispose(),
            onAdFailedToShowFullScreenContent: (Ad a, AdError error) =>
                a.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }
}
