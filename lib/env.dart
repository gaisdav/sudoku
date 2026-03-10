import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Доступ к переменным окружения из .env (или .env.example).
/// Значения из --dart-define имеют приоритет над .env.
///
/// Использование:
/// 1. Скопируйте .env.example в .env и при необходимости подставьте свои ID.
/// 2. Для релиза можно передавать ID через:
///    flutter build apk --dart-define=ADMOB_APP_ID_ANDROID=ca-app-pub-xxx
class Env {
  Env._();

  /// Читает значение по ключу из .env.
  static String? get(String key) => dotenv.env[key];

  /// То же, но возвращает [defaultValue], если значения нет.
  static String getOr(String key, String defaultValue) =>
      dotenv.env[key] ?? defaultValue;

  // --- AdMob: приоритет --dart-define, затем .env

  static String get admobAppIdAndroid =>
      _def('ADMOB_APP_ID_ANDROID', dotenv.env['ADMOB_APP_ID_ANDROID']);

  static String get admobAppIdIos =>
      _def('ADMOB_APP_ID_IOS', dotenv.env['ADMOB_APP_ID_IOS']);

  static String get admobBannerIdAndroid =>
      _def('ADMOB_BANNER_ID_ANDROID', dotenv.env['ADMOB_BANNER_ID_ANDROID']);

  static String get admobBannerIdIos =>
      _def('ADMOB_BANNER_ID_IOS', dotenv.env['ADMOB_BANNER_ID_IOS']);

  static String get admobInterstitialIdAndroid => _def(
      'ADMOB_INTERSTITIAL_ID_ANDROID',
      dotenv.env['ADMOB_INTERSTITIAL_ID_ANDROID']);

  static String get admobInterstitialIdIos =>
      _def('ADMOB_INTERSTITIAL_ID_IOS', dotenv.env['ADMOB_INTERSTITIAL_ID_IOS']);

  static String get admobRewardedIdAndroid =>
      _def('ADMOB_REWARDED_ID_ANDROID', dotenv.env['ADMOB_REWARDED_ID_ANDROID']);

  static String get admobRewardedIdIos =>
      _def('ADMOB_REWARDED_ID_IOS', dotenv.env['ADMOB_REWARDED_ID_IOS']);

  static String get admobAppOpenIdAndroid =>
      _def('ADMOB_APP_OPEN_ID_ANDROID', dotenv.env['ADMOB_APP_OPEN_ID_ANDROID']);

  static String get admobAppOpenIdIos =>
      _def('ADMOB_APP_OPEN_ID_IOS', dotenv.env['ADMOB_APP_OPEN_ID_IOS']);

  static String _def(String dartDefineKey, String? envValue) {
    final fromDefine =
        String.fromEnvironment(dartDefineKey, defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    return envValue ?? '';
  }
}
