// lib/core/logic/day_menu_generation.dart
//
// Уровень 3, часть 3: генерация ВСЕГО дня. Просто идёт по MealSlot
// формулы плана и для каждого вызывает generateDishesForMealSlot,
// накапливая id уже использованных рецептов — чтобы один и тот же
// рецепт не оказался, например, и на обед, и на ужин.
//
// При регенерации (previousMenu передан) закреплённые блюда каждого
// приёма пищи сохраняются автоматически — их просто "выцепляем"
// из прошлого меню и передаём как pinnedDishes.

import '../models/enums.dart';
import '../models/generated_menu.dart';
import '../models/item_variant.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import 'recipe_selection.dart';

GeneratedMenu generateMenuForDay({
  required MealPlanTemplate plan,
  required DateTime date,
  required List<Recipe> allRecipes, // фильтруется по type == meal внутри
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
  required String Function() generateId,
  GeneratedMenu? previousMenu, // передай при перегенерации, чтобы сохранить закреплённые блюда
}) {
  final mealRecipes =
      allRecipes.where((r) => r.type == RecipeType.meal).toList();

  final allDishes = <MenuDish>[];
  final usedRecipeIds = <String>{};

  for (final mealSlot in plan.mealSlots) {
    final pinnedForThisSlot = previousMenu?.dishes
            .where((d) => d.mealSlotId == mealSlot.id && d.isPinned)
            .toList() ??
        const <MenuDish>[];

    // Закреплённые рецепты тоже не должны повториться в другом приёме пищи.
    for (final pinned in pinnedForThisSlot) {
      if (pinned.recipeId != null) usedRecipeIds.add(pinned.recipeId!);
    }

    final dishesForSlot = generateDishesForMealSlot(
      mealSlot: mealSlot,
      pinnedDishes: pinnedForThisSlot,
      candidateRecipes: mealRecipes,
      productStock: productStock,
      prepStock: prepStock,
      generateId: generateId,
      excludeRecipeIds: usedRecipeIds,
    );

    allDishes.addAll(dishesForSlot);

    for (final dish in dishesForSlot) {
      if (dish.recipeId != null) usedRecipeIds.add(dish.recipeId!);
    }
  }

  return GeneratedMenu(
    id: generateId(),
    planTemplateId: plan.id,
    date: date,
    dishes: allDishes,
  );
}