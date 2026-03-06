import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import 'sudoku_cell_widget.dart';
import 'sudoku_grid_painter.dart';

/// Max side length of the grid in logical pixels (avoids huge grid on tablets).
const _kMaxGridSide = 420.0;

class SudokuGrid extends ConsumerWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    const spacing = 2.0;
    final selected = state.selectedCellIndex;
    final selectedRow = selected != null ? selected ~/ 9 : null;
    final selectedCol = selected != null ? selected % 9 : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 32.0;
        final availableWidth = (constraints.maxWidth - padding).clamp(0.0, double.infinity);
        final availableHeight = constraints.maxHeight.clamp(0.0, double.infinity);
        final gridSide = min(min(availableWidth, availableHeight), _kMaxGridSide);

        return Center(
          child: SizedBox(
            width: gridSide,
            height: gridSide,
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 9,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: 1,
                      ),
                      itemCount: 81,
                      itemBuilder: (context, index) {
                        final row = index ~/ 9;
                        final col = index % 9;
                        final isSameRowOrCol = (selectedRow != null && row == selectedRow) ||
                            (selectedCol != null && col == selectedCol);
                        return SudokuCellWidget(
                          cellIndex: index,
                          cell: state.cellAt(index),
                          isSelected: state.selectedCellIndex == index,
                          isSameRowOrColumn: isSameRowOrCol,
                          onTap: () => ref.read(gameProvider.notifier).selectCell(
                                state.selectedCellIndex == index ? null : index,
                              ),
                        );
                      },
                    );
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                    painter: SudokuGridPainter(
                      color: Colors.grey.shade400,
                      strokeWidth: 2.5,
                    ),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
