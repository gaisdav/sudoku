/// Single cell of the Sudoku board.
/// Empty cell: [value] == 0.
class SudokuCell {
  SudokuCell({
    required this.value,
    this.isOriginal = false,
    this.isHint = false,
    this.isWrong = false,
  });

  /// 0 = empty, 1-9 = digit
  final int value;

  /// Digit from generator — cannot be erased by player
  final bool isOriginal;

  /// Digit was filled via hint — highlight differently (e.g. blue)
  final bool isHint;

  /// Cell is invalid (duplicate in row/col/box) — highlight red
  final bool isWrong;

  bool get isEmpty => value == 0;

  SudokuCell copyWith({
    int? value,
    bool? isOriginal,
    bool? isHint,
    bool? isWrong,
  }) {
    return SudokuCell(
      value: value ?? this.value,
      isOriginal: isOriginal ?? this.isOriginal,
      isHint: isHint ?? this.isHint,
      isWrong: isWrong ?? this.isWrong,
    );
  }
}
