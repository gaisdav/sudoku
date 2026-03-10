import '../env.dart';

/// Параметры управления рекламой (Interstitial, App Open).
/// Значения читаются из .env; ключи и значения по умолчанию см. в .env.example.
///
/// Использование: при реализации Interstitial и App Open обращаться к полям этого класса
/// вместо констант — так можно менять поведение через .env без пересборки.
class AdConfig {
  AdConfig._();

  static int _int(String key, int defaultValue) {
    final s = Env.get(key);
    if (s == null || s.isEmpty) return defaultValue;
    return int.tryParse(s) ?? defaultValue;
  }

  // --- Interstitial (межстраничная реклама) ---

  /// Минимальный интервал (минуты) между любыми показами interstitial.
  /// См. INTERSTITIAL_MIN_INTERVAL_MINUTES в .env.
  static int get interstitialMinIntervalMinutes =>
      _int('INTERSTITIAL_MIN_INTERVAL_MINUTES', 6);

  /// Доп. минимальный интервал (минуты) для триггеров Restart (Game over / You won).
  /// См. INTERSTITIAL_RESTART_MIN_INTERVAL_MINUTES в .env.
  static int get interstitialRestartMinIntervalMinutes =>
      _int('INTERSTITIAL_RESTART_MIN_INTERVAL_MINUTES', 3);

  /// Показывать interstitial каждое N-е нажатие «Продолжить» (Continue).
  /// См. INTERSTITIAL_EVERY_NTH_CONTINUE в .env.
  static int get interstitialEveryNthContinue =>
      _int('INTERSTITIAL_EVERY_NTH_CONTINUE', 2);

  /// Каждое N-е нажатие на сложность в блоке «Start new game» на главной.
  /// См. INTERSTITIAL_EVERY_NTH_START_NEW_GAME в .env.
  static int get interstitialEveryNthStartNewGame =>
      _int('INTERSTITIAL_EVERY_NTH_START_NEW_GAME', 2);

  /// Каждое N-е нажатие «New game» в шапке экрана игры.
  /// См. INTERSTITIAL_EVERY_NTH_NEW_GAME_IN_HEADER в .env.
  static int get interstitialEveryNthNewGameInHeader =>
      _int('INTERSTITIAL_EVERY_NTH_NEW_GAME_IN_HEADER', 2);

  /// Каждый N-й выход в меню (кнопка «Назад», «Back to menu» в Game over / You won).
  /// См. INTERSTITIAL_EVERY_NTH_BACK_TO_MENU в .env.
  static int get interstitialEveryNthBackToMenu =>
      _int('INTERSTITIAL_EVERY_NTH_BACK_TO_MENU', 2);

  /// Каждое N-е нажатие по переключателю Notes.
  /// См. INTERSTITIAL_EVERY_NTH_NOTES в .env.
  static int get interstitialEveryNthNotes =>
      _int('INTERSTITIAL_EVERY_NTH_NOTES', 3);

  // --- App Open (реклама при открытии приложения) ---

  /// Минимальное время (секунды) в фоне, чтобы возврат в приложение считался «открытием».
  /// См. APP_OPEN_RESUME_MIN_BACKGROUND_SECONDS в .env.
  static int get appOpenResumeMinBackgroundSeconds =>
      _int('APP_OPEN_RESUME_MIN_BACKGROUND_SECONDS', 60);

  /// Показывать app open каждое N-е возвращение из фона (resume).
  /// См. APP_OPEN_EVERY_NTH_RESUME в .env.
  static int get appOpenEveryNthResume =>
      _int('APP_OPEN_EVERY_NTH_RESUME', 3);

  /// Показывать app open каждое N-е полное открытие приложения (cold start).
  /// См. APP_OPEN_EVERY_NTH_COLD_START в .env.
  static int get appOpenEveryNthColdStart =>
      _int('APP_OPEN_EVERY_NTH_COLD_START', 3);
}
