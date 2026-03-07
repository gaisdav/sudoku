import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../providers/game_provider.dart';

const _blue = Color(0xFF2196F3);

class NumberPad extends ConsumerWidget {
  const NumberPad({super.key});

  /// For each digit 1-9, how many are still to be placed (9 - count on board).
  static List<int> _remainingCounts(GameState state) {
    final counts = List.filled(10, 0);
    for (final c in state.cells) {
      if (c.value >= 1 && c.value <= 9) counts[c.value]++;
    }
    return List.generate(10, (i) => i == 0 ? 0 : (9 - counts[i]).clamp(0, 9));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final hasSelection = state.selectedCellIndex != null;
    final canEdit = hasSelection && !state.isWon;
    final showRemaining = state.difficulty == Level.easy || state.difficulty == Level.medium;
    final remaining = showRemaining ? _remainingCounts(state) : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.grey.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 2, 3, 4, 5]
                .map((n) => _padCell(context, n, canEdit, notifier, remaining?[n]))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int n in [6, 7, 8, 9]) _padCell(context, n, canEdit, notifier, remaining?[n]),
              _clearCell(context, canEdit, notifier),
            ],
          ),
        ],
      ),
    );
  }

  Widget _padCell(
    BuildContext context,
    int n,
    bool canEdit,
    GameNotifier notifier, [
    int? remaining,
  ]) {
    // On Easy/Medium: block digit if all 9 are already placed (remaining == 0).
    final digitEnabled = remaining == null || remaining > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: _NumButton(
        label: '$n',
        remaining: remaining != null && remaining > 0 ? remaining : null,
        onPressed: canEdit && digitEnabled
            ? () {
                HapticFeedback.lightImpact();
                notifier.setCellValue(n);
              }
            : null,
      ),
    );
  }

  Widget _clearCell(BuildContext context, bool canEdit, GameNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: _NumButton(
        icon: Icons.close,
        onPressed: canEdit
            ? () {
                HapticFeedback.selectionClick();
                notifier.clearCell();
              }
            : null,
      ),
    );
  }
}

class _NumButton extends StatelessWidget {
  const _NumButton({
    this.label,
    this.icon,
    this.remaining,
    this.onPressed,
  });

  final String? label;
  final IconData? icon;
  /// Shown top-right on Easy/Medium when > 0 (how many of this digit left to place).
  final int? remaining;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final mainChild = label != null
        ? Text(
            label!,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: enabled ? _blue : Colors.grey.shade400,
            ),
          )
        : Icon(
            icon,
            size: 26,
            color: enabled ? _blue : Colors.grey.shade400,
          );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: remaining != null
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: mainChild),
                    Positioned(
                      top: 4,
                      right: 6,
                      child: Text(
                        '$remaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                )
              : mainChild,
        ),
      ),
    );
  }
}
