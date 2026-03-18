import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Persists current game and statistics using Hive.
class GameStorage {
  GameStorage._();
  static const _boxName = 'sudoku_game';
  static const _keySavedGame = 'saved_game';
  static const _keyStats = 'stats';
  static const _keyThemeMode = 'theme_mode';

  static Box? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
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

  // --- Activity dates (for streak & calendar) ---

  static const _keyActivityDates = 'activity_dates';
  static const _maxActivityDates = 365;

  /// Normalizes [date] to local calendar date (yyyy-MM-dd).
  static String _dateToKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Records that the user was active (e.g. won a puzzle) on [date]. Uses local date. Keeps only last [_maxActivityDates] days.
  static Future<void> saveActivityDate(DateTime date) async {
    final key = _dateToKey(date);
    final list = List<String>.from(loadActivityDates());
    if (list.contains(key)) return;
    list.add(key);
    list.sort();
    final trimmed = list.length > _maxActivityDates ? list.sublist(list.length - _maxActivityDates) : list;
    await box.put(_keyActivityDates, jsonEncode(trimmed));
  }

  /// Returns list of activity date strings (yyyy-MM-dd), sorted. Empty if none.
  static List<String> loadActivityDates() {
    final raw = box.get(_keyActivityDates);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw.toString()) as List;
      return list.map((e) => e.toString()).where((s) => s.length == 10).toList()..sort();
    } catch (_) {
      return [];
    }
  }

  /// Clears all activity dates (e.g. when user resets statistics).
  static Future<void> clearActivityDates() async {
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
