import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sudoku_cell.dart';

class SudokuCellWidget extends StatelessWidget {
  const SudokuCellWidget({
    super.key,
    required this.cellIndex,
    required this.cell,
    this.notes = const {},
    this.isConflictFlash = false,
    this.showWrongHighlight = true,
    this.highlightDigit,
    required this.isSelected,
    required this.isSameRowOrColumn,
    this.isInCompleteRegion = false,
    this.isJustCompleted = false,
    required this.onTap,
  });

  final int cellIndex;
  final SudokuCell cell;
  /// Pencil marks (1-9) for this cell. Shown when cell is empty.
  final Set<int> notes;
  /// Red flash when user tried to add invalid note (conflict with original).
  final bool isConflictFlash;
  /// When false (e.g. Notes mode on Hard/Expert), wrong cells are not highlighted in red.
  final bool showWrongHighlight;
  /// Easy/Medium: digit to highlight (same as selected cell). All cells with this value get a light tint.
  final int? highlightDigit;
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
    if (isConflictFlash) {
      bg = errorRed.withValues(alpha: 0.5);
    } else if (showWrongHighlight && cell.isWrong) {
      bg = errorRed.withValues(alpha: 0.35);
    } else if (isJustCompleted) {
      // Приоритет: вспышка «область заполнена» поверх выбора и строки/столбца/блока
      bg = Colors.green.shade50;
    } else if (isSelected) {
      bg = lightBlue;
    } else if (highlightDigit != null && cell.value == highlightDigit) {
      // Easy/Medium: light highlight for all cells with the same digit as selected
      bg = Colors.green.shade50;
    } else if (isSameRowOrColumn) {
      bg = lightBlue.withValues(alpha: 0.5);
    } else if (isInCompleteRegion) {
      bg = Colors.grey.shade100;
    }

    // Given numbers: black. User/hint: blue. Wrong: red (only when showWrongHighlight).
    Color textColor = cell.isOriginal ? black : blue;
    if (showWrongHighlight && cell.isWrong) textColor = Colors.red.shade700;

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
            child: cell.value != 0
                ? TweenAnimationBuilder<double>(
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
                  )
                : notes.isEmpty
                    ? const SizedBox.shrink()
                    : _NotesGrid(notes: notes, cellSize: size),
          );
        },
      ),
    );
  }
}

/// Small digits 1-9 in 3×3 positions inside the cell (1 top-left, 2 top-center, ..., 9 bottom-right).
class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes, required this.cellSize});

  final Set<int> notes;
  final double cellSize;

  static const _positions = [
    Alignment(-1.0, -1.0), Alignment(0.0, -1.0), Alignment(1.0, -1.0),
    Alignment(-1.0, 0.0), Alignment(0.0, 0.0), Alignment(1.0, 0.0),
    Alignment(-1.0, 1.0), Alignment(0.0, 1.0), Alignment(1.0, 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    final fontSize = (cellSize / 3 * 0.7).clamp(8.0, 14.0);
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int n = 1; n <= 9; n++)
            if (notes.contains(n))
              Align(
                alignment: _positions[n - 1],
                child: Padding(
                  padding: EdgeInsets.all(cellSize * 0.04),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
