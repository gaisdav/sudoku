import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../utils/vibration_helper.dart'
    show hapticLightImpact, hapticSelection, vibrateOnGameOver;
import '../providers/theme_mode_provider.dart';
import '../services/interstitial_ad_service.dart';
import '../services/rewarded_ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/number_pad.dart';
import '../widgets/stats_dialog.dart';
import '../widgets/sudoku_grid.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    this.continueLast = false,
    this.newGameLevel,
  });

  /// Open and restore saved game (from home "Continue").
  final bool continueLast;

  /// Open and start new game with this level (from home difficulty choice).
  final Level? newGameLevel;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    // Start/restore game after first frame — must not modify provider during build/initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(gameProvider.notifier);
      if (widget.continueLast) {
        notifier.ensureGameStarted();
      } else if (widget.newGameLevel != null) {
        notifier.newGame(widget.newGameLevel!);
      } else {
        notifier.ensureGameStarted(Level.easy);
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(gameProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        notifier.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        notifier.onAppResumed();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.isWon && prev?.isWon != true) {
        ref.read(gameProvider.notifier).pauseTimer();
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final l10n = AppLocalizations.of(context)!;
            final prevBest = next.previousBestTimeForLevel;
            final isNewRecord =
                prevBest == null || next.elapsedSeconds <= prevBest;
            final recordText = isNewRecord
                ? l10n.newRecord
                : l10n.slowerThanBest(formatDuration(next.elapsedSeconds - prevBest));
            return AlertDialog(
              title: Text(l10n.youWon),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.congratulations),
                  const SizedBox(height: 8),
                  Text(
                    l10n.timeLabel(formatDuration(next.elapsedSeconds)),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.hintsUsedLabel(next.hintsUsedThisGame),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recordText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isNewRecord
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    InterstitialAdService.tryShowInterstitial(
                      context,
                      InterstitialTrigger.backToMenu,
                      onDone: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: Text(l10n.backToMenu),
                ),
                TextButton(
                  onPressed: () {
                    InterstitialAdService.tryShowInterstitial(
                      context,
                      InterstitialTrigger.restartYouWon,
                      onDone: () {
                        Navigator.of(ctx).pop();
                        ref.read(gameProvider.notifier).newGame();
                      },
                    );
                  },
                  child: Text(l10n.newGame),
                ),
              ],
            );
          },
        );
      }
      if (next.errorsMade > next.maxErrors &&
          !next.gameOverDialogShown &&
          !next.noErrorsModeThisSession) {
        ref.read(gameProvider.notifier).markGameOverDialogShown();
        ref.read(gameProvider.notifier).pauseTimer();
        vibrateOnGameOver();
        showGameOverDialog(context, ref, next.difficulty);
      }
    });

    return _GameScreenBody();
  }
}

/// Ширина экрана, при которой кнопки Undo/Notes/Hint в «компактном» размере.
const _kActionCompactWidth = 360.0;

/// Ширина экрана, при которой кнопки достигают максимального размера (планшеты).
const _kActionLargeWidth = 640.0;

/// Loading-ad dialog with spinner (Hint, Undo, Second chance, No errors mode).
class _LoadingAdDialog extends StatelessWidget {
  const _LoadingAdDialog({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              message ?? AppLocalizations.of(context)!.loadingAd,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show "No errors mode" dialog: explanation and "Watch 3 ads" / "Cancel". Timer is already paused.
void _showNoErrorsModeDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final notifier = ref.read(gameProvider.notifier);
  final alreadyEnabled = ref.read(gameProvider).noErrorsModeThisSession;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.noErrorsMode),
      content: Text(
        alreadyEnabled
            ? l10n.noErrorsModeAlreadyOn
            : l10n.noErrorsModeDescription,
      ),
      actions: [
        if (!alreadyEnabled)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.onAppResumed();
            },
            child: Text(l10n.cancel),
          ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            if (alreadyEnabled) {
              notifier.onAppResumed();
            } else {
              _watchAdsForNoErrorsMode(context, ref, 0);
            }
          },
          child: Text(alreadyEnabled ? l10n.ok : l10n.watch3Ads),
        ),
      ],
    ),
  );
}

