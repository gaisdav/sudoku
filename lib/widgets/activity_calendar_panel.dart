import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_streak_provider.dart';
import 'activity_calendar.dart';

/// Month navigation + [ActivityCalendarWidget] for embedding on a tab or full screen.
class ActivityCalendarPanel extends ConsumerStatefulWidget {
  const ActivityCalendarPanel({super.key});

  @override
  ConsumerState<ActivityCalendarPanel> createState() => _ActivityCalendarPanelState();
}

class _ActivityCalendarPanelState extends ConsumerState<ActivityCalendarPanel> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final activityDates = ref.watch(activityDatesProvider);
    final activitySet = activityDates.toSet();
    final locale = Localizations.localeOf(context).toString();

    return ActivityCalendarWidget(
      displayMonth: _displayMonth,
      activityDates: activitySet,
      locale: locale,
      onPreviousMonth: () {
        setState(() {
          _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
        });
      },
      onNextMonth: () {
        setState(() {
          _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
        });
      },
    );
  }
}
