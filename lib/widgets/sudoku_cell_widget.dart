import 'package:flutter/material.dart';
import '../models/sudoku_cell.dart';

class SudokuCellWidget extends StatelessWidget {
  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.onTap,
  });

  final SudokuCell cell;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color bg = colorScheme.surface;
    if (cell.isWrong) {
      bg = colorScheme.errorContainer.withValues(alpha: 0.5);
    } else if (cell.isHint) {
      bg = colorScheme.primaryContainer.withValues(alpha: 0.4);
    }
    if (isSelected) {
      bg = colorScheme.primaryContainer;
    }

    TextStyle textStyle = TextStyle(
      fontSize: 20,
      fontWeight: cell.isOriginal ? FontWeight.bold : FontWeight.normal,
      color: cell.isOriginal
          ? colorScheme.onSurface
          : cell.isHint
              ? colorScheme.primary
              : colorScheme.onSurface,
    );
    if (cell.isWrong) {
      textStyle = textStyle.copyWith(color: colorScheme.error);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          cell.value == 0 ? '' : '${cell.value}',
          style: textStyle,
        ),
      ),
    );
  }
}
