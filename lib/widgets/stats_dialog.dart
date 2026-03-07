import 'package:flutter/material.dart';

import '../services/game_storage.dart';

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

void showStatsDialog(BuildContext context) {
  final totalWins = GameStorage.loadTotalWins();
  final bestByLevel = GameStorage.loadBestTimeByLevel();
  final bestHintsByLevel = GameStorage.loadBestTimeHintsByLevel();
  const levelNames = ['Easy', 'Medium', 'Hard', 'Expert'];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
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
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
