import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../providers/game_provider.dart';
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

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.isWon && prev?.isWon != true) {
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
                  Navigator.of(ctx).pop();
                  ref.read(gameProvider.notifier).newGame();
                },
                child: const Text('New game'),
              ),
            ],
          ),
        );
      }
    });

    return _GameScreenBody();
  }
}

const _blue = Color(0xFF2196F3);

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
            notifier.pauseTimer();
            Navigator.of(context).pop();
          },
          tooltip: 'Back to menu',
        ),
        title: const Text('Sudoku'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'new') _showNewGameDialog(context, ref);
              if (value == 'stats') showStatsDialog(context);
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
                ],
              ),
            ),
            const Expanded(child: SudokuGrid()),
            // Undo, Notes, Hint
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const _ActionButton(
                    icon: Icons.undo,
                    label: 'Undo',
                    onPressed: null,
                  ),
                  const _ActionButton(
                    icon: Icons.edit_note,
                    label: 'Notes',
                    onPressed: null,
                  ),
                  _ActionButton(
                    icon: Icons.lightbulb_outline,
                    label: 'Hint',
                    badge: state.hasFreeHintLeft ? '1' : 'Ad',
                    onPressed: state.isWon
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            final applied = notifier.applyHint();
                            if (!applied) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Watch an ad to get another hint (coming soon).'),
                                  duration: Duration(seconds: 2),
                                ),
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
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: enabled ? _blue : Colors.grey.shade400,
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Text(
                  badge!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled ? _blue : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.grey.shade800 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
