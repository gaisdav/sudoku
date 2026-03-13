import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/game_storage.dart';

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Показывает диалог статистики. Возвращает Future, который завершается при закрытии диалога.
Future<void> showStatsDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final levelNames = [l10n.levelEasy, l10n.levelMedium, l10n.levelHard, l10n.levelExpert];
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final totalWins = GameStorage.loadTotalWins();
      final bestByLevel = GameStorage.loadBestTimeByLevel();
      final bestHintsByLevel = GameStorage.loadBestTimeHintsByLevel();
      return StatefulBuilder(
        builder: (context, setState) {
          final l10nInner = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10nInner.statistics),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10nInner.totalWinsWithCount(totalWins), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(l10nInner.bestTimeByDifficulty, style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (var i = 0; i < levelNames.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        bestByLevel[i] != null
                            ? l10nInner.bestTimeLine(levelNames[i], formatDuration(bestByLevel[i]!), bestHintsByLevel[i] ?? 0)
                            : l10nInner.bestTimeLineNoRecord(levelNames[i]),
                      ),
                    ),
                  ],
                ],
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
                    await GameStorage.resetStats();
                    setState(() {});
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
}
