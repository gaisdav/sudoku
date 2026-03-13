// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Судоку';

  @override
  String get menu => 'Меню';

  @override
  String get backToMenu => 'В меню';

  @override
  String get game => 'Игра';

  @override
  String get newGame => 'Новая игра';

  @override
  String get statistics => 'Статистика';

  @override
  String get viewStatistics => 'Смотреть статистику';

  @override
  String get settings => 'Настройки';

  @override
  String get levelEasy => 'Лёгкий';

  @override
  String get levelMedium => 'Средний';

  @override
  String get levelHard => 'Сложный';

  @override
  String get levelExpert => 'Эксперт';

  @override
  String get theme => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystem => 'Системная';

  @override
  String get accentColor => 'Акцентный цвет';

  @override
  String get language => 'Язык';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageSpanish => 'Испанский';

  @override
  String get vibration => 'Вибрация';

  @override
  String get vibrationSubtitle =>
      'Тактильный отклик при нажатии на ячейки и кнопки';

  @override
  String get continueGame => 'Продолжить';

  @override
  String savedTodayAt(String time) {
    return 'Сохранено сегодня в $time';
  }

  @override
  String savedYesterdayAt(String time) {
    return 'Сохранено вчера в $time';
  }

  @override
  String savedOn(String date) {
    return 'Сохранено $date';
  }

  @override
  String get youWon => 'Победа!';

  @override
  String get congratulations => 'Поздравляем, вы собрали головоломку.';

  @override
  String timeLabel(String time) {
    return 'Время: $time';
  }

  @override
  String hintsUsedLabel(int count) {
    return 'Подсказок использовано: $count';
  }

  @override
  String get newRecord => 'Новый рекорд!';

  @override
  String slowerThanBest(String duration) {
    return 'На $duration медленнее вашего лучшего';
  }

  @override
  String get loadingAd => 'Загрузка рекламы…';

  @override
  String get noErrorsMode => 'Режим без ошибок';

  @override
  String get noErrorsModeAlreadyOn =>
      'Режим без ошибок уже включён. Неверные ячейки подсвечиваются красным, но игра не завершится из-за лимита ошибок.';

  @override
  String get noErrorsModeDescription =>
      'В этом режиме неверные ячейки подсвечиваются красным, но игра не завершится из-за лимита ошибок.\n\nЧтобы включить на эту сессию, посмотрите 3 рекламы подряд. Таймер приостановлен.';

  @override
  String get watch3Ads => 'Смотреть 3 рекламы';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'OK';

  @override
  String adProgress(int current) {
    return 'Реклама $current/3…';
  }

  @override
  String get gameOver => 'Игра окончена';

  @override
  String get gameOverDescription =>
      'Превышено допустимое количество ошибок для этой сложности.';

  @override
  String get adNotAvailableSecondChance =>
      'Реклама недоступна. Второй шанс применён.';

  @override
  String get secondChanceAd => 'Второй шанс (реклама)';

  @override
  String get restart => 'Заново';

  @override
  String get noErrors => 'Без ошибок';

  @override
  String get undo => 'Отмена';

  @override
  String get notes => 'Заметки';

  @override
  String get hint => 'Подсказка';

  @override
  String get adBadge => 'Рекл.';

  @override
  String get adNotAvailableHintApplied =>
      'Реклама недоступна. Подсказка применена.';

  @override
  String get adNotAvailableUndoApplied =>
      'Реклама недоступна. Отмена хода применена.';

  @override
  String get chooseDifficulty => 'Выберите сложность:';

  @override
  String totalWinsWithCount(int count) {
    return 'Всего побед: $count';
  }

  @override
  String get bestTimeByDifficulty => 'Лучшее время по сложности:';

  @override
  String bestTimeLine(String level, String time, int hints) {
    return '$level: $time ($hints подсказок)';
  }

  @override
  String bestTimeLineNoRecord(String level) {
    return '$level: —';
  }

  @override
  String get resetStatisticsConfirmTitle => 'Сбросить статистику?';

  @override
  String get resetStatisticsConfirmMessage =>
      'Все победы и лучшие времена будут удалены. Это нельзя отменить.';

  @override
  String get reset => 'Сбросить';

  @override
  String get resetStatistics => 'Сбросить статистику';

  @override
  String get lightTheme => 'Светлая тема';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get followSystem => 'Как в системе';
}
