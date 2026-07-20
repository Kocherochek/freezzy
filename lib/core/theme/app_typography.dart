import 'package:flutter/material.dart';
class AppTypography {
  // Заголовки Lora
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Lora',
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'Lora',
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
  );

  // Основной интерфейс
  static const TextStyle body = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle chips = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle searchHint = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14.0,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
  );
}