import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/activity_streak_provider.dart';
import '../services/game_storage.dart';
import '../services/streak_reminder_service.dart';

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

Future<void> applyStatsReset(WidgetRef ref) async {
  await GameStorage.resetStats();
  ref.read(activityDatesVersionProvider.notifier).state++;
  if (!kIsWeb) {
    unawaited(StreakReminderService.applyFromStorage(
      defaultTitle: StreakReminderService.defaultReminderTitleFallback,
      defaultBody: StreakReminderService.defaultReminderBodyFallback,
    ));
  }
}

/// Statistics numbers (total wins, best times). Optional inline reset for tab layout.
class StatsSummarySection extends ConsumerStatefulWidget {
  const StatsSummarySection({
    super.key,
    this.showInlineResetButton = true,
  });

  /// When `false`, reset is expected in dialog actions (see [showStatsDialog]).
  final bool showInlineResetButton;

  @override
  ConsumerState<StatsSummarySection> createState() => _StatsSummarySectionState();
}

class _StatsSummarySectionState extends ConsumerState<StatsSummarySection> {
  Future<void> _onResetPressed(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final l10nDialog = AppLocalizations.of(dialogCtx)!;
        return AlertDialog(
          title: Text(l10nDialog.resetStatisticsConfirmTitle),
          content: Text(l10nDialog.resetStatisticsConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10nDialog.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10nDialog.reset),
            ),
          ],
        );
      },
    );
    if (confirm != true || !context.mounted) return;
    await applyStatsReset(ref);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levelNames = [l10n.levelEasy, l10n.levelMedium, l10n.levelHard, l10n.levelExpert];
    final theme = Theme.of(context);
    final totalWins = GameStorage.loadTotalWins();
    final bestByLevel = GameStorage.loadBestTimeByLevel();
    final bestHintsByLevel = GameStorage.loadBestTimeHintsByLevel();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.totalWinsWithCount(totalWins), style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Text(l10n.bestTimeByDifficulty, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (var i = 0; i < levelNames.length; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              bestByLevel[i] != null
                  ? l10n.bestTimeLine(levelNames[i], formatDuration(bestByLevel[i]!), bestHintsByLevel[i] ?? 0)
                  : l10n.bestTimeLineNoRecord(levelNames[i]),
            ),
          ),
        ],
        if (widget.showInlineResetButton) ...[
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _onResetPressed(context),
              child: Text(l10n.resetStatistics),
            ),
          ),
        ],
      ],
    );
  }
}

/// Показывает диалог статистики. Возвращает Future, который завершается при закрытии диалога.
/// Pass [ref] so that after reset statistics the activity/streak providers are invalidated (for этап 1–2).
Future<void> showStatsDialog(BuildContext context, {WidgetRef? ref}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Consumer(
        builder: (context, consumerRef, _) {
          final effectiveRef = ref ?? consumerRef;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final l10nInner = AppLocalizations.of(context)!;
              return AlertDialog(
                title: Text(l10nInner.statistics),
                content: const SingleChildScrollView(
                  child: StatsSummarySection(
                    showInlineResetButton: false,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogCtx) {
                          final l10nDialog = AppLocalizations.of(dialogCtx)!;
                          return AlertDialog(
                            title: Text(l10nDialog.resetStatisticsConfirmTitle),
                            content: Text(l10nDialog.resetStatisticsConfirmMessage),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(false),
                                child: Text(l10nDialog.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(true),
                                child: Text(l10nDialog.reset),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirm == true && context.mounted) {
                        await applyStatsReset(effectiveRef);
                        setDialogState(() {});
                      }
                    },
                    child: Text(l10nInner.resetStatistics),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10nInner.ok),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
