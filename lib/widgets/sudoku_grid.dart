import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../providers/game_provider.dart';
import 'sudoku_cell_widget.dart';

/// Max side length of the grid in logical pixels (avoids huge grid on tablets).
const _kMaxGridSide = 420.0;

/// Gap between 3×3 blocks (replaces drawn lines). Smaller = larger cells.
const _blockGap = 4.0;
const _cellSpacing = 0.5;

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
        const padding = 12.0;
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
    final isSameBlock = selectedRow != null &&
        selectedCol != null &&
        blockRow == selectedRow! ~/ 3 &&
        blockCol == selectedCol! ~/ 3;
    final isSameRowOrCol = state.difficulty != Level.expert &&
        ((selectedRow != null && row == selectedRow) ||
            (selectedCol != null && col == selectedCol) ||
            isSameBlock);
    final isInCompleteRegion = (state.difficulty == Level.easy ||
            state.difficulty == Level.medium) &&
        (state.isRowComplete(row) ||
            state.isColComplete(col) ||
            state.isBlockComplete(blockRow, blockCol));
    final justCompleted = state.justCompletedRegionIds;
    final isJustCompleted = justCompleted.contains('r:$row') ||
        justCompleted.contains('c:$col') ||
        justCompleted.contains('b:$blockRow:$blockCol');
    final cellNotes = state.cellNotes.length > index ? state.cellNotes[index] : <int>{};
    // Hard/Expert: hide error highlight in Notes mode to make it harder.
    final showWrongHighlight = !(state.isNotesMode &&
        (state.difficulty == Level.hard || state.difficulty == Level.expert));
    // Easy/Medium: highlight all cells with the same digit as the selected cell (or just placed).
    int? highlightDigit;
    if (state.difficulty == Level.easy || state.difficulty == Level.medium) {
      final sel = state.selectedCellIndex;
      if (sel != null) {
        final v = state.cells[sel].value;
        if (v >= 1 && v <= 9) highlightDigit = v;
      }
    }
    return SudokuCellWidget(
      cellIndex: index,
      cell: state.cellAt(index),
      notes: cellNotes,
      isConflictFlash: state.conflictFlashCellIndices.contains(index),
      showWrongHighlight: showWrongHighlight,
      highlightDigit: highlightDigit,
      isSelected: state.selectedCellIndex == index,
      isSameRowOrColumn: isSameRowOrCol,
      isInCompleteRegion: isInCompleteRegion,
      isJustCompleted: isJustCompleted,
      onTap: () => onSelectCell(index),
    );
  }
}
