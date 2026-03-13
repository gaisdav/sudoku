import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/vibration_helper.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../config/app_colors.dart';
import '../providers/game_provider.dart';

/// Min/max side of each number-pad button so it scales on small and large screens (like the grid).
const _kMinButtonSize = 40.0;
const _kMaxButtonSize = 76.0;

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
    final isNotesMode = state.isNotesMode;
    // In Notes mode hide remaining counts; otherwise show on Easy/Medium.
    final showRemaining = !isNotesMode && (state.difficulty == Level.easy || state.difficulty == Level.medium);
    final remaining = showRemaining ? _remainingCounts(state) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const gap = 8.0;
        const countPerRow = 5;
        final availableWidth = (constraints.maxWidth - horizontalPadding * 2).clamp(0.0, double.infinity);
        final buttonSize = ((availableWidth - (countPerRow - 1) * gap) / countPerRow)
            .clamp(_kMinButtonSize, _kMaxButtonSize)
            .floorToDouble();
        const padding = gap / 2;

        final colors = context.appColors;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: colors.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3, 4, 5]
                    .map((n) => _padCell(context, n, canEdit, isNotesMode, notifier, state, remaining?[n], buttonSize, padding, colors))
                    .toList(),
              ),
              const SizedBox(height: gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int n in [6, 7, 8, 9]) _padCell(context, n, canEdit, isNotesMode, notifier, state, remaining?[n], buttonSize, padding, colors),
                  _clearCell(context, canEdit, isNotesMode, notifier, buttonSize, padding, colors),
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
    bool isNotesMode,
    GameNotifier notifier,
    GameState state, [
    int? remaining,
    double buttonSize = 52,
    double padding = 5,
    AppColors? colors,
  ]) {
    final c = colors ?? context.appColors;
    final digitEnabled = isNotesMode || remaining == null || remaining > 0;
    final isConflictFlash = state.conflictFlashDigit == n;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: _NumButton(
        colors: c,
        size: buttonSize,
        label: '$n',
        remaining: remaining != null && remaining > 0 ? remaining : null,
        isConflictFlash: isConflictFlash,
        onPressed: canEdit && digitEnabled
            ? () {
                if (isNotesMode) {
                  hapticLightImpact();
                  notifier.toggleNote(n);
                } else {
                  hapticLightImpact();
                  notifier.setCellValue(n);
                }
              }
            : null,
      ),
    );
  }

  Widget _clearCell(BuildContext context, bool canEdit, bool isNotesMode, GameNotifier notifier, [double buttonSize = 52, double padding = 5, AppColors? colors]) {
    final c = colors ?? context.appColors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: _NumButton(
        colors: c,
        size: buttonSize,
        icon: Icons.close,
        onPressed: canEdit
            ? () {
                hapticSelection();
                if (isNotesMode) {
                  notifier.clearNotesInCell();
                } else {
                  notifier.clearCell();
                }
              }
            : null,
      ),
    );
  }
}

class _NumButton extends StatelessWidget {
  const _NumButton({
    required this.colors,
    this.size = 52,
    this.label,
    this.icon,
    this.remaining,
    this.isConflictFlash = false,
    this.onPressed,
  });

  final AppColors colors;
  final double size;
  final String? label;
  final IconData? icon;
  /// Shown top-right on Easy/Medium when > 0 (how many of this digit left to place). Hidden in Notes mode.
  final int? remaining;
  /// Red flash when this digit was rejected as note (conflict with original).
  final bool isConflictFlash;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fontSize = (size * 0.42).clamp(16.0, 28.0);
    final iconSize = (size * 0.5).clamp(20.0, 34.0);
    final mainChild = label != null
        ? Text(
            label!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: enabled ? colors.primary : colors.disabled,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        : Icon(
            icon,
            size: iconSize,
            color: enabled ? colors.primary : colors.disabled,
          );

    final borderRadius = (size * 0.23).clamp(8.0, 16.0);
    final borderColor = isConflictFlash ? colors.error : colors.border;
    final bgColor = isConflictFlash ? colors.errorLight : colors.surface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: isConflictFlash ? 2 : 1),
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
                          fontSize: (size * 0.21).clamp(9.0, 14.0),
                          fontWeight: FontWeight.w600,
                          color: colors.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
