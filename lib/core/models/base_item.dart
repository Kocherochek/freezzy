// lib/core/models/base_item.dart
//
// BaseItem — общий "шаблон" для БАЗОВОГО продукта или БАЗОВОЙ заготовки
// (например, "Молоко" или "Пельмени"). Это уровень справочника,
// на который ссылается рецепт — рецепту не важно, 3% молоко или 1.5%.
//
// abstract class означает, что мы никогда не создаём "просто BaseItem" —
// только его наследников BaseProduct или BasePrep. Зато код, которому
// не важно, продукт это или заготовка (например, конструктор меню),
// может работать с типом BaseItem и одинаково обращаться к обоим.

import 'enums.dart';

abstract class BaseItem {
  final String id;
  final String name; // "Молоко", "Пельмени"
  final String categoryId;
  final List<MenuRole> menuRoles; // множественный выбор: белок + завтрак и т.д.
  final StockingZone defaultZone;
  final Unit defaultUnit;
  final int? defaultShelfLifeDays; // подставляется, если юзер не указал срок годности сам
  final bool isCustom; // true, если добавлено пользователем, а не из справочника

  BaseItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.menuRoles,
    required this.defaultZone,
    required this.defaultUnit,
    this.defaultShelfLifeDays,
    this.isCustom = false,
  });
}

/// Базовый продукт, например "Молоко".
class BaseProduct extends BaseItem {
  final bool alwaysInStock; // соль, перец и т.п. — не нужно напоминать купить,
  // но можно вручную добавить в список покупок

  BaseProduct({
    required super.id,
    required super.name,
    required super.categoryId,
    required super.menuRoles,
    required super.defaultZone,
    required super.defaultUnit,
    super.defaultShelfLifeDays,
    super.isCustom = false,
    this.alwaysInStock = false,
  });
}

/// Базовая заготовка, например "Пельмени".
/// У заготовок нет alwaysInStock — по твоим словам, он им не нужен.
class BasePrep extends BaseItem {
  BasePrep({
    required super.id,
    required super.name,
    required super.categoryId,
    required super.menuRoles,
    required super.defaultZone,
    required super.defaultUnit,
    super.defaultShelfLifeDays,
    super.isCustom = false,
  });
}