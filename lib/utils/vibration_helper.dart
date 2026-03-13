import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../services/game_storage.dart';

bool get _vibrationEnabled => GameStorage.loadVibrationEnabled();

/// Лёгкий тактильный отклик (если вибрация включена в настройках).
void hapticSelection() {
  if (_vibrationEnabled) HapticFeedback.selectionClick();
}

/// Лёгкий удар (если вибрация включена в настройках).
void hapticLightImpact() {
  if (_vibrationEnabled) HapticFeedback.lightImpact();
}

/// Тяжёлая неприятная вибрация при ошибке (неверная цифра). Учитывает настройку.
Future<void> vibrateOnError() async {
  if (!_vibrationEnabled) return;
  if (!(await Vibration.hasVibrator())) return;
  // Двойной жёсткий импульс: вибрация — пауза — более длинная вибрация
  await Vibration.vibrate(
    pattern: [0, 120, 60, 200],
  );
}

/// Ещё более тяжёлая вибрация при game over. Учитывает настройку.
Future<void> vibrateOnGameOver() async {
  if (!_vibrationEnabled) return;
  if (!(await Vibration.hasVibrator())) return;
  // Тройной длинный импульс
  await Vibration.vibrate(
    pattern: [0, 250, 100, 350, 100, 450],
  );
}
