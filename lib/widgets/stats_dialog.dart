import 'package:flutter/material.dart';

import '../services/game_storage.dart';

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Показывает диалог статистики. Возвращает Future, который завершается при закрытии диалога.
Future<void> showStatsDialog(BuildContext context) {
  const levelNames = ['Easy', 'Medium', 'Hard', 'Expert'];
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final totalWins = GameStorage.loadTotalWins();
      final bestByLevel = GameStorage.loadBestTimeByLevel();
      final bestHintsByLevel = GameStorage.loadBestTimeHintsByLevel();
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Statistics'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total wins: $totalWins', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Best time by difficulty:', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (var i = 0; i < levelNames.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      bestByLevel[i] != null
                          ? '${levelNames[i]}: ${formatDuration(bestByLevel[i]!)}'
                              ' (${bestHintsByLevel[i] ?? 0} hints)'
                          : '${levelNames[i]}: —',
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
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Reset statistics?'),
                    content: const Text(
                      'All wins and best times will be cleared. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await GameStorage.resetStats();
                  setState(() {});
                }
              },
              child: const Text('Reset statistics'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    },
  );
}
