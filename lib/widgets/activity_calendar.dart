import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays one month in a 7×7 grid (weekday headers + up to 6 rows of days).
/// Highlights [activityDates] (yyyy-MM-dd) and today.
class ActivityCalendarWidget extends StatelessWidget {
  const ActivityCalendarWidget({
    super.key,
    required this.displayMonth,
    required this.activityDates,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.locale,
  });

  /// First day of the month to show.
  final DateTime displayMonth;
  /// Set of date strings "yyyy-MM-dd" when user had activity.
  final Set<String> activityDates;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final String? locale;

  static String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = this.locale ?? Localizations.localeOf(context).toString();
    final monthYear = DateFormat.yMMM(locale).format(displayMonth);
    final weekdayFormat = DateFormat.E(locale);
    final firstWeekday = displayMonth.weekday; // 1 = Monday, 7 = Sunday
    final daysInMonth = DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);
    final firstDayOffset = firstWeekday - 1; // 0..6
    final totalCells = firstDayOffset + daysInMonth;
    final rows = (totalCells / 7).ceil().clamp(1, 6);

    final weekdays = List.generate(7, (i) {
      final d = DateTime(2000, 1, 3 + i); // Mon=3, Tue=4, ...
      return weekdayFormat.format(d);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
            ),
            Text(
              monthYear,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              children: weekdays.map((label) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )).toList(),
            ),
            ...List.generate(rows, (rowIndex) {
              return TableRow(
                children: List.generate(7, (colIndex) {
                  final cellIndex = rowIndex * 7 + colIndex;
                  final dayNumber = cellIndex - firstDayOffset + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(height: 36);
                  }
                  final date = DateTime(displayMonth.year, displayMonth.month, dayNumber);
                  final key = _dateKey(date);
                  final isActive = activityDates.contains(key);
                  final now = DateTime.now();
                  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                  return _DayCell(
                    day: dayNumber,
                    isActive: isActive,
                    isToday: isToday,
                    colorScheme: colorScheme,
                    textTheme: theme.textTheme,
                  );
                }),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.colorScheme,
    required this.textTheme,
  });

  final int day;
  final bool isActive;
  final bool isToday;
  final ColorScheme colorScheme;
  final TextTheme? textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : null,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: (textTheme?.bodyMedium ?? const TextStyle()).copyWith(
              color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
