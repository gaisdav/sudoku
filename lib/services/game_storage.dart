import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Persists current game and statistics using Hive.
class GameStorage {
  GameStorage._();
  static const _boxName = 'sudoku_game';
  static const _keySavedGame = 'saved_game';
  static const _keyStats = 'stats';

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
}