/// Show ad at [adIndex] (0, 1, 2); after the third, enable no-errors mode and resume timer.
void _watchAdsForNoErrorsMode(
    BuildContext context, WidgetRef ref, int adIndex) {
  final notifier = ref.read(gameProvider.notifier);
  if (adIndex >= 3) {
    notifier.setNoErrorsModeThisSession(true);
    notifier.onAppResumed();
    return;
  }
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _LoadingAdDialog(
      message: AppLocalizations.of(context)!.adProgress(adIndex + 1),
    ),
  );
  showRewardedAd(
    context,
    onAdReadyToShow: () {
      if (context.mounted) Navigator.of(context).pop();
    },
    onRewarded: () {},
    onDismissed: () {
      if (context.mounted) _watchAdsForNoErrorsMode(context, ref, adIndex + 1);
    },
    onNotAvailable: () {
      if (context.mounted) {
        Navigator.of(context).pop();
        notifier.onAppResumed();
      }
    },
  );
}

void showGameOverDialog(BuildContext context, WidgetRef ref, Level difficulty) {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.gameOver),
      content: Text(l10n.gameOverDescription),
      actions: [
        TextButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const _LoadingAdDialog(),
            );
            showRewardedAd(
              context,
              onAdReadyToShow: () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
              onRewarded: () {
                final notifier = ref.read(gameProvider.notifier);
                notifier.clearWrongCells();
                notifier.resetErrors();
                notifier.resetGameOverDialogShown();
                notifier.onAppResumed();
              },
              onNotAvailable: () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ref.read(gameProvider.notifier).clearWrongCells();
                  ref.read(gameProvider.notifier).resetErrors();
                  ref.read(gameProvider.notifier).resetGameOverDialogShown();
                  ref.read(gameProvider.notifier).onAppResumed();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.adNotAvailableSecondChance),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          },
          child: Text(l10n.secondChanceAd),
        ),
        TextButton(
          onPressed: () {
            InterstitialAdService.tryShowInterstitial(
              context,
              InterstitialTrigger.restartGameOver,
              onDone: () {
                Navigator.of(ctx).pop();
                ref.read(gameProvider.notifier).newGame(difficulty);
              },
            );
          },
          child: Text(l10n.restart),
        ),
        TextButton(
          onPressed: () {
            InterstitialAdService.tryShowInterstitial(
              context,
              InterstitialTrigger.backToMenu,
              onDone: () {
                Navigator.of(ctx).pop();
                ref.read(gameProvider.notifier).endGameAndClearSave().then((_) {
                  if (context.mounted) Navigator.of(context).pop();
                });
              },
            );
          },
          child: Text(l10n.backToMenu),
        ),
      ],
    ),
  );
}

