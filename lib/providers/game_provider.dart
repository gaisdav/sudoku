import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../models/sudoku_cell.dart';
import '../services/game_storage.dart';

const _omit = Object();

/// Game state: 81 cells (index 0..80), solution, selected index, difficulty, timer, hints.
class GameState {
  const GameState({
    required this.cells,
    required this.solution,
    this.selectedCellIndex,
    this.isWon = false,
    this.difficulty = Level.easy,
    this.elapsedSeconds = 0,
    this.hintsUsedThisGame = 0,
    this.gameOverDialogShown = false,
    this.errorsMade = 0,
    this.justCompletedRegionIds = const {},
  });

  final List<SudokuCell> cells;
  final List<int> solution;
  final int? selectedCellIndex;
  final bool isWon;
  final Level difficulty;
  final int elapsedSeconds;
  final int hintsUsedThisGame;
  final bool gameOverDialogShown;
  /// Cumulative count of wrong entries this game (incremented once per wrong digit entered, never decreased).
  final int errorsMade;
  /// Region ids ('r:0', 'c:1', 'b:0:1') that just became complete (for fill animation). Cleared after ~400ms.
  final Set<String> justCompletedRegionIds;

  SudokuCell cellAt(int index) => cells[index];

  bool get isInitial => solution.every((v) => v == 0);

  /// Max free hints per difficulty (Easy 3, Medium 2, Hard 1, Expert 0). Rest require ad.
  int get maxFreeHints => switch (difficulty) {
        Level.easy => 3,
        Level.medium => 2,
        Level.hard => 1,
        Level.expert => 0,
      };

  /// How many free hints are left this game.
  int get freeHintsLeft => (maxFreeHints - hintsUsedThisGame).clamp(0, maxFreeHints);

  /// Max allowed errors before game over (Easy 3, Medium 2, Hard 1, Expert 0).
  int get maxErrors => switch (difficulty) {
        Level.easy => 3,
        Level.medium => 2,
        Level.hard => 1,
        Level.expert => 0,
      };

  /// True if all 9 cells in this row have a value (filled).
  bool isRowComplete(int row) {
    for (int c = 0; c < 9; c++) {
      if (cells[row * 9 + c].value == 0) return false;
    }
    return true;
  }

  /// True if all 9 cells in this column have a value (filled).
  bool isColComplete(int col) {
    for (int r = 0; r < 9; r++) {
      if (cells[r * 9 + col].value == 0) return false;
    }
    return true;
  }

