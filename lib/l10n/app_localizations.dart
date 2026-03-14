import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sudoku'**
  String get appTitle;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to menu'**
  String get backToMenu;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @viewStatistics.
  ///
  /// In en, this message translates to:
  /// **'View statistics'**
  String get viewStatistics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get tabInstructions;

  /// No description provided for @instructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play Sudoku'**
  String get instructionsTitle;

  /// No description provided for @instructionsBody.
  ///
  /// In en, this message translates to:
  /// **'Sudoku is played on a 9×9 grid divided into nine 3×3 boxes.\n\nGoal: Fill the grid so that every row, every column, and every 3×3 box contains the digits 1 through 9, with no repeats.\n\nRules:\n• Each row must contain 1–9 exactly once.\n• Each column must contain 1–9 exactly once.\n• Each 3×3 box must contain 1–9 exactly once.\n\nSome cells are already filled; the rest you fill in using logic. There is only one correct solution for each puzzle.'**
  String get instructionsBody;

  /// No description provided for @levelEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get levelEasy;

  /// No description provided for @levelMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get levelMedium;

  /// No description provided for @levelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get levelHard;

  /// No description provided for @levelExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get levelExpert;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback when tapping cells and buttons'**
  String get vibrationSubtitle;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @savedTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Saved today at {time}'**
  String savedTodayAt(String time);

  /// No description provided for @savedYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Saved yesterday at {time}'**
  String savedYesterdayAt(String time);

  /// No description provided for @savedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved {date}'**
  String savedOn(String date);

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get youWon;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, you completed the puzzle.'**
  String get congratulations;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String timeLabel(String time);

  /// No description provided for @hintsUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Hints used: {count}'**
  String hintsUsedLabel(int count);

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New record!'**
  String get newRecord;

  /// No description provided for @slowerThanBest.
  ///
  /// In en, this message translates to:
  /// **'{duration} slower than your best'**
  String slowerThanBest(String duration);

  /// No description provided for @loadingAd.
  ///
  /// In en, this message translates to:
  /// **'Loading ad…'**
  String get loadingAd;

  /// No description provided for @noErrorsMode.
  ///
  /// In en, this message translates to:
  /// **'No errors mode'**
  String get noErrorsMode;

  /// No description provided for @noErrorsModeAlreadyOn.
  ///
  /// In en, this message translates to:
  /// **'No errors mode is already on for this session. Wrong cells are highlighted in red but the game will not end from too many errors.'**
  String get noErrorsModeAlreadyOn;

  /// No description provided for @noErrorsModeDescription.
  ///
  /// In en, this message translates to:
  /// **'In this mode wrong cells are highlighted in red but the game will not end from too many errors.\n\nTo enable it for this session, watch 3 ads in a row. The timer is paused.'**
  String get noErrorsModeDescription;

  /// No description provided for @watch3Ads.
  ///
  /// In en, this message translates to:
  /// **'Watch 3 ads'**
  String get watch3Ads;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @adProgress.
  ///
  /// In en, this message translates to:
  /// **'Ad {current}/3…'**
  String adProgress(int current);

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOver;

  /// No description provided for @gameOverDescription.
  ///
  /// In en, this message translates to:
  /// **'You have exceeded the allowed number of errors for this difficulty.'**
  String get gameOverDescription;

  /// No description provided for @adNotAvailableSecondChance.
  ///
  /// In en, this message translates to:
  /// **'Ad not available. Second chance applied.'**
  String get adNotAvailableSecondChance;

  /// No description provided for @secondChanceAd.
  ///
  /// In en, this message translates to:
  /// **'Second chance (Ad)'**
  String get secondChanceAd;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @noErrors.
  ///
  /// In en, this message translates to:
  /// **'No errors'**
  String get noErrors;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @adBadge.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adBadge;

  /// No description provided for @adNotAvailableHintApplied.
  ///
  /// In en, this message translates to:
  /// **'Ad not available. Hint applied.'**
  String get adNotAvailableHintApplied;

  /// No description provided for @adNotAvailableUndoApplied.
  ///
  /// In en, this message translates to:
  /// **'Ad not available. Undo applied.'**
  String get adNotAvailableUndoApplied;

  /// No description provided for @chooseDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Choose difficulty:'**
  String get chooseDifficulty;

  /// No description provided for @totalWinsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Total wins: {count}'**
  String totalWinsWithCount(int count);

  /// No description provided for @bestTimeByDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Best time by difficulty:'**
  String get bestTimeByDifficulty;

  /// No description provided for @bestTimeLine.
  ///
  /// In en, this message translates to:
  /// **'{level}: {time} ({hints} hints)'**
  String bestTimeLine(String level, String time, int hints);

  /// No description provided for @bestTimeLineNoRecord.
  ///
  /// In en, this message translates to:
  /// **'{level}: —'**
  String bestTimeLineNoRecord(String level);

  /// No description provided for @resetStatisticsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset statistics?'**
  String get resetStatisticsConfirmTitle;

  /// No description provided for @resetStatisticsConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All wins and best times will be cleared. This cannot be undone.'**
  String get resetStatisticsConfirmMessage;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Reset statistics'**
  String get resetStatistics;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