class _GameScreenBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.onAppPaused();
            InterstitialAdService.tryShowInterstitial(
              context,
              InterstitialTrigger.backToMenu,
              onDone: () {
                notifier.pauseTimer();
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          },
          tooltip: l10n.backToMenu,
        ),
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.menu,
            onSelected: (value) {
              if (value == 'new') {
                notifier.onAppPaused();
                InterstitialAdService.tryShowInterstitial(
                  context,
                  InterstitialTrigger.newGameInHeader,
                  onDone: () {
                    notifier.onAppResumed();
                    _showNewGameDialog(context, ref);
                  },
                );
              }
              if (value == 'stats') {
                notifier.onAppPaused();
                showStatsDialog(context).then((_) {
                  if (context.mounted) notifier.onAppResumed();
                });
              }
              if (value == 'no_errors') {
                notifier.pauseTimer();
                _showNoErrorsModeDialog(context, ref);
              }
            },
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final themeMode = ref.watch(themeModeProvider);
              final gameState = ref.watch(gameProvider);
              final colorScheme = Theme.of(context).colorScheme;
              return [
                PopupMenuItem(value: 'new', child: Text(l10n.newGame)),
                PopupMenuItem(value: 'stats', child: Text(l10n.statistics)),
                PopupMenuItem<String>(
                  value: 'no_errors',
                  child: Row(
                    children: [
                      Text(l10n.noErrorsMode),
                      if (gameState.noErrorsModeThisSession) ...[
                        const Spacer(),
                        const Icon(Icons.check, size: 20),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme_row',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.light_mode,
                            color: themeMode == ThemeMode.light
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          tooltip: l10n.lightTheme,
                          onPressed: () {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(ThemeMode.light);
                            Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.dark_mode,
                            color: themeMode == ThemeMode.dark
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          tooltip: l10n.darkTheme,
                          onPressed: () {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(ThemeMode.dark);
                            Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.brightness_auto,
                            color: themeMode == ThemeMode.system
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          tooltip: l10n.followSystem,
                          onPressed: () {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(ThemeMode.system);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer + difficulty + errors bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatDuration(state.elapsedSeconds),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.access_time,
                            size: 18, color: colors.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.bar_chart, size: 20, color: colors.textMutedDark),
                  const SizedBox(width: 6),
                  Text(
                    _difficultyName(l10n, state.difficulty),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (state.difficulty != Level.expert) ...[
                    const Spacer(),
                    if (state.noErrorsModeThisSession) ...[
                      Icon(Icons.check_circle_outline,
                          size: 20, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.noErrors,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.warning_amber_rounded,
                          size: 20, color: colors.textMutedDark),
                      const SizedBox(width: 6),
                      Text(
                        '${state.errorsMade} / ${state.maxErrors}',
                        style: TextStyle(
                          fontSize: 14,
                          color: state.errorsMade >= state.maxErrors
                              ? colors.errorDark
                              : colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            // Сетка и блок «кнопки + numpad» делят пространство: на больших экранах нижний блок центрируется по высоте
            Expanded(
              child: Column(
                children: [
                  const Expanded(
                    flex: 2,
                    child: SudokuGrid(),
                  ),
                  Expanded(
                    flex: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final scale = ((w - _kActionCompactWidth) /
                                (_kActionLargeWidth - _kActionCompactWidth))
                            .clamp(0.0, 1.0);
                        final outerH = 6.0 + scale * 6.0; // 6 .. 12
                        final gap = 6.0 + scale * 6.0; // 6 .. 12
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: outerH, vertical: 4),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    _ActionButton(
                                      icon: Icons.undo,
                                      label: l10n.undo,
                                      badge: _undoBadge(l10n, state),
                                      actionScale: scale,
                                      onPressed: _undoEnabled(state)
                                          ? () =>
                                              _onUndoTap(context, ref, state)
                                          : null,
                                    ),
                                    _ActionButton(
                                      icon: Icons.edit_note,
                                      label: l10n.notes,
                                      isActive: state.isNotesMode,
                                      actionScale: scale,
                                      onPressed: state.isWon
                                          ? null
                                          : () {
                                              hapticSelection();
                                              notifier.onAppPaused();
                                              InterstitialAdService
                                                  .tryShowInterstitial(
                                                context,
                                                InterstitialTrigger.notes,
                                                onDone: () {
                                                  notifier.onAppResumed();
                                                  notifier.toggleNotesMode();
                                                },
                                              );
                                            },
                                    ),
                                    _ActionButton(
                                      icon: Icons.lightbulb_outline,
                                      label: l10n.hint,
                                      badge: state.freeHintsLeft > 0
                                          ? '${state.freeHintsLeft}'
                                          : l10n.adBadge,
                                      actionScale: scale,
                                      onPressed: state.isWon
                                          ? null
                                          : () async {
                                              hapticLightImpact();
                                              final applied =
                                                  notifier.applyHint();
                                              if (!applied) {
                                                if (!context.mounted) return;
                                                notifier.onAppPaused();
                                                showDialog<void>(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) =>
                                                      const _LoadingAdDialog(),
                                                );
                                                showRewardedAd(
                                                  context,
                                                  onAdReadyToShow: () {
                                                    if (context.mounted)
                                                      Navigator.of(context)
                                                          .pop();
                                                  },
                                                  onRewarded: () => notifier
                                                      .applyHintFromAd(),
                                                  onDismissed: () =>
                                                      notifier.onAppResumed(),
                                                  onNotAvailable: () {
                                                    if (context.mounted) {
                                                      Navigator.of(context)
                                                          .pop();
                                                      notifier
                                                          .applyHintFromAd();
                                                      notifier.onAppResumed();
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              AppLocalizations.of(context)!.adNotAvailableHintApplied),
                                                          duration: const Duration(
                                                              seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                );
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                              const NumberPad(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const BannerAdWidget(collapsible: true),
          ],
        ),
      ),
    );
  }

  static String _difficultyName(AppLocalizations l10n, Level level) {
    return switch (level) {
      Level.easy => l10n.levelEasy,
      Level.medium => l10n.levelMedium,
      Level.hard => l10n.levelHard,
      Level.expert => l10n.levelExpert,
    };
  }

  static String _undoBadge(AppLocalizations l10n, GameState state) {
    if (state.undoRemaining > 0) return '${state.undoRemaining}';
    return l10n.adBadge;
  }

  static bool _undoEnabled(GameState state) {
    return !state.isWon && state.undoStack.isNotEmpty;
  }

  static void _onUndoTap(BuildContext context, WidgetRef ref, GameState state) {
    final notifier = ref.read(gameProvider.notifier);
    if (state.undoRemaining > 0) {
      hapticSelection();
      notifier.undo();
      return;
    }
    notifier.onAppPaused();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingAdDialog(),
    );
    showRewardedAd(
      context,
      onAdReadyToShow: () {
        if (context.mounted) Navigator.of(context).pop();
      },
      onRewarded: () {
        if (state.difficulty == Level.expert) {
          notifier.performUndoAfterAd();
        } else {
          notifier.refillUndoAfterAd();
        }
      },
      onDismissed: () => notifier.onAppResumed(),
      onNotAvailable: () {
        if (context.mounted) {
          Navigator.of(context).pop();
          if (state.difficulty == Level.expert) {
            notifier.performUndoAfterAd();
          } else {
            notifier.refillUndoAfterAd();
          }
          notifier.onAppResumed();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.adNotAvailableUndoApplied),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  static void _showNewGameDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newGame),
        content: Text(l10n.chooseDifficulty),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.easy);
            },
            child: Text(l10n.levelEasy),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.medium);
            },
            child: Text(l10n.levelMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.hard);
            },
            child: Text(l10n.levelHard),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.expert);
            },
            child: Text(l10n.levelExpert),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.badge,
    this.isActive = false,
    this.actionScale = 0.0,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;

  /// 0 = компактный размер (узкий экран), 1 = крупный (планшет). Масштабирование отступов и шрифтов.
  final double actionScale;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    final active = isActive && enabled;
    final t = actionScale.clamp(0.0, 1.0);
    final hPad = 12.0 + t * 12.0; // 12 .. 24
    final vPad = 8.0 + t * 6.0; // 8 .. 14
    final radius = 8.0 + t * 8.0; // 8 .. 16
    final iconSize = 18.0 + t * 12.0; // 18 .. 30
    final fontSize = 12.0 + t * 6.0; // 12 .. 18
    final gap = 4.0 + t * 4.0; // 4 .. 8
    final labelGap = 6.0 + t * 6.0; // 6 .. 12
    return Material(
      color: active ? colors.primary.withValues(alpha: 0.15) : colors.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: active ? colors.primary : colors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: active
                    ? colors.primary
                    : (enabled ? colors.primary : colors.disabled),
              ),
              if (badge != null) ...[
                SizedBox(width: gap),
                Text(
                  badge!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: active
                        ? colors.primary
                        : (enabled ? colors.primary : colors.disabled),
                    fontSize: fontSize,
                  ),
                ),
              ],
              SizedBox(width: labelGap),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active
                      ? colors.primary
                      : (enabled ? colors.textSecondary : colors.disabled),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
