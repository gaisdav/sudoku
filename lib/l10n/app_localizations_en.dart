// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sudoku';

  @override
  String get menu => 'Menu';

  @override
  String get backToMenu => 'Back to menu';

  @override
  String get game => 'Game';

  @override
  String get newGame => 'New game';

  @override
  String get statistics => 'Statistics';

  @override
  String get viewStatistics => 'View statistics';

  @override
  String get settings => 'Settings';

  @override
  String get tabHome => 'Home';

  @override
  String get tabInstructions => 'Instructions';

  @override
  String get levelEasy => 'Easy';

  @override
  String get levelMedium => 'Medium';

  @override
  String get levelHard => 'Hard';

  @override
  String get levelExpert => 'Expert';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get accentColor => 'Accent color';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationSubtitle =>
      'Haptic feedback when tapping cells and buttons';

  @override
  String get continueGame => 'Continue';

  @override
  String savedTodayAt(String time) {
    return 'Saved today at $time';
  }

  @override
  String savedYesterdayAt(String time) {
    return 'Saved yesterday at $time';
  }

  @override
  String savedOn(String date) {
    return 'Saved $date';
  }

  @override
  String get youWon => 'You won!';

  @override
  String get congratulations => 'Congratulations, you completed the puzzle.';

  @override
  String timeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String hintsUsedLabel(int count) {
    return 'Hints used: $count';
  }

  @override
  String get newRecord => 'New record!';

  @override
  String slowerThanBest(String duration) {
    return '$duration slower than your best';
  }

  @override
  String get loadingAd => 'Loading ad…';

  @override
  String get noErrorsMode => 'No errors mode';

  @override
  String get noErrorsModeAlreadyOn =>
      'No errors mode is already on for this session. Wrong cells are highlighted in red but the game will not end from too many errors.';

  @override
  String get noErrorsModeDescription =>
      'In this mode wrong cells are highlighted in red but the game will not end from too many errors.\n\nTo enable it for this session, watch 3 ads in a row. The timer is paused.';

  @override
  String get watch3Ads => 'Watch 3 ads';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String adProgress(int current) {
    return 'Ad $current/3…';
  }

  @override
  String get gameOver => 'Game over';

  @override
  String get gameOverDescription =>
      'You have exceeded the allowed number of errors for this difficulty.';

  @override
  String get adNotAvailableSecondChance =>
      'Ad not available. Second chance applied.';

  @override
  String get secondChanceAd => 'Second chance (Ad)';

  @override
  String get restart => 'Restart';

  @override
  String get noErrors => 'No errors';

  @override
  String get undo => 'Undo';

  @override
  String get notes => 'Notes';

  @override
  String get hint => 'Hint';

  @override
  String get adBadge => 'Ad';

  @override
  String get adNotAvailableHintApplied => 'Ad not available. Hint applied.';

  @override
  String get adNotAvailableUndoApplied => 'Ad not available. Undo applied.';

  @override
  String get chooseDifficulty => 'Choose difficulty:';

  @override
  String totalWinsWithCount(int count) {
    return 'Total wins: $count';
  }

  @override
  String get bestTimeByDifficulty => 'Best time by difficulty:';

  @override
  String bestTimeLine(String level, String time, int hints) {
    return '$level: $time ($hints hints)';
  }

  @override
  String bestTimeLineNoRecord(String level) {
    return '$level: —';
  }

  @override
  String get resetStatisticsConfirmTitle => 'Reset statistics?';

  @override
  String get resetStatisticsConfirmMessage =>
      'All wins and best times will be cleared. This cannot be undone.';

  @override
  String get reset => 'Reset';

  @override
  String get resetStatistics => 'Reset statistics';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get followSystem => 'Follow system';
}
