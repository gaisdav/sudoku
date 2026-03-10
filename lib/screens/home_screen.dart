import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../services/game_storage.dart';
import '../services/interstitial_ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/stats_dialog.dart' show formatDuration, showStatsDialog;
import 'game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _openNewGameAndRefreshOnReturn(Level level) {
    InterstitialAdService.tryShowInterstitial(
      context,
      InterstitialTrigger.startNewGame,
      onDone: () {
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GameScreen(newGameLevel: level),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedGame = GameStorage.loadGame() != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
            // Continue last game
            _SectionCard(
              title: 'Continue last game',
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ContinueRow(
                  hasSavedGame: hasSavedGame,
                  onContinue: () {
                    InterstitialAdService.tryShowInterstitial(
                      context,
                      InterstitialTrigger.continueGame,
                      onDone: () {
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const GameScreen(continueLast: true),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // New game
            _SectionCard(
              title: 'Start new game',
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DifficultyChip(
                      label: 'Easy',
                      onTap: () => _openNewGameAndRefreshOnReturn(Level.easy),
                    ),
                    _DifficultyChip(
                      label: 'Medium',
                      onTap: () => _openNewGameAndRefreshOnReturn(Level.medium),
                    ),
                    _DifficultyChip(
                      label: 'Hard',
                      onTap: () => _openNewGameAndRefreshOnReturn(Level.hard),
                    ),
                    _DifficultyChip(
                      label: 'Expert',
                      onTap: () => _openNewGameAndRefreshOnReturn(Level.expert),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics
            _SectionCard(
              title: 'Statistics',
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    InterstitialAdService.tryShowInterstitial(
                      context,
                      InterstitialTrigger.viewStatistics,
                      onDone: () => showStatsDialog(context),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View statistics'),
                ),
              ),
            ),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

}

const List<String> _levelLabels = ['Easy', 'Medium', 'Hard', 'Expert'];

class _ContinueRow extends StatelessWidget {
  const _ContinueRow({
    required this.hasSavedGame,
    required this.onContinue,
  });

  final bool hasSavedGame;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final saved = hasSavedGame ? GameStorage.loadGame() : null;
    final difficultyIndex = (saved?[GameStorage.keyDifficulty] as num?)?.toInt() ?? 0;
    final levelLabel = _levelLabels[difficultyIndex.clamp(0, _levelLabels.length - 1)];
    final elapsedSeconds = (saved?[GameStorage.keyElapsedSeconds] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        FilledButton.icon(
          onPressed: hasSavedGame ? onContinue : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Continue'),
        ),
        if (hasSavedGame) ...[
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  levelLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDuration(elapsedSeconds),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}
