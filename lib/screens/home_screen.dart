import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../l10n/app_localizations.dart';
import '../providers/accent_color_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/vibration_enabled_provider.dart';
import '../services/game_storage.dart';
import '../services/streak_reminder_service.dart';
import '../services/interstitial_ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../providers/activity_streak_provider.dart';
import '../widgets/activity_calendar_panel.dart';
import '../widgets/stats_dialog.dart' show formatDuration, StatsSummarySection;
import 'game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeTab { main, instructions, statistics, settings }

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

  void _showDifficultyChooser({
    required String dialogTitle,
    required void Function(Level level) onPicked,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.chooseDifficulty),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: Text(l10n.levelEasy),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onPicked(Level.easy);
                    },
                  ),
                  ActionChip(
                    label: Text(l10n.levelMedium),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onPicked(Level.medium);
                    },
                  ),
                  ActionChip(
                    label: Text(l10n.levelHard),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onPicked(Level.hard);
                    },
                  ),
                  ActionChip(
                    label: Text(l10n.levelExpert),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onPicked(Level.expert);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showNewGameDifficultyPicker() {
    final l10n = AppLocalizations.of(context)!;
    _showDifficultyChooser(
      dialogTitle: l10n.newGame,
      onPicked: _openNewGameAndRefreshOnReturn,
    );
  }

  void _openTimedGame() {
    final l10n = AppLocalizations.of(context)!;
    void pushTimedNew(Level level) {
      InterstitialAdService.tryShowInterstitial(
        context,
        InterstitialTrigger.startNewGame,
        onDone: () {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GameScreen(
                timedNewGame: true,
                timedNewLevel: level,
              ),
            ),
          ).then((_) {
            if (mounted) setState(() {});
          });
        },
      );
    }

    void showTimedLevelPicker() {
      _showDifficultyChooser(
        dialogTitle: l10n.timedModeTitle,
        onPicked: pushTimedNew,
      );
    }

    if (GameStorage.loadTimedGame() != null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.timedContinueDialogTitle),
          content: Text(l10n.timedContinueDialogBody),
          actionsOverflowButtonSpacing: 14,
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                showTimedLevelPicker();
              },
              child: Text(l10n.timedStartNew),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                InterstitialAdService.tryShowInterstitial(
                  context,
                  InterstitialTrigger.continueGame,
                  onDone: () {
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GameScreen(continueTimed: true),
                      ),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                );
              },
              child: Text(l10n.continueGame),
            ),
          ],
        ),
      );
    } else {
      showTimedLevelPicker();
    }
  }

  void _goToStatisticsTab() {
    InterstitialAdService.tryShowInterstitial(
      context,
      InterstitialTrigger.viewStatistics,
      onDone: () {
        if (context.mounted) setState(() => _selectedTab = _HomeTab.statistics);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedGame = GameStorage.loadGame() != null;

    final l10n = AppLocalizations.of(context)!;
    final appBarTitle = switch (_selectedTab) {
      _HomeTab.main => l10n.appTitle,
      _HomeTab.instructions => l10n.instructionsTitle,
      _HomeTab.statistics => l10n.statistics,
      _HomeTab.settings => l10n.settings,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (_selectedTab == _HomeTab.main)
            _HomeAppBarStreakActions(
              current: ref.watch(currentStreakProvider),
              best: ref.watch(bestStreakProvider),
              onTap: _goToStatisticsTab,
            ),
        ],
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: IndexedStack(
            index: _selectedTab.index,
            children: [
              _MainTabContent(
                hasSavedGame: hasSavedGame,
                onRefresh: () => setState(() {}),
                onShowNewGameDifficultyPicker: _showNewGameDifficultyPicker,
                onOpenTimedGame: _openTimedGame,
              ),
              const _InstructionsTabContent(),
              const _StatisticsTabContent(),
              const _SettingsTabContent(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: _CompactNavBar(
          currentIndex: _selectedTab.index,
          onTap: (index) {
            if (index == _HomeTab.instructions.index) {
              InterstitialAdService.tryShowInterstitial(
                context,
                InterstitialTrigger.viewInstructions,
                onDone: () {
                  if (context.mounted) setState(() => _selectedTab = _HomeTab.instructions);
                },
              );
            } else if (index == _HomeTab.statistics.index) {
              _goToStatisticsTab();
            } else {
              setState(() => _selectedTab = _HomeTab.values[index]);
            }
          },
          items: [
            _NavBarItem(icon: Icons.home_rounded, selectedIcon: Icons.home_rounded, label: l10n.tabHome),
            _NavBarItem(icon: Icons.menu_book_rounded, selectedIcon: Icons.menu_book_rounded, label: l10n.tabInstructions),
            _NavBarItem(icon: Icons.bar_chart_rounded, selectedIcon: Icons.bar_chart_rounded, label: l10n.tabStatistics),
            _NavBarItem(icon: Icons.settings_rounded, selectedIcon: Icons.settings_rounded, label: l10n.settings),
          ],
        ),
      ),
    );
  }
}

/// Fire + current streak and trophy + best streak; matches statistics streak chip colors.
class _HomeAppBarStreakActions extends StatelessWidget {
  const _HomeAppBarStreakActions({
    required this.current,
    required this.best,
    required this.onTap,
  });

  final int current;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    Widget chip({required IconData icon, required String value}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(value, style: valueStyle),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(icon: Icons.local_fire_department, value: '$current'),
          chip(icon: Icons.emoji_events, value: '$best'),
        ],
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          size: _iconSize,
                          color: color,
                        ),
                        const SizedBox(height: _iconToLabelGap),
                        Text(
                          item.label,
                          style: labelStyleWithColor,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
    required this.onShowNewGameDifficultyPicker,
    required this.onOpenTimedGame,
  });

  final bool hasSavedGame;
  final VoidCallback onRefresh;
  final VoidCallback onShowNewGameDifficultyPicker;
  final VoidCallback onOpenTimedGame;

  static const double _actionRadius = 16;
  static const double _actionMinHeight = 52;
  /// Cap width on tablets / very wide phones so actions stay comfortably narrow.
  static const double _maxActionWidth = 420;
  static const double _padH = 16;
  static const double _padTop = 16;
  /// Extra air above the bottom tab bar (buttons sit low on home).
  static const double _padBottom = 28;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    const pad = EdgeInsets.fromLTRB(_padH, _padTop, _padH, _padBottom);
    final actionChildren = <Widget>[
      if (hasSavedGame) ...[
        _HomeContinueButton(
          borderRadius: _actionRadius,
          minHeight: _actionMinHeight,
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
        const SizedBox(height: 12),
      ],
      _HomeSecondaryActionButton(
        label: l10n.newGame,
        borderRadius: _actionRadius,
        minHeight: _actionMinHeight,
        onPressed: onShowNewGameDifficultyPicker,
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _HomeSecondaryActionButton(
              label: l10n.timedModeHomeButton,
              icon: Icons.timer_outlined,
              borderRadius: _actionRadius,
              minHeight: _actionMinHeight,
              onPressed: onOpenTimedGame,
            ),
          ),
          const SizedBox(width: 10),
          _HomeSquareInfoButton(
            borderRadius: _actionRadius,
            size: _actionMinHeight,
            tooltip: l10n.timedModeTitle,
            colorScheme: colorScheme,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.timedModeTitle),
                  content: SingleChildScrollView(
                    child: Text(
                      l10n.timedModeInfoBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.ok),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ];

    final actionsColumn = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxActionWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actionChildren,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight;
        if (!minH.isFinite || minH <= 0) {
          return SingleChildScrollView(
            padding: pad,
            child: actionsColumn,
          );
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Padding(
              padding: pad,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [actionsColumn],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatisticsTabContent extends StatelessWidget {
  const _StatisticsTabContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _SectionBlock(
          title: l10n.streak,
          child: const _StreakBlock(),
        ),
        const Divider(height: 32),
        _SectionBlock(
          title: l10n.statistics,
          child: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: StatsSummarySection(),
          ),
        ),
        const Divider(height: 32),
        _SectionBlock(
          title: l10n.activityCalendar,
          child: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: ActivityCalendarPanel(),
          ),
        ),
      ],
    );
  }
}

