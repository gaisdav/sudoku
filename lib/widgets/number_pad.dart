
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/vibration_helper.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../config/app_colors.dart';
import '../providers/game_provider.dart';

/// Min/max side of each number-pad button so it scales on small and large screens (like the grid).
const _kMinButtonSize = 34.0;
const _kMaxButtonSize = 58.0;

/// When 5 buttons per row would be narrower than [_kMinButtonSize], use one row 1–9 (rectangular keys).
const _kCompactGap = 4.0;
const _kCompactRowHeight = 38.0;

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
    final canEdit =
        hasSelection && !state.isWon && !state.isTimedOut;
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
        final widthPerFive = (availableWidth - (countPerRow - 1) * gap) / countPerRow;
        final useCompactStrip = widthPerFive < _kMinButtonSize - 0.01;

        final colors = context.appColors;
        if (useCompactStrip) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            color: colors.background,
            child: Row(
              children: [
                for (int n = 1; n <= 9; n++) ...[
                  if (n > 1) const SizedBox(width: _kCompactGap),
                  Expanded(
                    child: _padCellStrip(
                      context,
                      n,
                      canEdit,
                      isNotesMode,
                      notifier,
                      state,
                      remaining?[n],
                      _kCompactRowHeight,
                      colors,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final buttonSize = widthPerFive.clamp(_kMinButtonSize, _kMaxButtonSize).floorToDouble();
        const padding = gap / 2;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
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

  Widget _padCellStrip(
    BuildContext context,
    int n,
    bool canEdit,
    bool isNotesMode,
    GameNotifier notifier,
    GameState state,
    int? remaining,
    double height,
    AppColors colors,
  ) {
    final digitEnabled = isNotesMode || remaining == null || remaining > 0;
    final isConflictFlash = state.conflictFlashDigit == n;
    return _NumButton(
      colors: colors,
      width: double.infinity,
      height: height,
      label: '$n',
      remainingAbove: remaining != null && remaining > 0 ? remaining : null,
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
    );
  }

}

class _NumButton extends StatelessWidget {
  const _NumButton({
    required this.colors,
    this.size = 52,
    this.width,
    this.height,
    this.label,
    this.icon,
    this.remaining,
    /// Remaining count above the digit (compact strip).
    this.remainingAbove,
    this.isConflictFlash = false,
    this.onPressed,
  });

  final AppColors colors;
  final double size;
  final double? width;
  final double? height;
  final String? label;
  final IconData? icon;
  /// Shown top-right on Easy/Medium when > 0 (how many of this digit left to place). Hidden in Notes mode.
  final int? remaining;
  final int? remainingAbove;
  /// Red flash when this digit was rejected as note (conflict with original).
  final bool isConflictFlash;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final w = width ?? size;
    final h = height ?? size;
    final ref = height ?? size;
    final fontSize = label != null
        ? (width != null && height != null
            ? (h * 0.38).clamp(14.0, 22.0)
            : (ref * 0.42).clamp(16.0, 28.0))
        : 16.0;
    final iconSize = (ref * 0.5).clamp(18.0, 28.0);
    final mainChild = label != null
        ? Text(
            label!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: enabled ? colors.textPrimary : colors.disabled,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        : Icon(
            icon,
            size: iconSize,
            color: enabled ? colors.textPrimary : colors.disabled,
          );

    final borderRadius = (ref * 0.23).clamp(6.0, 14.0);
    final borderColor = isConflictFlash ? colors.error : colors.border;
    final bgColor = isConflictFlash ? colors.errorLight : colors.surface;

    Widget content;
    if (remainingAbove != null) {
      final tiny = (h * 0.22).clamp(7.0, 11.0);
      content = FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$remainingAbove',
              style: TextStyle(
                fontSize: tiny,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: (h * 0.04).clamp(0.0, 3.0)),
            mainChild,
          ],
        ),
      );
    } else if (remaining != null) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: mainChild),
          Positioned(
            top: 2,
            right: 4,
            child: Text(
              '$remaining',
              style: TextStyle(
                fontSize: (ref * 0.21).clamp(9.0, 14.0),
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      );
    } else {
      content = mainChild;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: isConflictFlash ? 2 : 1),
          ),
          alignment: Alignment.center,
          padding: remainingAbove != null ? EdgeInsets.symmetric(vertical: (h * 0.06).clamp(1.0, 4.0)) : null,
          child: content,
        ),
      ),
    );
  }
}
