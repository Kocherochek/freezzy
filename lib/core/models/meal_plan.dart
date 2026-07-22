// lib/core/models/meal_plan.dart
//
// Формула плана питания. MealPlanTemplate — это "рецепт" самого дня:
// какие приёмы пищи в нём есть (MealSlot) и какая роль нужна в каждом
// (MealComponentSlot). Пользователь может добавлять/убирать компоненты
// и целые приёмы пищи — просто редактируя эти списки.

import 'enums.dart';

/// Один "слот" внутри приёма пищи с конкретной требуемой ролью.
/// Например, слот с ролью protein внутри обеда.
class MealComponentSlot {
  final String id;
  final MenuRole role;

  MealComponentSlot({
    required this.id,
    required this.role,
  });
}

/// Приём пищи — Завтрак, Обед, Ужин или кастомный (например "Полдник").
/// name — обычная строка, а не enum, потому что пользователь может
/// добавить свой приём пищи с произвольным названием.
class MealSlot {
  final String id;
  final String name;
  final List<MealComponentSlot> components;

  MealSlot({
    required this.id,
    required this.name,
    required this.components,
  });
}

/// Сама формула плана питания целиком — предустановленная или кастомная.
class MealPlanTemplate {
  final String id;
  final String name; // "Завтрак + Обед + Ужин", "Суп + Горячее + Салат"
  final List<MealSlot> mealSlots;
  final bool isCustom;
  final String? basedOnPresetId; // если отредактировали готовый пресет

  MealPlanTemplate({
    required this.id,
    required this.name,
    required this.mealSlots,
    this.isCustom = false,
    this.basedOnPresetId,
  });
}