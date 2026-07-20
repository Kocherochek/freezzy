import 'package:flutter/material.dart';
class AppColors {
 // 1. Базовые цвета интерфейса
  static const Color background = Color(0xFFFDFBF7); // нежный теплый кремовый для фона
  static const Color surface = Color(0xFFFFFFFF); // чистый белый для плашек

  // Типографика и иконки
  static const Color textMain = Color(0xFF3E3835); // глубокий серо-коричневый для Н1
  static const Color textSecondary = Color(0xFF8A827E); // пастельный серый для неактивных элементов
  static const Color textMainButton = Color(0xFFFFFFFF); // для главных кнопок и FAB
  static const Color textWhite = Color(0xFFFFFFFF); // для чипсов статусов наличия

  // Кнопки и акцентные цвета
  static const Color accentMain = Color(0xFF9683B5); // лавандовый - акцентный на кнопках, текст - белый
  static const Color buttonText = textMainButton; // для главных кнопок и FAB
  static const Color accentSecondary = Color(0xFF4A7C7A); // Мягкий приглушенный эвкалипт - акцентный на второстепенных кнопках: обводка и текст
  static const Color shadowColor = Color(0xFF3E3835); // мягкая тень на основе умбры
  static const Color neonLimeShadow = Color(0xFF7FFFD4); // неоновая тень второстепенной кнопки

  // 2. Чипсы зоны хранения
  static const Color fridgeBg = Color(0xFFEFEBF5); // холодильник: бледно-лавандовый
  static const Color fridgeTxt = Color(0xFF9683B5); // холодильник: равен акцентному лавандовому
  static const Color freezerBg = Color(0xFFE3EAEF); // морозилка: холодный бледно-голубой
  static const Color freezerTxt = Color(0xFF708D9C); // морозилка: глубокий ледяной
  static const Color pantryBg = Color(0xFFEFEBE6); // шкаф: серо-бежевый
  static const Color pantryTxt = Color(0xFF8A827E); // шкаф: глубокий серо-коричневый

  // 3. Чипсы статус свежести
  static const Color statusFreshnessTxt = textMain; // единый темный цвет текста для свежести
  static const Color statusFresh = Color(0xFFE6E8DE); // бледно-зеленый
  static const Color statusNormal = Color(0xFFF5E6CC); // бледный песочный
  static const Color statusExpired = Color(0xFFF2D1C4); // бледный терракотовый

  // 4. Чипсы статус наличия
  static const Color statusActionTxt = textWhite; // единый белый цвет текста для экшн-чипсов
  static const Color actionInStock = Color(0xFF909577); // оливковый, в наличии
  static const Color actionDefrost = Color(0xFF708D9C); // французский синий, разморозить
  static const Color actionBuy = Color(0xFFD69A80); // кирпичный, купить

  // 5. Приемы пищи
  static const Color mealTxt = textMain; // единый цвет текста для категорий еды
  static const Color mealBreakfast = Color(0xFFF4E3B1); // завтрак, соломенный
  static const Color mealLunch = Color(0xFF909577); // обед, оливковый
  static const Color mealDinner = Color(0xFFD69A80); // ужин, терракотовый
  static const Color mealSnack = Color(0xFF9683B5); // перекус, лавандовый

  // Дополнительные цвета для кастомизации меню
  static const Color mealSage = Color(0xFFE3ECE7); // шалфейный
  static const Color mealRose = Color(0xFFF5E2DE); // пыльная роза
  static const Color mealCumin = Color(0xFFE6D8CE); // пряный кумин (бежевый)
  static const Color mealSky = Color(0xFFE2EDF0); // льняной голубой
  static const Color mealApricot = Color(0xFFF6E9DD); // персиковый
  static const Color mealWood = Color(0xFFE6DFD3); // древесно-льняной

  // 6. Баннеры для уведомлений
  static const Color bannerGreenBg = Color(0xFFEAEFE3); // нежно-мятный
  static const Color bannerGreenTxt = Color(0xFF909577); // оливковый текст
  static const Color bannerClay = Color(0xFFD69A80); // пастельно-терракотовый
  static const Color bannerClayTxt = textMain; // основной текст для красного баннера

  // 8. Системные цвета
  static const Color error = Color(0xFFD32F2F); // красный для критических ошибок

}