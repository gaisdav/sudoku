import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/activity_streak_provider.dart';
import '../widgets/activity_calendar.dart';

/// Full-screen "Progress" / Activity calendar: which days had at least one solved puzzle.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progress),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Text(
              l10n.activityCalendar,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ActivityCalendarWidget(
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
            ),
          ],
        ),
      ),
    );
  }
}
