# Sudoku (Flutter)

Mobile Sudoku app for Android and iOS. See [plan.md](plan.md) for the full roadmap.

## Stage 1 (MVP) — Implemented

- **Models:** `SudokuCell` (value, isOriginal, isHint, isWrong), 9×9 board as list of 81 cells
- **State:** `GameNotifier` (Riverpod) — generation via `sudoku_dart`, selection, input, validation, win check, `applyHint()`
- **UI:** Game screen with 9×9 grid, number pad 1–9, cell selection, clear cell, new game
- **Behaviour:** Wrong cells (duplicate in row/column/box) highlighted in red; win dialog on completion

## Stage 2 (UI & animations) — Implemented

- **AnimatedContainer** on cells for smooth selection/row/column highlight
- **Scale animation** (elastic) when a digit appears in a cell
- **CustomPainter** for bold 3×3 block borders
- **Haptic feedback** on cell tap, number pad, and hint button
- **Hint button** (lightbulb) in app bar — calls `applyHint()` (no ad yet)

## Stage 4 (Progress, difficulty, statistics) — Implemented

- **Difficulty:** Easy / Medium / Hard / Expert via `sudoku_dart` `Level`; choice when starting a new game (dialog).
- **Persistence (Hive):** Current game is saved (board, solution, difficulty, elapsed time); on launch, saved game is restored automatically so the player can continue.
- **Timer:** Elapsed time in seconds, shown in the app bar (mm:ss); stops when the game is won.
- **Statistics:** Total wins and best time per difficulty, stored in Hive; “Statistics” button in the app bar opens a dialog with the data.

## Run

From the project root (with Flutter installed):

```bash
flutter create . --project-name sudoku
flutter pub get
flutter run
```

Pick an Android or iOS device/emulator when prompted.

### Flutter not found (`command not found: flutter`)

**If Flutter is already installed** — add it to your PATH. In a terminal:

```bash
# Common install locations on macOS:
ls ~/flutter/bin/flutter
ls ~/development/flutter/bin/flutter
brew --prefix flutter 2>/dev/null
```

Once you find the folder that contains the `flutter` script (e.g. `~/flutter`), add this to `~/.zshrc`:

```bash
export PATH="$HOME/flutter/bin:$PATH"
```

Then run `source ~/.zshrc` or open a new terminal and try `flutter --version`.

**If Flutter is not installed** — install it from [flutter.dev](https://docs.flutter.dev/get-started/install) or with Homebrew: `brew install --cask flutter`.
