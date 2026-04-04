import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_storage.dart';

/// Version bump to invalidate activity-dependent providers when a new activity date is saved.
final activityDatesVersionProvider = StateProvider<int>((ref) => 0);

/// List of activity date strings (yyyy-MM-dd), sorted — days with at least one in-game move. Calendar + streak.
final activityDatesProvider = Provider<List<String>>((ref) {
  ref.watch(activityDatesVersionProvider);
  return GameStorage.loadActivityDates();
});

/// Current streak: consecutive days up to today or yesterday. 0 if last activity was before yesterday.
final currentStreakProvider = Provider<int>((ref) {
  final dates = ref.watch(activityDatesProvider);
  return _computeCurrentStreak(dates);
});

/// Best streak ever: maximum number of consecutive days in activity history.
final bestStreakProvider = Provider<int>((ref) {
  final dates = ref.watch(activityDatesProvider);
  return _computeBestStreak(dates);
});

/// Today's date string in local time (yyyy-MM-dd).
String _todayKey() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

/// Yesterday's date string in local time.
String _yesterdayKey() {
  final y = DateTime.now().subtract(const Duration(days: 1));
  return '${y.year.toString().padLeft(4, '0')}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
}

/// Parses "yyyy-MM-dd" to DateTime at noon local (for day arithmetic).
DateTime _parseDate(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return DateTime(2000, 1, 1);
  final y = int.tryParse(parts[0]) ?? 2000;
  final m = int.tryParse(parts[1]) ?? 1;
  final d = int.tryParse(parts[2]) ?? 1;
  return DateTime(y, m, d);
}

/// True if [a] and [b] are exactly one day apart (a is day before b).
bool _isConsecutiveDay(String a, String b) {
  final da = _parseDate(a);
  final db = _parseDate(b);
  return db.difference(da).inDays == 1;
}

/// Current streak: last active day must be today or yesterday; then count consecutive days backward.
int _computeCurrentStreak(List<String> dates) {
  if (dates.isEmpty) return 0;
  final today = _todayKey();
  final yesterday = _yesterdayKey();
  final last = dates.last;
  if (last != today && last != yesterday) return 0;
  int count = 1;
  int i = dates.length - 1;
  while (i > 0 && _isConsecutiveDay(dates[i - 1], dates[i])) {
    count++;
    i--;
  }
  return count;
}

/// Best streak: longest run of consecutive days in [dates].
int _computeBestStreak(List<String> dates) {
  if (dates.isEmpty) return 0;
  int best = 1;
  int current = 1;
  for (int i = 1; i < dates.length; i++) {
    if (_isConsecutiveDay(dates[i - 1], dates[i])) {
      current++;
    } else {
      if (current > best) best = current;
      current = 1;
    }
  }
  if (current > best) best = current;
  return best;
}
