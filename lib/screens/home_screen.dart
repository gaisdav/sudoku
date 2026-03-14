import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../l10n/app_localizations.dart';
import '../providers/accent_color_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/vibration_enabled_provider.dart';
import '../services/game_storage.dart';
import '../services/interstitial_ad_service.dart';
import '../widgets/stats_dialog.dart' show formatDuration, showStatsDialog;
import 'game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeTab { main, instructions, settings }

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _HomeTab _selectedTab = _HomeTab.main;

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

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab.index,
          children: [
            _MainTabContent(
              hasSavedGame: hasSavedGame,
              onRefresh: () => setState(() {}),
              onOpenNewGame: _openNewGameAndRefreshOnReturn,
            ),
            const _InstructionsTabContent(),
            const _SettingsTabContent(),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: _CompactNavBar(
          currentIndex: _selectedTab.index,
          onTap: (index) => setState(() => _selectedTab = _HomeTab.values[index]),
          items: [
            _NavBarItem(icon: Icons.home_rounded, selectedIcon: Icons.home_rounded, label: l10n.tabHome),
            _NavBarItem(icon: Icons.menu_book_rounded, selectedIcon: Icons.menu_book_rounded, label: l10n.tabInstructions),
            _NavBarItem(icon: Icons.settings_rounded, selectedIcon: Icons.settings_rounded, label: l10n.settings),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem {
  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _CompactNavBar extends StatelessWidget {
  const _CompactNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavBarItem> items;

  static const double _iconSize = 22;
  static const double _iconToLabelGap = 2;
  static const double _verticalPadding = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurfaceVariant;
    final labelStyle = (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(fontSize: 11);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              final color = selected ? selectedColor : unselectedColor;
              final labelStyleWithColor = labelStyle.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              );
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? item.selectedIcon : item.icon,
                            size: _iconSize,
                            color: color,
                          ),
                          SizedBox(height: _iconToLabelGap),
                          Text(item.label, style: labelStyleWithColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MainTabContent extends StatelessWidget {
  const _MainTabContent({
    required this.hasSavedGame,
    required this.onRefresh,
    required this.onOpenNewGame,
  });

  final bool hasSavedGame;
  final VoidCallback onRefresh;
  final void Function(Level level) onOpenNewGame;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _SectionBlock(
          title: l10n.game,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContinueRow(
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
                        if (context.mounted) onRefresh();
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.newGame,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DifficultyChip(
                    label: l10n.levelEasy,
                    onTap: () => onOpenNewGame(Level.easy),
                  ),
                  _DifficultyChip(
                    label: l10n.levelMedium,
                    onTap: () => onOpenNewGame(Level.medium),
                  ),
                  _DifficultyChip(
                    label: l10n.levelHard,
                    onTap: () => onOpenNewGame(Level.hard),
                  ),
                  _DifficultyChip(
                    label: l10n.levelExpert,
                    onTap: () => onOpenNewGame(Level.expert),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        _SectionBlock(
          title: l10n.statistics,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FilledButton.tonalIcon(
              onPressed: () {
                InterstitialAdService.tryShowInterstitial(
                  context,
                  InterstitialTrigger.viewStatistics,
                  onDone: () => showStatsDialog(context),
                );
              },
              icon: const Icon(Icons.bar_chart),
              label: Text(l10n.viewStatistics),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionsTabContent extends StatelessWidget {
  const _InstructionsTabContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.shrink(),
    );
  }
}

class _SettingsTabContent extends StatelessWidget {
  const _SettingsTabContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: const [
        _SettingsSection(),
      ],
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final accentIndex = ref.watch(accentIndexProvider);
    final notifierTheme = ref.read(themeModeProvider.notifier);
    final notifierAccent = ref.read(accentIndexProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.theme,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(
                Icons.light_mode,
                color: themeMode == ThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              tooltip: l10n.lightTheme,
              onPressed: () => notifierTheme.setThemeMode(ThemeMode.light),
            ),
            IconButton(
              icon: Icon(
                Icons.dark_mode,
                color: themeMode == ThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              tooltip: l10n.darkTheme,
              onPressed: () => notifierTheme.setThemeMode(ThemeMode.dark),
            ),
            IconButton(
              icon: Icon(
                Icons.brightness_auto,
                color: themeMode == ThemeMode.system
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              tooltip: l10n.followSystem,
              onPressed: () => notifierTheme.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.language,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: ref.watch(localeProvider)?.languageCode ?? 'system',
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'system', child: Text(l10n.themeSystem)),
            DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
            DropdownMenuItem(value: 'ru', child: Text(l10n.languageRussian)),
            DropdownMenuItem(value: 'es', child: Text(l10n.languageSpanish)),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref.read(localeProvider.notifier).setLocale(
                  value == 'system' ? null : Locale(value),
                );
          },
        ),
        const SizedBox(height: 20),
        Text(
          l10n.accentColor,
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
          title: Text(l10n.vibration),
          subtitle: Text(l10n.vibrationSubtitle),
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
    final l10n = AppLocalizations.of(context)!;
    final levelLabels = [l10n.levelEasy, l10n.levelMedium, l10n.levelHard, l10n.levelExpert];
    final saved = hasSavedGame ? GameStorage.loadGame() : null;
    final difficultyIndex = (saved?[GameStorage.keyDifficulty] as num?)?.toInt() ?? 0;
    final levelLabel = levelLabels[difficultyIndex.clamp(0, levelLabels.length - 1)];
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
          label: Text(l10n.continueGame),
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
                    _formatSavedAt(l10n, savedAt),
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

  static String _formatSavedAt(AppLocalizations l10n, DateTime savedAt) {
    final timeStr = '${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${savedAt.day.toString().padLeft(2, '0')}.${savedAt.month.toString().padLeft(2, '0')}.${savedAt.year}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final savedDay = DateTime(savedAt.year, savedAt.month, savedAt.day);
    if (savedDay == today) {
      return l10n.savedTodayAt(timeStr);
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (savedDay == yesterday) {
      return l10n.savedYesterdayAt(timeStr);
    }
    return l10n.savedOn(dateStr);
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
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
