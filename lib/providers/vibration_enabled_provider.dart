import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_storage.dart';

/// Провайдер настройки «Включить/выключить вибрацию». Сохраняется в [GameStorage].
final vibrationEnabledProvider =
    NotifierProvider<VibrationEnabledNotifier, bool>(VibrationEnabledNotifier.new);

class VibrationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => GameStorage.loadVibrationEnabled();

  void setEnabled(bool enabled) {
    state = enabled;
    GameStorage.saveVibrationEnabled(enabled);
  }
}
