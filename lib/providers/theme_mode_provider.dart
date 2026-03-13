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
    if (saved == GameStorage.valueThemeLight) return ThemeMode.light;
    if (saved == GameStorage.valueThemeSystem) return ThemeMode.system;
    return ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final value = mode == ThemeMode.light
        ? GameStorage.valueThemeLight
        : mode == ThemeMode.system
            ? GameStorage.valueThemeSystem
            : GameStorage.valueThemeDark;
    GameStorage.saveThemeMode(value);
  }
}
