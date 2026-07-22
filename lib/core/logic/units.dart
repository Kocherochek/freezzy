// lib/core/logic/units.dart
//
// Нормализация единиц измерения. Проблема: рецепту нужно "500 г",
// а на складе может лежать "1 кг" и "200 г" — разные единицы одной
// величины (масса), которые нужно привести к общему виду перед
// сравнением. А "3 шт" и "150 г" сравнивать нельзя вообще — это
// разные измерения, и такое считаем ошибкой данных, а не поводом
// для конвертации.

import '../models/enums.dart';

enum UnitDimension { mass, volume, count }

UnitDimension dimensionOf(Unit unit) {
  switch (unit) {
    case Unit.grams:
    case Unit.kilograms:
      return UnitDimension.mass;
    case Unit.milliliters:
    case Unit.liters:
      return UnitDimension.volume;
    case Unit.pieces:
      return UnitDimension.count;
  }
}

/// Переводит количество в базовую единицу его измерения:
/// граммы для массы, миллилитры для объёма, штуки остаются штуками.
/// Все сравнения количества в приложении должны идти именно
/// через базовую единицу, а не напрямую в исходных unit.
double toBaseUnit(double quantity, Unit unit) {
  switch (unit) {
    case Unit.grams:
      return quantity;
    case Unit.kilograms:
      return quantity * 1000;
    case Unit.milliliters:
      return quantity;
    case Unit.liters:
      return quantity * 1000;
    case Unit.pieces:
      return quantity;
    case _:
      throw ArgumentError('Неизвестная единица измерения: $unit');
  }
}

/// Обратная операция к toBaseUnit — переводит количество из базовой
/// единицы измерения обратно в исходную (например, из граммов в кг,
/// если партия на складе хранится именно в кг). Нужна при списании:
/// считаем расход в базовых единицах, а сохраняем остаток в той же
/// единице, в которой партия была изначально.
double fromBaseUnit(double baseQuantity, Unit unit) {
  switch (unit) {
    case Unit.grams:
      return baseQuantity;
    case Unit.kilograms:
      return baseQuantity / 1000;
    case Unit.milliliters:
      return baseQuantity;
    case Unit.liters:
      return baseQuantity / 1000;
    case Unit.pieces:
      return baseQuantity;
    case _:
      throw ArgumentError('Неизвестная единица измерения: $unit');
  }
}

/// Кидается, если пытаемся сравнить величины разной размерности
/// (например, граммы и штуки). Это сигнал ошибки в данных рецепта
/// или продукта, а не то, что можно тихо посчитать "как-нибудь".
class IncompatibleUnitsException implements Exception {
  final Unit a;
  final Unit b;
  IncompatibleUnitsException(this.a, this.b);

  @override
  String toString() =>
      'Единицы $a и $b нельзя сравнивать — разные размерности величины';
}

void assertSameDimension(Unit a, Unit b) {
  if (dimensionOf(a) != dimensionOf(b)) {
    throw IncompatibleUnitsException(a, b);
  }
}