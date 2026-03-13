import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../providers/accent_color_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/vibration_enabled_provider.dart';
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
            const SizedBox(height: 24),

            // Settings
            _SectionCard(
              title: 'Settings',
              child: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: _SettingsSection(),
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

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accentIndex = ref.watch(accentIndexProvider);
    final notifierTheme = ref.read(themeModeProvider.notifier);
    final notifierAccent = ref.read(accentIndexProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            textStyle: Theme.of(context).textTheme.labelSmall,
            visualDensity: VisualDensity.compact,
          ),
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode, size: 16)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode, size: 16)),
            ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto, size: 16)),
          ],
          selected: {themeMode},
          onSelectionChanged: (Set<ThemeMode> selected) {
            notifierTheme.setThemeMode(selected.first);
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Accent color',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const count = 6;
            const minSize = 24.0;
            const maxSize = 36.0;
            const minGap = 4.0;
            const maxGap = 10.0;
            final width = constraints.maxWidth;
            final size = ((width - (count - 1) * minGap) / count).clamp(minSize, maxSize);
            final gap = width > count * maxSize + (count - 1) * maxGap
                ? maxGap
                : ((width - count * size) / (count - 1)).clamp(minGap, maxGap);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(accentColorOptions.length, (i) {
                final selected = i == accentIndex;
                return GestureDetector(
                  onTap: () => notifierAccent.setAccentIndex(i),
                  child: Container(
                    width: size,
                    height: size,
                    margin: EdgeInsets.only(right: i < accentColorOptions.length - 1 ? gap : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColorOptions[i],
                      border: Border.all(
                        color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (selected)
                          BoxShadow(
                            color: accentColorOptions[i].withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Vibration'),
          subtitle: const Text('Haptic feedback when tapping cells and buttons'),
          value: ref.watch(vibrationEnabledProvider),
          onChanged: (value) {
            ref.read(vibrationEnabledProvider.notifier).setEnabled(value);
          },
        ),
      ],
    );
  }
}

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
    final savedAtRaw = saved?[GameStorage.keySavedAt] as String?;
    DateTime? savedAt;
    if (savedAtRaw != null && savedAtRaw.isNotEmpty) {
      savedAt = DateTime.tryParse(savedAtRaw);
    }

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
                if (savedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatSavedAt(savedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _formatSavedAt(DateTime savedAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final savedDay = DateTime(savedAt.year, savedAt.month, savedAt.day);
    if (savedDay == today) {
      return 'Saved today at ${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (savedDay == yesterday) {
      return 'Saved yesterday at ${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')}';
    }
    return 'Saved ${savedAt.day.toString().padLeft(2, '0')}.${savedAt.month.toString().padLeft(2, '0')}.${savedAt.year}';
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
