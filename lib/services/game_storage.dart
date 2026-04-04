import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Per-day result for the activity calendar. If a day has at least one win, it is stored as [win] even if the user lost later.
enum CalendarDayOutcome {
  /// At least one move, no finished win/loss recorded for that day yet, or only abandoned games after a loss.
  played,
  loss,
  win,
}

/// Persists current game and statistics using Hive.
class GameStorage {
  GameStorage._();
  static const _boxName = 'sudoku_game';
  static const _keySavedGame = 'saved_game';
  static const _keyTimedGame = 'saved_timed_game';
  static const _keyStats = 'stats';
  static const _keyThemeMode = 'theme_mode';

  static Box? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    await _purgeRemovedDailyChallengeKeys();
    await _ensureActivityCalendarMigratedAsync();
  }

  /// One-time cleanup after removing the daily challenge feature (legacy Hive keys).
  static Future<void> _purgeRemovedDailyChallengeKeys() async {
    final b = _box;
    if (b == null) return;
    await b.delete('saved_daily_game');
    await b.delete('daily_challenge_level_index');
    await b.delete('daily_completed_date');
    for (final k in b.keys.toList()) {
      if (k.toString().startsWith('daily_puzzle_')) {
        await b.delete(k);
      }
    }
  }

  static Box get box {
    final b = _box;
    if (b == null) throw StateError('GameStorage not initialized. Call init() first.');
    return b;
  }

  // --- Saved game (current puzzle in progress) ---

  static const String keyDifficulty = 'difficulty';
  static const String keyCellValues = 'cellValues';
  static const String keyCellIsOriginal = 'cellIsOriginal';
  static const String keySolution = 'solution';
  static const String keyElapsedSeconds = 'elapsedSeconds';
  static const String keyHintsUsedThisGame = 'hintsUsedThisGame';
  static const String keyErrorsMade = 'errorsMade';
  static const String keyIsNotesMode = 'isNotesMode';
  static const String keyCellNotes = 'cellNotes';

  /// Saves current game. Pass null to clear.
  static Future<void> saveGame(Map<String, dynamic>? data) async {
    if (data == null) {
      await box.delete(_keySavedGame);
      return;
    }
    await box.put(_keySavedGame, jsonEncode(data));
  }

  /// Returns saved game map or null.
  static Map<String, dynamic>? loadGame() {
    final raw = box.get(_keySavedGame);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw.toString()) as Map);
    } catch (_) {
      return null;
    }
  }

  static const String keyTimedRemaining = 'timedRemaining';
  static const String keyTimedInitialLimit = 'timedInitialLimit';
  static const String keyTimedBonusSeconds = 'timedBonusSeconds';
  static const String keyTimedWarned30 = 'timedWarned30';

  static Future<void> saveTimedGame(Map<String, dynamic>? data) async {
    if (data == null) {
      await box.delete(_keyTimedGame);
      return;
    }
    await box.put(_keyTimedGame, jsonEncode(data));
  }

  static Map<String, dynamic>? loadTimedGame() {
    final raw = box.get(_keyTimedGame);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw.toString()) as Map);
    } catch (_) {
      return null;
    }
  }

  // --- Statistics ---

  static const String keyTotalWins = 'totalWins';
  static const String keyBestTimeByLevel = 'bestTimeByLevel';
  static const String keyBestTimeHintsByLevel = 'bestTimeHintsByLevel';

  /// Saves statistics. [bestTimeHintsByLevel] = hints used when that best time was set.
  static Future<void> saveStats({
    required int totalWins,
    required Map<int, int> bestTimeByLevel,
    required Map<int, int> bestTimeHintsByLevel,
  }) async {
    final data = {
      keyTotalWins: totalWins,
      keyBestTimeByLevel: bestTimeByLevel.map((k, v) => MapEntry(k.toString(), v)),
      keyBestTimeHintsByLevel:
          bestTimeHintsByLevel.map((k, v) => MapEntry(k.toString(), v)),
    };
    await box.put(_keyStats, jsonEncode(data));
  }

  static int loadTotalWins() {
    final raw = box.get(_keyStats);
    if (raw == null) return 0;
    try {
      final map = jsonDecode(raw.toString()) as Map;
      return (map[keyTotalWins] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Level index -> hints used when best time was set (for display next to best time).
  static Map<int, int> loadBestTimeHintsByLevel() {
    final raw = box.get(_keyStats);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw.toString()) as Map;
      final byLevel = map[keyBestTimeHintsByLevel];
      if (byLevel is! Map) return {};
      return byLevel.map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Level index -> best time in seconds.
  static Map<int, int> loadBestTimeByLevel() {
    final raw = box.get(_keyStats);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw.toString()) as Map;
      final byLevel = map[keyBestTimeByLevel];
      if (byLevel is! Map) return {};
      return byLevel.map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // --- Settings (theme, etc.) ---

  static const String valueThemeDark = 'dark';
  static const String valueThemeLight = 'light';
  static const String valueThemeSystem = 'system';

  /// Saves theme mode. [value] must be [valueThemeDark], [valueThemeLight] or [valueThemeSystem].
  static Future<void> saveThemeMode(String value) async {
    await box.put(_keyThemeMode, value);
  }

  /// Returns saved theme. Default: [valueThemeDark].
  static String loadThemeMode() {
    final raw = box.get(_keyThemeMode);
    if (raw == null) return valueThemeDark;
    final s = raw.toString();
    if (s == valueThemeLight) return valueThemeLight;
    if (s == valueThemeSystem) return valueThemeSystem;
    return valueThemeDark;
  }

  static const _keyAccentIndex = 'accent_index';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyLocale = 'locale';

  /// Saves app locale override. Pass empty string or null for system default.
  static Future<void> saveLocale(String? languageCode) async {
    if (languageCode == null || languageCode.isEmpty) {
      await box.delete(_keyLocale);
    } else {
      await box.put(_keyLocale, languageCode);
    }
  }

  /// Returns saved locale language code, or null for system default.
  static String? loadLocale() {
    final raw = box.get(_keyLocale);
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Saves whether haptic/vibration feedback is enabled. Default true.
  static Future<void> saveVibrationEnabled(bool enabled) async {
    await box.put(_keyVibrationEnabled, enabled);
  }

  /// Returns whether vibration is enabled. Default true.
  static bool loadVibrationEnabled() {
    final raw = box.get(_keyVibrationEnabled);
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is String) return raw != 'false';
    return true;
  }

  /// Key for saved game timestamp (ISO 8601 string). Optional in saved game map.
  static const String keySavedAt = 'savedAt';

  /// Resets all statistics to zero. Does not clear saved game. Also clears activity dates and streak data.
  static Future<void> resetStats() async {
    await saveStats(
      totalWins: 0,
      bestTimeByLevel: {},
      bestTimeHintsByLevel: {},
    );
    await clearActivityDates();
  }

  // --- Activity calendar (streak + per-day outcome) ---

  static const _keyActivityDates = 'activity_dates'; // legacy; migrated into [_keyActivityCalendar]
  static const _keyActivityCalendar = 'activity_calendar';
  static const _maxActivityDates = 365;

  /// Normalizes [date] to local calendar date (yyyy-MM-dd).
  static String _dateToKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static CalendarDayOutcome? _parseOutcome(String raw) {
    switch (raw) {
      case 'win':
        return CalendarDayOutcome.win;
      case 'loss':
        return CalendarDayOutcome.loss;
      case 'played':
        return CalendarDayOutcome.played;
      default:
        return null;
    }
  }

  /// Merges [incoming] with the previous stored outcome for the same calendar day.
  static String? _mergeStoredOutcome(String? previous, CalendarDayOutcome incoming) {
    switch (incoming) {
      case CalendarDayOutcome.win:
        return 'win';
      case CalendarDayOutcome.loss:
        if (previous == 'win') return 'win';
        return 'loss';
      case CalendarDayOutcome.played:
        if (previous == null) return 'played';
        return previous;
    }
  }

  static Map<String, String> _loadCalendarRawMap() {
    final raw = box.get(_keyActivityCalendar);
    if (raw == null) return {};
    try {
      final m = Map<String, dynamic>.from(jsonDecode(raw.toString()) as Map);
      final out = <String, String>{};
      for (final e in m.entries) {
        final k = e.key.toString();
        if (k.length != 10) continue;
        final v = e.value.toString();
        if (_parseOutcome(v) == null) continue;
        out[k] = v;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static void _trimCalendarMap(Map<String, String> map) {
    if (map.length <= _maxActivityDates) return;
    final keys = map.keys.toList()..sort();
    final drop = keys.length - _maxActivityDates;
    for (int i = 0; i < drop; i++) {
      map.remove(keys[i]);
    }
  }

  static Future<void> _ensureActivityCalendarMigratedAsync() async {
    if (box.get(_keyActivityCalendar) != null) return;
    final fromLegacy = <String, String>{};
    final raw = box.get(_keyActivityDates);
    if (raw != null) {
      try {
        final list = jsonDecode(raw.toString()) as List;
        for (final e in list) {
          final s = e.toString();
          if (s.length == 10) fromLegacy[s] = 'played';
        }
      } catch (_) {}
    }
    await box.put(_keyActivityCalendar, jsonEncode(fromLegacy));
    await box.delete(_keyActivityDates);
  }

  /// Outcome per local calendar day. Legacy [activity_dates] list is treated as [played] until migrated.
  static Map<String, CalendarDayOutcome> loadCalendarDayOutcomes() {
    final rawMap = _loadCalendarRawMap();
    if (rawMap.isNotEmpty) {
      final out = <String, CalendarDayOutcome>{};
      for (final e in rawMap.entries) {
        final o = _parseOutcome(e.value);
        if (o != null) out[e.key] = o;
      }
      return out;
    }
    final legacy = box.get(_keyActivityDates);
    if (legacy == null) return {};
    try {
      final list = jsonDecode(legacy.toString()) as List;
      final out = <String, CalendarDayOutcome>{};
      for (final e in list) {
        final s = e.toString();
        if (s.length == 10) out[s] = CalendarDayOutcome.played;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Updates stored outcome for [date] using merge rules (win beats everything; loss beats played; played only fills empty days).
  /// Returns true if persisted data changed.
  static Future<bool> recordCalendarDay(DateTime date, CalendarDayOutcome outcome) async {
    await _ensureActivityCalendarMigratedAsync();
    final key = _dateToKey(date);
    final map = _loadCalendarRawMap();
    final merged = _mergeStoredOutcome(map[key], outcome);
    if (merged == null) return false;
    if (map[key] == merged) return false;
    map[key] = merged;
    _trimCalendarMap(map);
    await box.put(_keyActivityCalendar, jsonEncode(map));
    return true;
  }

  /// Whether today's local calendar date is already in the activity list (played / had a move today).
  static bool hasActivityToday() {
    return loadCalendarDayOutcomes().containsKey(_dateToKey(DateTime.now()));
  }

  /// Sorted date keys (yyyy-MM-dd) with any recorded activity — for streaks.
  static List<String> loadActivityDates() {
    final keys = loadCalendarDayOutcomes().keys.toList()..sort();
    return keys;
  }

  /// Clears all activity dates (e.g. when user resets statistics).
  static Future<void> clearActivityDates() async {
    await box.delete(_keyActivityCalendar);
    await box.delete(_keyActivityDates);
  }

  // --- Reminder (for этап 2a: push notifications) ---

  static const _keyReminderEnabled = 'reminder_enabled';
  static const _keyReminderTime = 'reminder_time'; // "HH:mm"
  static const _keyReminderText = 'reminder_text';

  static Future<void> saveReminderEnabled(bool enabled) async {
    await box.put(_keyReminderEnabled, enabled);
  }

  static bool loadReminderEnabled() {
    final raw = box.get(_keyReminderEnabled);
    if (raw == null) return false;
    if (raw is bool) return raw;
    return raw.toString() == 'true';
  }

  /// Saves reminder time as "HH:mm" (e.g. "19:00").
  static Future<void> saveReminderTime(String timeHHmm) async {
    await box.put(_keyReminderTime, timeHHmm);
  }

  /// Returns reminder time "HH:mm". Default "19:00".
  static String loadReminderTime() {
    final raw = box.get(_keyReminderTime);
    if (raw == null) return '19:00';
    final s = raw.toString().trim();
    if (s.length == 5 && s[2] == ':') return s;
    return '19:00';
  }

  static Future<void> saveReminderText(String text) async {
    await box.put(_keyReminderText, text);
  }

  static String loadReminderText() {
    final raw = box.get(_keyReminderText);
    if (raw == null) return '';
    return raw.toString();
  }

  /// Saves accent color index (0-based). Default 0 = blue.
  static Future<void> saveAccentIndex(int index) async {
    await box.put(_keyAccentIndex, index);
  }

  /// Returns saved accent index. Default 0.
  static int loadAccentIndex() {
    final raw = box.get(_keyAccentIndex);
    if (raw == null) return 0;
    return (raw is num) ? raw.toInt().clamp(0, 99) : 0;
  }
}
