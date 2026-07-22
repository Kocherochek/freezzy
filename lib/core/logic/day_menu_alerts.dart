// lib/core/logic/day_menu_alerts.dart
//
// Агрегация статусов ВСЕХ блюд дня в два списка для баннера "перед
// первым рецептом": чего не хватает суммарно за день (сложено по
// baseItemId, а не по рецептам — иначе список покупок задвоится),
// и что нужно разморозить (тут просто "какие продукты и для каких
// рецептов", количество не так важно, как факт "не забудь достать").

import '../models/generated_menu.dart';
import '../models/item_variant.dart';
import '../models/recipe.dart';
import 'recipe_matching.dart';
import 'stock_consumption.dart';

/// Одна строка агрегированной потребности — либо "не хватает X",
/// либо "нужно разморозить Y". Для разморозки quantityInBaseUnit
/// не несёт смысла и всегда 0 — важен только сам факт и список рецептов.
class DayIngredientNeed {
  final String baseItemId;
  final String displayName;
  final double quantityInBaseUnit;
  final List<String> recipeIds; // какие рецепты дня в этом нуждаются

  DayIngredientNeed({
    required this.baseItemId,
    required this.displayName,
    required this.quantityInBaseUnit,
    required this.recipeIds,
  });

  DayIngredientNeed addOccurrence({
    required double extraQuantity,
    required String recipeId,
  }) {
    return DayIngredientNeed(
      baseItemId: baseItemId,
      displayName: displayName,
      quantityInBaseUnit: quantityInBaseUnit + extraQuantity,
      recipeIds: [...recipeIds, recipeId],
    );
  }
}

class DayMenuAlerts {
  final List<DayIngredientNeed> missingIngredients;
  final List<DayIngredientNeed> needsDefrostIngredients;

  DayMenuAlerts({
    required this.missingIngredients,
    required this.needsDefrostIngredients,
  });

  bool get hasMissingIngredients => missingIngredients.isNotEmpty;
  bool get hasItemsToDefrost => needsDefrostIngredients.isNotEmpty;
}

/// Считает баннер для всего дня. recipesById — просто способ быстро
/// найти Recipe по id, не пробегая список каждый раз (аналог группировки
/// склада, которую мы делали для matchRecipe).
DayMenuAlerts computeDayAlerts({
  required GeneratedMenu menu,
  required Map<String, Recipe> recipesById,
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
}) {
  final missing = <String, DayIngredientNeed>{};
  final needsDefrost = <String, DayIngredientNeed>{};

  // Виртуальный склад, который "расходуется" по мере прохода по блюдам
  // дня — без этого второе блюдо, которому нужен тот же продукт, что и
  // первому (например, курица для обеда и ужина), ошибочно посчиталось
  // бы "в наличии" против полного остатка склада, хотя первое блюдо
  // уже забрало часть. Настоящий склад это НЕ трогает — это просто
  // прогноз "хватит ли на весь день".
  var virtualProductStock = productStock;
  var virtualPrepStock = prepStock;

  for (final dish in menu.dishes) {
    if (dish.recipeId == null) continue;
    final recipe = recipesById[dish.recipeId];
    if (recipe == null) continue;

    final match = matchRecipe(
      recipe: recipe,
      productStock: virtualProductStock,
      prepStock: virtualPrepStock,
    );

    for (final result in [...match.productResults, ...match.prepResults]) {
      if (!result.isSufficient) {
        final existing = missing[result.baseItemId];
        missing[result.baseItemId] = existing == null
            ? DayIngredientNeed(
                baseItemId: result.baseItemId,
                displayName: result.displayName,
                quantityInBaseUnit: result.missingInBaseUnit,
                recipeIds: [recipe.id],
              )
            : existing.addOccurrence(
                extraQuantity: result.missingInBaseUnit,
                recipeId: recipe.id,
              );
      }

      if (result.needsDefrost) {
        final existing = needsDefrost[result.baseItemId];
        needsDefrost[result.baseItemId] = existing == null
            ? DayIngredientNeed(
                baseItemId: result.baseItemId,
                displayName: result.displayName,
                quantityInBaseUnit: 0,
                recipeIds: [recipe.id],
              )
            : existing.addOccurrence(extraQuantity: 0, recipeId: recipe.id);
      }
    }

    // Виртуально расходуем то, что реально есть (allocations) — чтобы
    // следующее блюдо дня считало уже уменьшённый остаток, а не полный склад.
    final consumption = consumeForRecipe(
      match: match,
      productStock: virtualProductStock,
      prepStock: virtualPrepStock,
    );
    virtualProductStock = consumption.updatedProductStock;
    virtualPrepStock = consumption.updatedPrepStock;
  }

  return DayMenuAlerts(
    missingIngredients: missing.values.toList(),
    needsDefrostIngredients: needsDefrost.values.toList(),
  );
}