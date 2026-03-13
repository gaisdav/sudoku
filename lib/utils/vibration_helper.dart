import 'package:vibration/vibration.dart';

/// Тяжёлая неприятная вибрация при ошибке (неверная цифра).
Future<void> vibrateOnError() async {
  if (!(await Vibration.hasVibrator())) return;
  // Двойной жёсткий импульс: вибрация — пауза — более длинная вибрация
  await Vibration.vibrate(
    pattern: [0, 120, 60, 200],
  );
}

/// Ещё более тяжёлая вибрация при game over.
Future<void> vibrateOnGameOver() async {
  if (!(await Vibration.hasVibrator())) return;
  // Тройной длинный импульс
  await Vibration.vibrate(
    pattern: [0, 250, 100, 350, 100, 450],
  );
}