class _StreakBlock extends ConsumerWidget {
  const _StreakBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentStreakProvider);
    final best = ref.watch(bestStreakProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StreakChip(
                  icon: Icons.local_fire_department,
                  title: l10n.streakCurrentTitle,
                  value: l10n.streakDaysCount(current),
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StreakChip(
                  icon: Icons.emoji_events,
                  title: l10n.streakBestTitle,
                  value: l10n.streakDaysCount(best),
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.streakHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({
    required this.icon,
    required this.title,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionsTabContent extends StatelessWidget {
  const _InstructionsTabContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                l10n.instructionsBody,
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const BannerAdWidget(collapsible: false),
      ],
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
        SizedBox(height: 24),
        _StreakReminderSection(),
      ],
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final accentIndex = ref.watch(accentIndexProvider);
    final notifierTheme = ref.read(themeModeProvider.notifier);
    final notifierAccent = ref.read(accentIndexProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.theme,
          style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              tooltip: l10n.lightTheme,
              onPressed: () => notifierTheme.setThemeMode(ThemeMode.light),
            ),
            IconButton(
              icon: Icon(
                Icons.dark_mode,
                color: themeMode == ThemeMode.dark
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              tooltip: l10n.darkTheme,
              onPressed: () => notifierTheme.setThemeMode(ThemeMode.dark),
            ),
            IconButton(
              icon: Icon(
                Icons.brightness_auto,
                color: themeMode == ThemeMode.system
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              tooltip: l10n.followSystem,
              onPressed: () => notifierTheme.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.language,
          style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: ref.watch(localeProvider)?.languageCode ?? 'system',
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'system', child: Text(l10n.themeSystem)),
            const DropdownMenuItem(value: 'en', child: Text('English')),
            const DropdownMenuItem(value: 'ru', child: Text('Русский')),
            const DropdownMenuItem(value: 'es', child: Text('Español')),
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
          style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
                        color: selected ? theme.colorScheme.primary : Colors.transparent,
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
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.vibration),
          subtitle: Text(
            l10n.vibrationSubtitle,
            style: theme.textTheme.bodySmall,
          ),
          value: ref.watch(vibrationEnabledProvider),
          onChanged: (value) {
            ref.read(vibrationEnabledProvider.notifier).setEnabled(value);
          },
        ),
      ],
    );
  }
}

