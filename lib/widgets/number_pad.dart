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

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const gap = 8.0;
        const countPerRow = 5;
        final availableWidth = (constraints.maxWidth - horizontalPadding * 2).clamp(0.0, double.infinity);
        final buttonSize = ((availableWidth - (countPerRow - 1) * gap) / countPerRow)
            .clamp(40.0, 52.0)
            .floorToDouble();
        const padding = gap / 2;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.grey.shade50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3, 4, 5]
                    .map((n) => _padCell(context, n, canEdit, notifier, remaining?[n], buttonSize, padding))
                    .toList(),
              ),
              const SizedBox(height: gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int n in [6, 7, 8, 9]) _padCell(context, n, canEdit, notifier, remaining?[n], buttonSize, padding),
                  _clearCell(context, canEdit, notifier, buttonSize, padding),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _padCell(
    BuildContext context,
    int n,
    bool canEdit,
    GameNotifier notifier, [
    int? remaining,
    double buttonSize = 52,
    double padding = 5,
  ]) {
    // On Easy/Medium: block digit if all 9 are already placed (remaining == 0).
    final digitEnabled = remaining == null || remaining > 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: _NumButton(
        size: buttonSize,
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

  Widget _clearCell(BuildContext context, bool canEdit, GameNotifier notifier, [double buttonSize = 52, double padding = 5]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: _NumButton(
        size: buttonSize,
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
    this.size = 52,
    this.label,
    this.icon,
    this.remaining,
    this.onPressed,
  });

  final double size;
  final String? label;
  final IconData? icon;
  /// Shown top-right on Easy/Medium when > 0 (how many of this digit left to place).
  final int? remaining;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fontSize = (size * 0.42).clamp(16.0, 22.0);
    final iconSize = (size * 0.5).clamp(20.0, 26.0);
    final mainChild = label != null
        ? Text(
            label!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: enabled ? _blue : Colors.grey.shade400,
            ),
          )
        : Icon(
            icon,
            size: iconSize,
            color: enabled ? _blue : Colors.grey.shade400,
          );

    final borderRadius = (size * 0.23).clamp(8.0, 12.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: remaining != null
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: mainChild),
                    Positioned(
                      top: 2,
                      right: 4,
                      child: Text(
                        '$remaining',
                        style: TextStyle(
                          fontSize: (size * 0.21).clamp(9.0, 11.0),
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
