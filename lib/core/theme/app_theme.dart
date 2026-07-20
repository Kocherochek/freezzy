import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';

class AppTheme {
  // Следующая строка закрывает конструктор. Это значит, что класс содержит только статические свойства.
  // Так как все данные статические, они привязаны к самому классу, а не к его объектам.
  // Закрытый конструктор запрещает создавать объекты на основе данного класса, тем самым экономя память.
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // настройка основной палитры для системных виджетов flutter
      colorScheme: const ColorScheme.light(
        surface: AppColors.background,
        surfaceContainer: AppColors.surface,
        primary: AppColors.accentMain,
        secondary: AppColors.accentSecondary,
        error: AppColors.error,
        onSurface: AppColors.textMain,
        onPrimary: AppColors.buttonText,
        onSecondary: AppColors.accentSecondary,
        shadow: AppColors.shadowColor,
      ),

      // Применяем базовый цвет фона для всех экранов
      scaffoldBackgroundColor: AppColors.background,

      // Настройка глобальной типографики приложения
      textTheme: const TextTheme(
        displayLarge: AppTypography.h1, // для самых крупных заголовков
        headlineLarge: AppTypography.h1, // связываем h1 с крупными хедерами
        headlineMedium: AppTypography.h2, // подзаголовки h2
        bodyLarge: AppTypography.body, // Основной текст
        bodyMedium: AppTypography.body, // Альтернативный основной текст
        labelLarge: AppTypography.button, // Большие кнопки
        labelSmall: AppTypography.buttonSmall, // Маленькие кнопки
        labelMedium: AppTypography.chips, // чипсы        
      ),

      // Настройка главной кнопки - лавандовый
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(AppTypography.button),
          shape: WidgetStatePropertyAll(
            StadiumBorder(),
          ),
          // Логика смены цвета кнопки в зависимости от состояния
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.accentMain.withValues(alpha: 0.3); // блеклый цвет текста для неактивной кнопки
            }
            return AppColors.accentMain; // Лавандовый по умолчанию
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSecondary; // серый цвет для неактивной кнопки
            }
            return AppColors.textMainButton; // белый текст по умолчанию
          }),

          // Логика смены тени в зависимости от состояния
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.disabled)) {
              return 0.0; // неактивная кнопка без тени
            }
            if (states.contains(WidgetState.pressed)) {
              return 2.0; // при нажатии кнопка визуально "прижимается" к экрану
            }
            return 6.0; // Базовая высота тени
          }),

          // Управление цветом тени
          shadowColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent; // Отключенная кнопка - прозрачная тень
            }
            return Color(0xFFB57EDC).withValues(alpha: 0.6);
          }),
        ), 
      ),

      // Второстепенная кнопка - оливковая обводка и текст
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(AppTypography.button),
          shape: WidgetStateProperty.all(
            StadiumBorder(),
          ),
           // Логика смены цвета кнопки в зависимости от состояния
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSecondary; // серый цвет для неактивной кнопки
            }
            return AppColors.accentSecondary;
          }),
          side: WidgetStateProperty.all(BorderSide(
            color: AppColors.accentSecondary,
            width: 3.0,
          )),
          
          // Логика смены тени в зависимости от состояния
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.disabled)) {
              return 0.0; // неактивная кнопка без тени
            }
            if (states.contains(WidgetState.pressed)) {
              return 2.0; // при нажатии кнопка визуально "прижимается" к экрану
            }
            return 6.0; // Базовая высота тени
          }),

          // Управление цветом тени
          shadowColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent; // Отключенная кнопка - прозрачная тень
            }
            return Color(0xFF39FF14).withValues(alpha: 0.2);
          }),
        ),
      ),

      // Настройка Floating Action Button (FAB) — круглой кнопки быстрого добавления
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentMain,
        foregroundColor: AppColors.textMainButton,
        shape: CircleBorder(),
        elevation: 4.0,
      ),

      // Настройка полей ввода (TextField) для поисковой строки и инпутов
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: AppTypography.searchHint,
        fillColor: AppColors.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.accentMain, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }}