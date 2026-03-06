import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';
import '../models/sudoku_cell.dart';

const _omit = Object();

/// Game state: 81 cells (index 0..80), solution, selected index.
class GameState {
  const GameState({
    required this.cells,
    required this.solution,
    this.selectedCellIndex,
    this.isWon = false,
  });

  final List<SudokuCell> cells;
  final List<int> solution;
  final int? selectedCellIndex;
  final bool isWon;

  SudokuCell cellAt(int index) => cells[index];

  GameState copyWith({
    List<SudokuCell>? cells,
    List<int>? solution,
    Object? selectedCellIndex = _omit,
    bool? isWon,
  }) {
    return GameState(
      cells: cells ?? this.cells,
      solution: solution ?? this.solution,
      selectedCellIndex: identical(selectedCellIndex, _omit) ? this.selectedCellIndex : selectedCellIndex as int?,
      isWon: isWon ?? this.isWon,
    );
  }
}

/// Converts sudoku_dart puzzle (-1 = empty) to our cells (0 = empty).
List<SudokuCell> puzzleToCells(List<int> puzzle) {
  return puzzle.map((v) {
    final digit = v == -1 ? 0 : v;
    return SudokuCell(
      value: digit,
      isOriginal: digit != 0,
    );
  }).toList();
}

final _random = Random();

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(_initialState()) {
    _newGame();
  }

  static GameState _initialState() {
    final empty = List.generate(81, (_) => SudokuCell(value: 0));
    return GameState(cells: empty, solution: List.filled(81, 0));
  }

  void _newGame() {
    final sudoku = Sudoku.generate(Level.easy);
    final puzzle = sudoku.puzzle;
    if (puzzle.isEmpty) {
      state = _initialState();
      return;
    }
    final solution = sudoku.solution;
    if (solution.isEmpty) {
      state = _initialState();
      return;
    }
    state = GameState(
      cells: puzzleToCells(puzzle),
      solution: List<int>.from(solution),
      selectedCellIndex: null,
      isWon: false,
    );
    _revalidateWrong();
  }

  void selectCell(int? index) {
    if (state.isWon) return;
    state = state.copyWith(selectedCellIndex: index);
  }

  /// Sets digit in selected cell (or at index). Only editable non-original cells.
  void setCellValue(int digit) {
    if (state.isWon) return;
    final idx = state.selectedCellIndex;
    if (idx == null || digit < 1 || digit > 9) return;
    final cell = state.cells[idx];
    if (cell.isOriginal) return;

    final newCells = List<SudokuCell>.from(state.cells);
    newCells[idx] = cell.copyWith(value: digit, isHint: false);
    state = state.copyWith(cells: newCells);
    _revalidateWrong();
    _checkWin();
  }

  void clearCell() {
    if (state.isWon) return;
    final idx = state.selectedCellIndex;
    if (idx == null) return;
    final cell = state.cells[idx];
    if (cell.isOriginal) return;

    final newCells = List<SudokuCell>.from(state.cells);
    newCells[idx] = cell.copyWith(value: 0, isHint: false);
    state = state.copyWith(cells: newCells);
    _revalidateWrong();
  }

  void _revalidateWrong() {
    final newCells = List<SudokuCell>.from(state.cells);
    for (int i = 0; i < 81; i++) {
      final c = newCells[i];
      if (c.value == 0) {
        if (c.isWrong) newCells[i] = c.copyWith(isWrong: false);
        continue;
      }
      final wrong = _isCellWrong(i, newCells);
      if (c.isWrong != wrong) newCells[i] = c.copyWith(isWrong: wrong);
    }
    state = state.copyWith(cells: newCells);
  }

  bool _isCellWrong(int index, List<SudokuCell> cells) {
    final value = cells[index].value;
    if (value == 0) return false;
    final row = index ~/ 9;
    final col = index % 9;
    for (int i = 0; i < 9; i++) {
      final ri = row * 9 + i;
      if (ri != index && cells[ri].value == value) return true;
      final ci = i * 9 + col;
      if (ci != index && cells[ci].value == value) return true;
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final i = (br + r) * 9 + (bc + c);
        if (i != index && cells[i].value == value) return true;
      }
    }
    return false;
  }

  void _checkWin() {
    for (int i = 0; i < 81; i++) {
      final c = state.cells[i];
      if (c.value == 0 || c.isWrong) return;
    }
    state = state.copyWith(isWon: true);
  }

  /// Hint: fill selected cell with solution value, or a random empty cell.
  void applyHint() {
    if (state.isWon) return;
    int? target = state.selectedCellIndex;
    final cells = state.cells;

    if (target != null) {
      final cell = cells[target];
      if (!cell.isEmpty && !cell.isWrong) target = null;
    }
    if (target == null) {
      final empties = <int>[];
      for (int i = 0; i < 81; i++) {
        if (cells[i].isEmpty && !cells[i].isOriginal) empties.add(i);
      }
      if (empties.isEmpty) return;
      target = empties[_random.nextInt(empties.length)];
    }

    final solutionValue = state.solution[target];
    if (solutionValue < 1 || solutionValue > 9) return;

    final newCells = List<SudokuCell>.from(state.cells);
    newCells[target] = state.cells[target].copyWith(
      value: solutionValue,
      isHint: true,
    );
    state = state.copyWith(cells: newCells);
    _revalidateWrong();
    _checkWin();
  }

  void newGame() {
    _newGame();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
