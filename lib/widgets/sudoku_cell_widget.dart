import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sudoku_cell.dart';

class SudokuCellWidget extends StatelessWidget {
  const SudokuCellWidget({
    super.key,
    required this.cellIndex,
    required this.cell,
    required this.isSelected,
    required this.isSameRowOrColumn,
    this.isInCompleteRegion = false,
    this.isJustCompleted = false,
    required this.onTap,
  });

  final int cellIndex;
  final SudokuCell cell;
  final bool isSelected;
  final bool isSameRowOrColumn;
  /// True if this cell's row, column, or 3×3 block is fully filled (for subtle highlight).
  final bool isInCompleteRegion;
  /// True if this cell's region just became complete (soft flash animation).
  final bool isJustCompleted;
  final VoidCallback onTap;

  void _onTap() {
    HapticFeedback.selectionClick();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2196F3);
    const lightBlue = Color(0xFFE3F2FD);
    const black = Color(0xFF212121);
    const errorRed = Color(0xFFE57373);

    Color bg = Colors.white;
    if (cell.isWrong) {
      bg = errorRed.withValues(alpha: 0.35);
    } else if (isJustCompleted) {
      // Приоритет: вспышка «область заполнена» поверх выбора и строки/столбца/блока
      bg = Colors.green.shade50;
    } else if (isSelected) {
      bg = lightBlue;
    } else if (isSameRowOrColumn) {
      bg = lightBlue.withValues(alpha: 0.5);
    } else if (isInCompleteRegion) {
      bg = Colors.grey.shade100;
    }

    // Given numbers: black. User/hint: blue. Wrong: red.
    Color textColor = cell.isOriginal ? black : blue;
    if (cell.isWrong) textColor = Colors.red.shade700;

    return GestureDetector(
      onTap: _onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final fontSize = (size * 0.52).clamp(14.0, 28.0);
          final textStyle = TextStyle(
            fontSize: fontSize,
            fontWeight: cell.isOriginal ? FontWeight.w600 : FontWeight.normal,
            color: textColor,
          );
          return AnimatedContainer(
            duration: Duration(
                milliseconds: isInCompleteRegion ? 400 : 150),
            curve: Curves.easeOut,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(
                color: isSelected ? blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: cell.value == 0
                ? const SizedBox.shrink()
                : TweenAnimationBuilder<double>(
                    key: ValueKey('$cellIndex-${cell.value}'),
                    tween: Tween(begin: 0.4, end: 1.0),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Text('${cell.value}', style: textStyle),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
