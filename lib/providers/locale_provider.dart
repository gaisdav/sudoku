import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_storage.dart';

/// Selected app locale. Null = use system locale.
/// Persisted via [GameStorage].
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = GameStorage.loadLocale();
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  void setLocale(Locale? locale) {
    state = locale;
    GameStorage.saveLocale(locale?.languageCode);
  }
}