class _StreakReminderSection extends StatefulWidget {
  const _StreakReminderSection();

  @override
  State<_StreakReminderSection> createState() => _StreakReminderSectionState();
}

class _StreakReminderSectionState extends State<_StreakReminderSection> {
  late bool _enabled;
  late TimeOfDay _time;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _enabled = GameStorage.loadReminderEnabled();
    final parts = GameStorage.loadReminderTime().split(':');
    _time = TimeOfDay(
      hour: int.tryParse(parts[0].trim())?.clamp(0, 23) ?? 19,
      minute: parts.length > 1 ? (int.tryParse(parts[1].trim())?.clamp(0, 59) ?? 0) : 0,
    );
    _textController = TextEditingController(text: GameStorage.loadReminderText());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _timeToStorage(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _rescheduleIfEnabled(AppLocalizations l10n) async {
    if (!_enabled) return;
    var body = _textController.text.trim();
    if (body.isEmpty) body = l10n.streakReminderDefaultMessage;
    await GameStorage.saveReminderText(body);
    await StreakReminderService.scheduleDaily(
      hour: _time.hour,
      minute: _time.minute,
      title: l10n.appTitle,
      body: body,
    );
  }

  Future<void> _onToggle(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final ok = await StreakReminderService.requestNotificationPermission();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationPermissionDenied)),
        );
        return;
      }
      await GameStorage.saveReminderEnabled(true);
      await GameStorage.saveReminderTime(_timeToStorage(_time));
      var body = _textController.text.trim();
      if (body.isEmpty) {
        body = l10n.streakReminderDefaultMessage;
        _textController.text = body;
      }
      await GameStorage.saveReminderText(body);
      await StreakReminderService.scheduleDaily(
        hour: _time.hour,
        minute: _time.minute,
        title: l10n.appTitle,
        body: body,
      );
      setState(() => _enabled = true);
    } else {
      await GameStorage.saveReminderEnabled(false);
      await StreakReminderService.cancelReminder();
      setState(() => _enabled = false);
    }
  }

  Future<void> _pickTime() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
    await GameStorage.saveReminderTime(_timeToStorage(picked));
    await _rescheduleIfEnabled(l10n);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.streakReminder),
          subtitle: Text(
            l10n.streakReminderSubtitle,
            style: theme.textTheme.bodySmall,
          ),
          value: _enabled,
          onChanged: _onToggle,
        ),
        if (_enabled) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l10n.streakReminderTime),
            trailing: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(
                _time,
                alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            onTap: _pickTime,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: l10n.streakReminderMessage,
                hintText: l10n.streakReminderMessageHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              onEditingComplete: () async {
                FocusScope.of(context).unfocus();
                await GameStorage.saveReminderText(_textController.text.trim());
                await _rescheduleIfEnabled(l10n);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeContinueButton extends StatelessWidget {
  const _HomeContinueButton({
    required this.onContinue,
    required this.borderRadius,
    required this.minHeight,
  });

  final VoidCallback onContinue;
  final double borderRadius;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelLabels = [l10n.levelEasy, l10n.levelMedium, l10n.levelHard, l10n.levelExpert];
    final saved = GameStorage.loadGame();
    final difficultyIndex = (saved?[GameStorage.keyDifficulty] as num?)?.toInt() ?? 0;
    final levelLabel = levelLabels[difficultyIndex.clamp(0, levelLabels.length - 1)];
    final elapsedSeconds = (saved?[GameStorage.keyElapsedSeconds] as num?)?.toInt() ?? 0;
    final sublineColor = colorScheme.onPrimary.withValues(alpha: 0.82);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    final button = FilledButton(
      onPressed: onContinue,
      style: FilledButton.styleFrom(
        minimumSize: Size(double.infinity, minHeight + 18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: shape,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.continueGame,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 2,
                ),
          ),
          const SizedBox(height: 2),
          LayoutBuilder(
            builder: (context, c) {
              const iconW = 16.0;
              const gap = 6.0;
              final textMaxW = (c.maxWidth - iconW - gap).clamp(0.0, double.infinity);
              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 16, color: sublineColor),
                    const SizedBox(width: gap),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: textMaxW),
                      child: Text(
                        '${formatDuration(elapsedSeconds)} - $levelLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: sublineColor,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: button,
    );
  }
}

class _HomeSecondaryActionButton extends StatelessWidget {
  const _HomeSecondaryActionButton({
    required this.label,
    required this.borderRadius,
    required this.minHeight,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final double borderRadius;
  final double minHeight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.primary,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        minimumSize: Size(double.infinity, minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) + 2,
                ),
          ),
        ],
      ),
    );
  }
}

class _HomeSquareInfoButton extends StatelessWidget {
  const _HomeSquareInfoButton({
    required this.onPressed,
    required this.borderRadius,
    required this.size,
    required this.colorScheme,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final double borderRadius;
  final double size;
  final ColorScheme colorScheme;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                Icons.info_outline,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
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

