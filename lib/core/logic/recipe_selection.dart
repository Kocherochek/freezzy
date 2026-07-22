// lib/core/logic/recipe_selection.dart
//
// Уровень 3, часть 2: заполнение слотов ОДНОГО приёма пищи рецептами.
// Учитывает: закреплённые блюда (не трогаем), рецепт с несколькими
// ролями сразу (закрывает несколько слотов одним блюдом — приоритет
// над score), и просто наивысший score среди подходящих кандидатов.
//
// Сознательно НЕ трогает генерацию на весь день/неделю целиком —
// это будет отдельная функция, которая просто вызывает
// generateDishesForMealSlot для каждого MealSlot формулы по очереди.

import '../models/generated_menu.dart';
import '../models/item_variant.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import 'recipe_matching.dart';
import 'recipe_scoring.dart';

/// Результат подбора одного рецепта: сам рецепт + какие слоты он закрывает.
class SlotSelection {
  final Recipe recipe;
  final List<String> coveredComponentSlotIds;
  final RecipeMatchResult match;

  SlotSelection({
    required this.recipe,
    required this.coveredComponentSlotIds,
    required this.match,
  });
}

/// Находит лучший рецепт среди кандидатов для ещё открытых слотов.
/// Сначала сравнивает по количеству закрытых слотов (рецепт с
/// несколькими ролями предпочтительнее), и только при равенстве —
/// по score.
SlotSelection? pickBestRecipeForOpenSlots({
  required List<MealComponentSlot> openSlots,
  required List<Recipe> candidateRecipes, // уже отфильтрованы по type == meal
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
}) {
  final openRoles = openSlots.map((s) => s.role).toSet();

  SlotSelection? best;
  double bestScore = -1;
  int bestCoverage = 0;

  for (final recipe in candidateRecipes) {
    final coveredRoles = recipe.menuRoles.toSet().intersection(openRoles);
    if (coveredRoles.isEmpty) continue; // рецепт не закрывает ни одной нужной роли

    final match = matchRecipe(
      recipe: recipe,
      productStock: productStock,
      prepStock: prepStock,
    );
    final score = scoreRecipe(recipe: recipe, match: match);

    final coverage = coveredRoles.length;
    final isBetter = coverage > bestCoverage ||
        (coverage == bestCoverage && score.totalScore > bestScore);

    if (isBetter) {
      final coveredSlotIds = openSlots
          .where((s) => coveredRoles.contains(s.role))
          .map((s) => s.id)
          .toList();

      best = SlotSelection(
        recipe: recipe,
        coveredComponentSlotIds: coveredSlotIds,
        match: match,
      );
      bestScore = score.totalScore;
      bestCoverage = coverage;
    }
  }

  return best;
}

/// Заполняет слоты ОДНОГО приёма пищи рецептами, пропуская уже
/// закреплённые. Предпочитает рецепты, которые сегодня ещё не
/// использовались, но если ничего подходящего среди них нет —
/// разрешает повтор, лишь бы слот не остался пустым. Пустым слот
/// останется только если в книге рецептов вообще нет ни одного
/// рецепта с нужной ролью.
List<MenuDish> generateDishesForMealSlot({
  required MealSlot mealSlot,
  required List<MenuDish> pinnedDishes, // уже закреплённые блюда этого приёма пищи
  required List<Recipe> candidateRecipes,
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
  required String Function() generateId, // например, uuid.v4 из твоего проекта
  Set<String> excludeRecipeIds = const {}, // рецепты, уже использованные в другом приёме пищи за день
}) {
  final pinnedSlotIds =
      pinnedDishes.expand((d) => d.fulfilledComponentSlotIds).toSet();

  var openSlots =
      mealSlot.components.where((s) => !pinnedSlotIds.contains(s.id)).toList();

  final remainingCandidates = candidateRecipes
      .where((r) => !excludeRecipeIds.contains(r.id))
      .toList();
  final result = <MenuDish>[...pinnedDishes];

  while (openSlots.isNotEmpty) {
    var selection = pickBestRecipeForOpenSlots(
      openSlots: openSlots,
      candidateRecipes: remainingCandidates,
      productStock: productStock,
      prepStock: prepStock,
    );

    // Среди рецептов, которые сегодня ещё не использовались, ничего не
    // подошло — разрешаем повтор (уникальность блюд за день — это
    // предпочтение, а не жёсткое правило). Ищем уже среди ВСЕХ рецептов
    // с нужной ролью, включая занятые другими приёмами пищи.
    selection ??= pickBestRecipeForOpenSlots(
      openSlots: openSlots,
      candidateRecipes: candidateRecipes,
      productStock: productStock,
      prepStock: prepStock,
    );

    // Слот остаётся пустым только если в книге рецептов вообще нет
    // ни одного рецепта с такой ролью — тогда экран должен предложить
    // выбрать блюдо вручную.
    if (selection == null) break;

    // final переменная — в отличие от selection, она может быть безопасно
    // использована внутри замыкания (.where) ниже без ошибки про null.
    final chosen = selection;

    result.add(MenuDish(
      id: generateId(),
      mealSlotId: mealSlot.id,
      fulfilledComponentSlotIds: chosen.coveredComponentSlotIds,
      recipeId: chosen.recipe.id,
    ));

    // Закрываем слоты, которые уже закрыты этим рецептом
    final newlyOpenSlots = openSlots
        .where((s) => !chosen.coveredComponentSlotIds.contains(s.id))
        .toList();
    
    // Удаляем рецепт, который уже использован, чтобы предотвратить повторное
    // использование одного и того же рецепта для других слотов этого же приёма пищи
    remainingCandidates.remove(chosen.recipe);
    
    // Обновляем список открытых слотов для следующей итерации цикла
    openSlots = newlyOpenSlots;
  }

  return result;
}