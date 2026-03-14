// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Sudoku';

  @override
  String get menu => 'Menú';

  @override
  String get backToMenu => 'Volver al menú';

  @override
  String get game => 'Juego';

  @override
  String get newGame => 'Nueva partida';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get viewStatistics => 'Ver estadísticas';

  @override
  String get settings => 'Ajustes';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabInstructions => 'Instrucciones';

  @override
  String get instructionsTitle => 'Cómo jugar al Sudoku';

  @override
  String get instructionsBody =>
      'El Sudoku se juega en una cuadrícula de 9×9 dividida en nueve bloques de 3×3.\n\nObjetivo: Rellena la cuadrícula de modo que cada fila, cada columna y cada bloque 3×3 contenga los dígitos del 1 al 9, sin repetir.\n\nReglas:\n• Cada fila debe contener 1–9 exactamente una vez.\n• Cada columna debe contener 1–9 exactamente una vez.\n• Cada bloque 3×3 debe contener 1–9 exactamente una vez.\n\nAlgunas celdas vienen ya rellenadas; el resto se rellena con lógica. Cada puzzle tiene una única solución correcta.';

  @override
  String get levelEasy => 'Fácil';

  @override
  String get levelMedium => 'Medio';

  @override
  String get levelHard => 'Difícil';

  @override
  String get levelExpert => 'Experto';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageRussian => 'Ruso';

  @override
  String get languageSpanish => 'Español';

  @override
  String get vibration => 'Vibración';

  @override
  String get vibrationSubtitle =>
      'Retroalimentación táctil al tocar celdas y botones';

  @override
  String get continueGame => 'Continuar';

  @override
  String savedTodayAt(String time) {
    return 'Guardado hoy a las $time';
  }

  @override
  String savedYesterdayAt(String time) {
    return 'Guardado ayer a las $time';
  }

  @override
  String savedOn(String date) {
    return 'Guardado el $date';
  }

  @override
  String get youWon => '¡Ganaste!';

  @override
  String get congratulations => 'Enhorabuena, completaste el puzzle.';

  @override
  String timeLabel(String time) {
    return 'Tiempo: $time';
  }

  @override
  String hintsUsedLabel(int count) {
    return 'Pistas usadas: $count';
  }

  @override
  String get newRecord => '¡Nuevo récord!';

  @override
  String slowerThanBest(String duration) {
    return '$duration más lento que tu mejor';
  }

  @override
  String get loadingAd => 'Cargando anuncio…';

  @override
  String get noErrorsMode => 'Modo sin errores';

  @override
  String get noErrorsModeAlreadyOn =>
      'El modo sin errores ya está activo. Las celdas incorrectas se marcan en rojo pero la partida no terminará por exceso de errores.';

  @override
  String get noErrorsModeDescription =>
      'En este modo las celdas incorrectas se marcan en rojo pero la partida no terminará por exceso de errores.\n\nPara activarlo en esta sesión, mira 3 anuncios seguidos. El temporizador está pausado.';

  @override
  String get watch3Ads => 'Ver 3 anuncios';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String adProgress(int current) {
    return 'Anuncio $current/3…';
  }

  @override
  String get gameOver => 'Partida terminada';

  @override
  String get gameOverDescription =>
      'Has superado el número permitido de errores para esta dificultad.';

  @override
  String get adNotAvailableSecondChance =>
      'Anuncio no disponible. Segunda oportunidad aplicada.';

  @override
  String get secondChanceAd => 'Segunda oportunidad (anuncio)';

  @override
  String get restart => 'Reiniciar';

  @override
  String get noErrors => 'Sin errores';

  @override
  String get undo => 'Deshacer';

  @override
  String get notes => 'Notas';

  @override
  String get hint => 'Pista';

  @override
  String get adBadge => 'Anun.';

  @override
  String get adNotAvailableHintApplied =>
      'Anuncio no disponible. Pista aplicada.';

  @override
  String get adNotAvailableUndoApplied =>
      'Anuncio no disponible. Deshacer aplicado.';

  @override
  String get chooseDifficulty => 'Elige la dificultad:';

  @override
  String totalWinsWithCount(int count) {
    return 'Total de victorias: $count';
  }

  @override
  String get bestTimeByDifficulty => 'Mejor tiempo por dificultad:';

  @override
  String bestTimeLine(String level, String time, int hints) {
    return '$level: $time ($hints pistas)';
  }

  @override
  String bestTimeLineNoRecord(String level) {
    return '$level: —';
  }

  @override
  String get resetStatisticsConfirmTitle => '¿Restablecer estadísticas?';

  @override
  String get resetStatisticsConfirmMessage =>
      'Se borrarán todas las victorias y mejores tiempos. No se puede deshacer.';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetStatistics => 'Restablecer estadísticas';

  @override
  String get lightTheme => 'Tema claro';

  @override
  String get darkTheme => 'Tema oscuro';

  @override
  String get followSystem => 'Según el sistema';
}
