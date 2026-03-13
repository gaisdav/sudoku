import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_storage.dart';

/// Индексы соответствуют [accentColorOptions].
final accentIndexProvider =
    NotifierProvider<AccentIndexNotifier, int>(AccentIndexNotifier.new);

/// Пресеты акцентных цветов (светлая тема). Для тёмной темы тот же оттенок используется в тёмной палитре.
const List<Color> accentColorOptions = [
  Color(0xFF2196F3), // Blue (default)
  Color(0xFF4CAF50), // Green
  Color(0xFF9C27B0), // Purple
  Color(0xFFFF9800), // Orange
  Color(0xFF009688), // Teal
  Color(0xFFE91E63), // Pink
];

class AccentIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return GameStorage.loadAccentIndex().clamp(0, accentColorOptions.length - 1);
  }

  void setAccentIndex(int index) {
    state = index.clamp(0, accentColorOptions.length - 1);
    GameStorage.saveAccentIndex(state);
  }
}
