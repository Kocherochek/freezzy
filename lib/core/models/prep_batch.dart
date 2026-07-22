// lib/core/models/prep_batch.dart
//
// Отдельная, более простая генерация — специально для рецептов заготовок
// (RecipeType.prep). В отличие от GeneratedMenu, здесь НЕТ mealSlotId/
// componentSlotId — заготовки не привязаны к ролям приёма пищи, это
// просто список "что хочу наготовить сегодня".

class PrepBatchDish {
  final String id;
  final String recipeId;
  bool isPinned; // сохраняется при перегенерации, как и в обычном меню

  PrepBatchDish({
    required this.id,
    required this.recipeId,
    this.isPinned = false,
  });
}

class GeneratedPrepBatch {
  final String id;
  final DateTime date;
  final List<PrepBatchDish> dishes;

  GeneratedPrepBatch({
    required this.id,
    required this.date,
    required this.dishes,
  });
}