  /// True if all 9 cells in this 3×3 block have a value (filled). [blockRow], [blockCol] in 0..2.
  bool isBlockComplete(int blockRow, int blockCol) {
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final i = (blockRow * 3 + r) * 9 + (blockCol * 3 + c);
        if (cells[i].value == 0) return false;
      }
    }
    return true;
  }

  GameState copyWith({
    List<SudokuCell>? cells,
    List<int>? solution,
    Object? selectedCellIndex = _omit,
    bool? isWon,
    Level? difficulty,
    int? elapsedSeconds,
    int? hintsUsedThisGame,
    bool? gameOverDialogShown,
    int? errorsMade,
    Set<String>? justCompletedRegionIds,
  }) {
    return GameState(
      cells: cells ?? this.cells,
      solution: solution ?? this.solution,
      selectedCellIndex: identical(selectedCellIndex, _omit) ? this.selectedCellIndex : selectedCellIndex as int?,
      isWon: isWon ?? this.isWon,
      difficulty: difficulty ?? this.difficulty,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hintsUsedThisGame: hintsUsedThisGame ?? this.hintsUsedThisGame,
      gameOverDialogShown: gameOverDialogShown ?? this.gameOverDialogShown,
      errorsMade: errorsMade ?? this.errorsMade,
      justCompletedRegionIds: justCompletedRegionIds ?? this.justCompletedRegionIds,
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
  GameNotifier() : super(_initialState());

  Timer? _timer;
  Timer? _justCompletedTimer;

  static Set<String> _completeRegionIds(GameState s) {
    final set = <String>{};
    for (int r = 0; r < 9; r++) {
      if (s.isRowComplete(r)) set.add('r:$r');
    }
    for (int c = 0; c < 9; c++) {
      if (s.isColComplete(c)) set.add('c:$c');
    }
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        if (s.isBlockComplete(br, bc)) set.add('b:$br:$bc');
      }
    }
    return set;
  }

  void _scheduleClearJustCompleted() {
    _justCompletedTimer?.cancel();
    _justCompletedTimer = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(justCompletedRegionIds: {});
      _justCompletedTimer = null;
    });
  }

  /// Двойной лёгкий отклик при заполнении строки/столбца/блока — ощущается чуть длиннее.
  void _triggerRegionCompleteHaptic() {
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 60), () {
      HapticFeedback.lightImpact();
    });
  }

  static GameState _initialState() {
    final empty = List.generate(81, (_) => SudokuCell(value: 0));
    return GameState(cells: empty, solution: List.filled(81, 0));
  }

  /// Call once after storage is ready. Loads saved game or starts new with [level].
  /// When returning to an already loaded game (Continue), restarts the timer if game not won.
  void ensureGameStarted([Level level = Level.easy]) {
    if (!state.isInitial) {
      if (!state.isWon) _startTimer();
      return;
    }
    final saved = GameStorage.loadGame();
    if (saved != null) {
      _restoreGame(saved);
      _startTimer();
      return;
    }
    newGame(level);
  }

  void _restoreGame(Map<String, dynamic> data) {
    try {
      final list = data[GameStorage.keyCellValues] as List?;
      final origList = data[GameStorage.keyCellIsOriginal] as List?;
      final solList = data[GameStorage.keySolution] as List?;
      final elapsed = (data[GameStorage.keyElapsedSeconds] as num?)?.toInt() ?? 0;
      final diffIndex = (data[GameStorage.keyDifficulty] as num?)?.toInt() ?? 0;
      final level = Level.values[diffIndex.clamp(0, Level.values.length - 1)];
      if (list == null || list.length != 81 || solList == null || solList.length != 81) return;
      final cells = <SudokuCell>[];
      for (int i = 0; i < 81; i++) {
        final v = (list[i] as num).toInt();
        final orig = origList != null && i < origList.length ? (origList[i] as bool) : (v != 0);
        cells.add(SudokuCell(value: v == -1 ? 0 : v, isOriginal: orig));
      }
      final solution = solList.map((e) => (e as num).toInt()).toList();
      final hintsUsed = (data[GameStorage.keyHintsUsedThisGame] as num?)?.toInt() ?? 0;
      final errorsMade = (data[GameStorage.keyErrorsMade] as num?)?.toInt() ?? 0;
      state = GameState(
        cells: cells,
        solution: solution,
        selectedCellIndex: null,
        isWon: false,
        difficulty: level,
        elapsedSeconds: elapsed,
        hintsUsedThisGame: hintsUsed,
        errorsMade: errorsMade,
      );
      _revalidateWrong();
    } catch (_) {
      newGame(Level.easy);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isWon) {
        _timer?.cancel();
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      _persistGame();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Stops the timer and saves current game when leaving the game screen (e.g. back to menu).
  void pauseTimer() {
    _persistGame();
    _stopTimer();
  }

  /// Pause timer when app is backgrounded (e.g. home button, switch app). Saves current state.
  void onAppPaused() {
    _stopTimer();
    _persistGame();
  }

  /// Resume timer when app is foregrounded, if game is in progress and not won.
  void onAppResumed() {
    if (!state.isWon && !state.isInitial) _startTimer();
  }

  /// Ends the game and clears saved data (e.g. after Game Over → Back to menu). Continue will no longer restore this game.
  Future<void> endGameAndClearSave() async {
    _stopTimer();
    await GameStorage.saveGame(null);
  }

  Future<void> _persistGame() async {
    if (state.isWon || state.isInitial) return;
    final data = {
      GameStorage.keyDifficulty: state.difficulty.index,
      GameStorage.keyCellValues: state.cells.map((c) => c.value).toList(),
      GameStorage.keyCellIsOriginal: state.cells.map((c) => c.isOriginal).toList(),
      GameStorage.keySolution: state.solution,
      GameStorage.keyElapsedSeconds: state.elapsedSeconds,
      GameStorage.keyHintsUsedThisGame: state.hintsUsedThisGame,
      GameStorage.keyErrorsMade: state.errorsMade,
    };
    await GameStorage.saveGame(data);
  }

  void _newGame(Level level) {
    _stopTimer();
    final sudoku = Sudoku.generate(level);
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
      difficulty: level,
      elapsedSeconds: 0,
      hintsUsedThisGame: 0,
      errorsMade: 0,
    );
    _revalidateWrong();
    _startTimer();
    _persistGame();
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

    final previousComplete = _completeRegionIds(state);
    final newCells = List<SudokuCell>.from(state.cells);
    newCells[idx] = cell.copyWith(value: digit, isHint: false);
    state = state.copyWith(cells: newCells);
    _revalidateWrong();
    if (state.cells[idx].isWrong) {
      state = state.copyWith(errorsMade: state.errorsMade + 1);
    }
    final newComplete = _completeRegionIds(state);
    final justCompleted = newComplete.difference(previousComplete);
    if (justCompleted.isNotEmpty) {
      state = state.copyWith(justCompletedRegionIds: justCompleted);
      _scheduleClearJustCompleted();
      _triggerRegionCompleteHaptic();
    }
    _persistGame();
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
    _persistGame();
  }

  /// Clears all wrong cells (non-original) to give a "second chance" after watching ad.
  void clearWrongCells() {
    if (state.isWon) return;
    final newCells = <SudokuCell>[];
    for (final c in state.cells) {
      if (c.isWrong && !c.isOriginal) {
        newCells.add(c.copyWith(value: 0, isHint: false, isWrong: false));
      } else {
        newCells.add(c);
      }
    }
    state = state.copyWith(cells: newCells);
    _revalidateWrong();
    _persistGame();
  }

  void markGameOverDialogShown() {
    state = state.copyWith(gameOverDialogShown: true);
    _persistGame();
  }

  void resetGameOverDialogShown() {
    state = state.copyWith(gameOverDialogShown: false);
    _persistGame();
  }

  /// For "second chance (Ad)": forgive one error so the counter goes down by 1.
  void forgiveLastError() {
    if (state.errorsMade <= 0) return;
    state = state.copyWith(errorsMade: state.errorsMade - 1);
    _persistGame();
  }

  /// Resets error counter to 0 (used when giving second chance after ad).
  void resetErrors() {
    if (state.errorsMade == 0) return;
    state = state.copyWith(errorsMade: 0);
    _persistGame();
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

  /// Hint: uses one free hint if any left, else returns false (UI shows "watch ad", then call applyHintFromAd).
  bool applyHint() {
    if (state.isWon) return false;
    if (state.freeHintsLeft <= 0) return false;
    return applyHintFromAd();
  }

  /// Hint after watching ad (or for free when freeHintsLeft > 0). Always applies if game not won.
  bool applyHintFromAd() {
    if (state.isWon) return false;
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
      if (empties.isEmpty) return false;
      target = empties[_random.nextInt(empties.length)];
    }

    final solutionValue = state.solution[target];
    if (solutionValue < 1 || solutionValue > 9) return false;

    final previousComplete = _completeRegionIds(state);
    final newCells = List<SudokuCell>.from(state.cells);
    newCells[target] = state.cells[target].copyWith(
      value: solutionValue,
      isHint: true,
    );
    state = state.copyWith(
      cells: newCells,
      hintsUsedThisGame: state.hintsUsedThisGame + 1,
    );
    _revalidateWrong();
    final newComplete = _completeRegionIds(state);
    final justCompleted = newComplete.difference(previousComplete);
    if (justCompleted.isNotEmpty) {
      state = state.copyWith(justCompletedRegionIds: justCompleted);
      _scheduleClearJustCompleted();
      _triggerRegionCompleteHaptic();
    }
    _persistGame();
    _checkWin();
    return true;
  }

  void _checkWin() {
    for (int i = 0; i < 81; i++) {
      final c = state.cells[i];
      if (c.value == 0 || c.isWrong) return;
    }
    _stopTimer();
    state = state.copyWith(isWon: true);
    _persistStats();
    GameStorage.saveGame(null);
  }

  Future<void> _persistStats() async {
    final totalWins = GameStorage.loadTotalWins() + 1;
    final bestByLevel = Map<int, int>.from(GameStorage.loadBestTimeByLevel());
    final bestHintsByLevel = Map<int, int>.from(GameStorage.loadBestTimeHintsByLevel());
    final levelIndex = state.difficulty.index;
    final current = state.elapsedSeconds;
    final prev = bestByLevel[levelIndex];
    if (prev == null || current < prev) {
      bestByLevel[levelIndex] = current;
      bestHintsByLevel[levelIndex] = state.hintsUsedThisGame;
    }
    await GameStorage.saveStats(
      totalWins: totalWins,
      bestTimeByLevel: bestByLevel,
      bestTimeHintsByLevel: bestHintsByLevel,
    );
  }

  void newGame([Level? level]) {
    _newGame(level ?? state.difficulty);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
