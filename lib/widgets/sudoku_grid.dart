import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import 'sudoku_cell_widget.dart';

/// Max side length of the grid in logical pixels (avoids huge grid on tablets).
const _kMaxGridSide = 420.0;

/// Gap between 3×3 blocks (replaces drawn lines).
const _blockGap = 10.0;
const _cellSpacing = 1.0;

class SudokuGrid extends ConsumerWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final selected = state.selectedCellIndex;
    final selectedRow = selected != null ? selected ~/ 9 : null;
    final selectedCol = selected != null ? selected % 9 : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 32.0;
        final availableWidth = (constraints.maxWidth - padding).clamp(0.0, double.infinity);
        final availableHeight = constraints.maxHeight.clamp(0.0, double.infinity);
        final gridSide = min(min(availableWidth, availableHeight), _kMaxGridSide);
        // 9 cells, 6 inner spacings (2 per block row), 2 block gaps: 9*cell + 6*_cellSpacing + 2*_blockGap = gridSide
        final cellSize = (gridSide - 6 * _cellSpacing - 2 * _blockGap) / 9;

        return Center(
          child: SizedBox(
            width: gridSide,
            height: gridSide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var br = 0; br < 3; br++) ...[
                  if (br > 0) const SizedBox(height: _blockGap),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var bc = 0; bc < 3; bc++) ...[
                        if (bc > 0) const SizedBox(width: _blockGap),
                        _BlockGrid(
                          blockRow: br,
                          blockCol: bc,
                          cellSize: cellSize,
                          state: state,
                          selectedRow: selectedRow,
                          selectedCol: selectedCol,
                          onSelectCell: (index) => ref.read(gameProvider.notifier).selectCell(
                                state.selectedCellIndex == index ? null : index,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BlockGrid extends StatelessWidget {
  const _BlockGrid({
    required this.blockRow,
    required this.blockCol,
    required this.cellSize,
    required this.state,
    required this.selectedRow,
    required this.selectedCol,
    required this.onSelectCell,
  });

  final int blockRow;
  final int blockCol;
  final double cellSize;
  final GameState state;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int index) onSelectCell;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < 3; r++) ...[
          if (r > 0) const SizedBox(height: _cellSpacing),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < 3; c++) ...[
                if (c > 0) const SizedBox(width: _cellSpacing),
                SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: _cell(
                    (blockRow * 3 + r) * 9 + (blockCol * 3 + c),
                    blockRow * 3 + r,
                    blockCol * 3 + c,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(int index, int row, int col) {
    final isSameRowOrCol = (selectedRow != null && row == selectedRow) ||
        (selectedCol != null && col == selectedCol);
    return SudokuCellWidget(
      cellIndex: index,
      cell: state.cellAt(index),
      isSelected: state.selectedCellIndex == index,
      isSameRowOrColumn: isSameRowOrCol,
      onTap: () => onSelectCell(index),
    );
  }
}
