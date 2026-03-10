import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/game_provider.dart';
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
          builder: (ctx) => AlertDialog(
            title: const Text('You won!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Congratulations, you completed the puzzle.'),
                const SizedBox(height: 8),
                Text(
                  'Time: ${formatDuration(next.elapsedSeconds)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Hints used: ${next.hintsUsedThisGame}',
                  style: Theme.of(context).textTheme.titleSmall,
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
                child: const Text('Back to menu'),
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
                child: const Text('New game'),
              ),
            ],
          ),
        );
      }
      if (next.errorsMade > next.maxErrors && !next.gameOverDialogShown) {
        ref.read(gameProvider.notifier).markGameOverDialogShown();
        ref.read(gameProvider.notifier).pauseTimer();
        showGameOverDialog(context, ref, next.difficulty);
      }
    });

    return _GameScreenBody();
  }
}

const _blue = Color(0xFF2196F3);

/// Диалог «загрузка рекламы» со спиннером (Hint, Undo, Second chance).
class _LoadingAdDialog extends StatelessWidget {
  const _LoadingAdDialog();

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
              'Loading ad…',
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

void showGameOverDialog(
    BuildContext context, WidgetRef ref, Level difficulty) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Game over'),
      content: const Text(
        'You have exceeded the allowed number of errors for this difficulty.',
      ),
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
                    const SnackBar(
                      content: Text('Ad not available. Second chance applied.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          },
          child: const Text('Second chance (Ad)'),
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
          child: const Text('Restart'),
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
          child: const Text('Back to menu'),
        ),
      ],
    ),
  );
}

class _GameScreenBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
          tooltip: 'Back to menu',
        ),
        title: const Text('Sudoku'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
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
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new', child: Text('New game')),
              const PopupMenuItem(value: 'stats', child: Text('Statistics')),
            ],
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatDuration(state.elapsedSeconds),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.access_time,
                            size: 18, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.bar_chart, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Text(
                    _difficultyName(state.difficulty),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (state.difficulty != Level.expert) ...[
                    const Spacer(),
                    Icon(Icons.warning_amber_rounded,
                        size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      '${state.errorsMade} / ${state.maxErrors}',
                      style: TextStyle(
                        fontSize: 14,
                        color: state.errorsMade >= state.maxErrors
                            ? Colors.red.shade700
                            : Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Expanded(child: SudokuGrid()),
            // Undo, Notes, Hint — на узких экранах компактные отступы и кнопки
            LayoutBuilder(
              builder: (context, constraints) {
                const breakpoint = 360.0;
                final compact = constraints.maxWidth < breakpoint;
                final outerH = compact ? 8.0 : 16.0;
                final gap = compact ? 8.0 : 16.0;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: outerH, vertical: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      _ActionButton(
                        icon: Icons.undo,
                        label: 'Undo',
                        badge: _undoBadge(state),
                        compact: compact,
                        onPressed: _undoEnabled(state)
                            ? () => _onUndoTap(context, ref, state)
                            : null,
                      ),
                      _ActionButton(
                        icon: Icons.edit_note,
                        label: 'Notes',
                        isActive: state.isNotesMode,
                        compact: compact,
                        onPressed: state.isWon
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                notifier.onAppPaused();
                                InterstitialAdService.tryShowInterstitial(
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
                        label: 'Hint',
                        badge: state.freeHintsLeft > 0 ? '${state.freeHintsLeft}' : 'Ad',
                        compact: compact,
                        onPressed: state.isWon
                            ? null
                            : () async {
                                HapticFeedback.lightImpact();
                                final applied = notifier.applyHint();
                                if (!applied) {
                                  if (!context.mounted) return;
                                  notifier.onAppPaused();
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
                                    onRewarded: () => notifier.applyHintFromAd(),
                                    onDismissed: () => notifier.onAppResumed(),
                                    onNotAvailable: () {
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        notifier.applyHintFromAd();
                                        notifier.onAppResumed();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Ad not available. Hint applied.'),
                                            duration: Duration(seconds: 2),
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
                );
              },
            ),
            const NumberPad(),
            const BannerAdWidget(collapsible: true),
          ],
        ),
      ),
    );
  }

  static String _difficultyName(Level level) {
    return switch (level) {
      Level.easy => 'Easy',
      Level.medium => 'Medium',
      Level.hard => 'Hard',
      Level.expert => 'Expert',
    };
  }

  static String _undoBadge(GameState state) {
    if (state.undoRemaining > 0) return '${state.undoRemaining}';
    return 'Ad';
  }

  static bool _undoEnabled(GameState state) {
    return !state.isWon && state.undoStack.isNotEmpty;
  }

  static void _onUndoTap(BuildContext context, WidgetRef ref, GameState state) {
    final notifier = ref.read(gameProvider.notifier);
    if (state.undoRemaining > 0) {
      HapticFeedback.selectionClick();
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
            const SnackBar(
              content: Text('Ad not available. Undo applied.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  static void _showNewGameDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New game'),
        content: const Text('Choose difficulty:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.easy);
            },
            child: const Text('Easy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.medium);
            },
            child: const Text('Medium'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.hard);
            },
            child: const Text('Hard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).newGame(Level.expert);
            },
            child: const Text('Expert'),
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
    this.compact = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;
  /// На узких экранах: меньше отступы и размер иконки/шрифта.
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final active = isActive && enabled;
    final hPad = compact ? 12.0 : 20.0;
    final vPad = compact ? 8.0 : 12.0;
    final radius = compact ? 8.0 : 12.0;
    final iconSize = compact ? 18.0 : 22.0;
    final fontSize = compact ? 12.0 : 14.0;
    final gap = compact ? 4.0 : 6.0;
    final labelGap = compact ? 6.0 : 8.0;
    return Material(
      color: active ? _blue.withValues(alpha: 0.15) : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: active ? _blue : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: active ? _blue : (enabled ? _blue : Colors.grey.shade400),
              ),
              if (badge != null) ...[
                SizedBox(width: gap),
                Text(
                  badge!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: active ? _blue : (enabled ? _blue : Colors.grey.shade400),
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
                  color: active ? _blue : (enabled ? Colors.grey.shade800 : Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
