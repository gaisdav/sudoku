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
import '../widgets/stats_dialog.dart' show formatDuration, showStatsDialog;
import 'game_screen.dart';
import 'progress_screen.dart';

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
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.timedStartNew),
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
                        pushTimedNew(Level.easy);
                      },
                    ),
                    ActionChip(
                      label: Text(l10n.levelMedium),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        pushTimedNew(Level.medium);
                      },
                    ),
                    ActionChip(
                      label: Text(l10n.levelHard),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        pushTimedNew(Level.hard);
                      },
                    ),
                    ActionChip(
                      label: Text(l10n.levelExpert),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        pushTimedNew(Level.expert);
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
              onOpenTimedGame: _openTimedGame,
              ref: ref,
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
          onTap: (index) {
            if (index == _HomeTab.instructions.index) {
              InterstitialAdService.tryShowInterstitial(
                context,
                InterstitialTrigger.viewInstructions,
                onDone: () {
                  if (context.mounted) setState(() => _selectedTab = _HomeTab.instructions);
                },
              );
            } else {
              setState(() => _selectedTab = _HomeTab.values[index]);
            }
          },
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
                          const SizedBox(height: _iconToLabelGap),
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
    required this.onOpenTimedGame,
    this.ref,
  });

  final bool hasSavedGame;
  final VoidCallback onRefresh;
  final void Function(Level level) onOpenNewGame;
  final VoidCallback onOpenTimedGame;
  final WidgetRef? ref;

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
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onOpenTimedGame,
                      icon: const Icon(Icons.timer_outlined),
                      label: Text(l10n.timedModeHomeButton),
                    ),
                  ),
                  IconButton(
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
                    icon: const Icon(Icons.info_outline),
                    tooltip: l10n.timedModeTitle,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        _SectionBlock(
          title: l10n.streak,
          child: const _StreakBlock(),
        ),
        const Divider(height: 32),
        _SectionBlock(
          title: l10n.statistics,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    InterstitialAdService.tryShowInterstitial(
                      context,
                      InterstitialTrigger.viewStatistics,
                      onDone: () => showStatsDialog(context, ref: ref),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: Text(l10n.viewStatistics),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProgressScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(l10n.viewProgress),
                ),
              ],
            ),
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
                l10n.instructionsTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
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
        Text(
          l10n.streakReminder,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
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
