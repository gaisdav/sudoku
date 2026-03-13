import 'package:flutter/material.dart';

/// Палитра цветов приложения. Все цвета берутся только отсюда.
/// В будущем: светлая и тёмная темы — два набора значений (light / dark).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryLight,
    required this.surface,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textMutedDark,
    required this.border,
    required this.borderSubtle,
    required this.disabled,
    required this.error,
    required this.errorLight,
    required this.errorDark,
    required this.successLight,
    required this.cellRegionComplete,
    required this.chipBackground,
    required this.conflictFlashBorder,
    required this.conflictFlashBackground,
  });

  /// Основной акцент (кнопки, выбранная ячейка, таймер).
  final Color primary;

  /// Светлый фон выделения (выбранная ячейка, тот же цифра).
  final Color primaryLight;

  /// Фон карточек, кнопок, таймера.
  final Color surface;

  /// Фон экрана (scaffold), блока с цифровой клавиатурой.
  final Color background;

  /// Текст оригинальных цифр (данные из головоломки).
  final Color textPrimary;

  /// Основной вторичный текст (сложность, ошибки, подписи кнопок).
  final Color textSecondary;

  /// Приглушённый текст/иконки (остаток цифр, иконка часов).
  final Color textMuted;

  /// Более тёмный приглушённый (заметки в ячейке, иконки).
  final Color textMutedDark;

  /// Границы ячеек, кнопок, таймера.
  final Color border;

  /// Светлая граница (чип сворачивания баннера).
  final Color borderSubtle;

  /// Неактивные элементы (disabled кнопки, иконки).
  final Color disabled;

  /// Ошибка: граница конфликта, красная подсветка.
  final Color error;

  /// Светлый фон при конфликте/ошибке.
  final Color errorLight;

  /// Текст/число ошибок при достижении лимита.
  final Color errorDark;

  /// Фон «успех»: заполненная область, та же цифра.
  final Color successLight;

  /// Фон ячейки в заполненной области (ряд/столбец/блок).
  final Color cellRegionComplete;

  /// Фон чипа (свернуть баннер).
  final Color chipBackground;

  /// Граница при конфликте (вспышка).
  final Color conflictFlashBorder;

  /// Фон при конфликте (вспышка).
  final Color conflictFlashBackground;

  /// Светлая тема (текущие значения из приложения).
  static const AppColors light = AppColors(
    primary: Color(0xFF2196F3),
    primaryLight: Color(0xFFE3F2FD),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFFAFAFA), // grey.shade50
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF424242), // grey.shade800
    textMuted: Color(0xFF757575),     // grey.shade600
    textMutedDark: Color(0xFF616161), // grey.shade700
    border: Color(0xFFE0E0E0),       // grey.shade300
    borderSubtle: Color(0xFFEEEEEE), // grey.shade200
    disabled: Color(0xFFBDBDBD),     // grey.shade400
    error: Color(0xFFE57373),
    errorLight: Color(0xFFFFEBEE),   // red.shade50
    errorDark: Color(0xFFC62828),    // red.shade700
    successLight: Color(0xFFE8F5E9), // green.shade50
    cellRegionComplete: Color(0xFFF5F5F5), // grey.shade100
    chipBackground: Color(0xFFEEEEEE),     // grey.shade200
    conflictFlashBorder: Color(0xFFF44336),
    conflictFlashBackground: Color(0xFFFFEBEE),
  );

  /// Тёмная тема — заглушка на будущее (при переключении на darkTheme подставится автоматически).
  static const AppColors dark = AppColors(
    primary: Color(0xFF2196F3),
    primaryLight: Color(0xFF1E3A5F),
    surface: Color(0xFF2D2D2D),
    background: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFFBDBDBD),
    textMuted: Color(0xFF9E9E9E),
    textMutedDark: Color(0xFF757575),
    border: Color(0xFF424242),
    borderSubtle: Color(0xFF616161),
    disabled: Color(0xFF616161),
    error: Color(0xFFEF9A9A),
    errorLight: Color(0xFF4A2C2C),
    errorDark: Color(0xFFEF5350),
    successLight: Color(0xFF2E4A2E),
    cellRegionComplete: Color(0xFF383838),
    chipBackground: Color(0xFF424242),
    conflictFlashBorder: Color(0xFFEF5350),
    conflictFlashBackground: Color(0xFF4A2C2C),
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? primary,
    Color? primaryLight,
    Color? surface,
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textMutedDark,
    Color? border,
    Color? borderSubtle,
    Color? disabled,
    Color? error,
    Color? errorLight,
    Color? errorDark,
    Color? successLight,
    Color? cellRegionComplete,
    Color? chipBackground,
    Color? conflictFlashBorder,
    Color? conflictFlashBackground,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textMutedDark: textMutedDark ?? this.textMutedDark,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      disabled: disabled ?? this.disabled,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      errorDark: errorDark ?? this.errorDark,
      successLight: successLight ?? this.successLight,
      cellRegionComplete: cellRegionComplete ?? this.cellRegionComplete,
      chipBackground: chipBackground ?? this.chipBackground,
      conflictFlashBorder: conflictFlashBorder ?? this.conflictFlashBorder,
      conflictFlashBackground: conflictFlashBackground ?? this.conflictFlashBackground,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    covariant ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textMutedDark: Color.lerp(textMutedDark, other.textMutedDark, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      cellRegionComplete: Color.lerp(cellRegionComplete, other.cellRegionComplete, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      conflictFlashBorder: Color.lerp(conflictFlashBorder, other.conflictFlashBorder, t)!,
      conflictFlashBackground: Color.lerp(conflictFlashBackground, other.conflictFlashBackground, t)!,
    );
  }
}

/// Доступ к палитре цветов приложения из [BuildContext].
extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
