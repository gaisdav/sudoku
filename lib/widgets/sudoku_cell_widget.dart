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
    required this.onTap,
  });

  final int cellIndex;
  final SudokuCell cell;
  final bool isSelected;
  final bool isSameRowOrColumn;
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
    } else if (isSelected) {
      bg = lightBlue;
    } else if (isSameRowOrColumn) {
      bg = lightBlue.withValues(alpha: 0.5);
    }

    // Given numbers: black. User/hint: blue. Wrong: red.
    Color textColor = cell.isOriginal ? black : blue;
    if (cell.isWrong) textColor = Colors.red.shade700;

    final textStyle = TextStyle(
      fontSize: 20,
      fontWeight: cell.isOriginal ? FontWeight.w600 : FontWeight.normal,
      color: textColor,
    );

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(1),
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
      ),
    );
  }
}
