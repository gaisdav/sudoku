import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_storage.dart';

/// Провайдер темы приложения. По умолчанию тёмная тема.
/// Сохраняется в [GameStorage].
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = GameStorage.loadThemeMode();
    return saved == GameStorage.valueThemeLight ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    GameStorage.saveThemeMode(
      mode == ThemeMode.light ? GameStorage.valueThemeLight : GameStorage.valueThemeDark,
    );
  }

  void toggle() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
