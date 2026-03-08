import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../services/game_storage.dart';
import '../widgets/stats_dialog.dart';
import 'game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _openNewGameAndRefreshOnReturn(Level level) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(newGameLevel: level),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedGame = GameStorage.loadGame() != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // Continue last game
            _SectionCard(
              title: 'Continue last game',
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  onPressed: hasSavedGame
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GameScreen(continueLast: true),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continue'),
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
                  onPressed: () => showStatsDialog(context),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View statistics'),
                ),
              ),
            ),
          ],
        ),
      ),
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
