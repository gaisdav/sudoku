import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_grid.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.isWon && prev?.isWon != true) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('You won!'),
            content: const Text('Congratulations, you completed the puzzle.'),
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

class _GameScreenBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gameProvider.notifier).newGame(),
            tooltip: 'New game',
          ),
        ],
      ),
      body: const SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16),
            Expanded(child: SudokuGrid()),
            NumberPad(),
          ],
        ),
      ),
    );
  }
}
