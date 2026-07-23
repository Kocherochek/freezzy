// lib/core/logic/cooking_session.dart
//
// Логика создания и управления сессией готовки.

import '../models/cooking_session.dart';
import '../models/enums.dart';
import '../models/recipe.dart';
import '../models/item_variant.dart';
import '../models/base_item.dart';
import 'recipe_matching.dart';
import 'recipe_filtering.dart';
import 'prep_menu_generation.dart';
import 'stock_consumption.dart';
import 'units.dart';

/// Создаёт сессию готовки из сгенерированного меню.
///
/// [params] содержит меню, рецепты, склад и настройки.
/// Возвращает сессию с:
/// - отмасштабированными ингредиентами (по порциям)
/// - шагами с пометкой о заготовках (автоматически выполненные)
/// - расчётом экономии времени
CookingSession createCookingSession(CookingSessionParams params) {
  final recipes = <CookingRecipe>[];
  final recipeServings = <String, int>{};
  final matchResults = <String, RecipeMatchResult>{};

  // Определяем, какие рецепты готовить
  final recipeIdsToCook = <String>[];

  if (params.menu != null) {
    // Обычное меню: рецепты в порядке приёмов пищи
    for (final dish in params.menu!.dishes) {
      if (dish.recipeId != null) {
        recipeIdsToCook.add(dish.recipeId!);
      }
    }
  } else if (params.prepMenu != null) {
    // Сессия заготовок: рецепты в произвольном порядке
    for (final dish in params.prepMenu!.dishes) {
      recipeIdsToCook.add(dish.recipeId);
    }
  }

  for (final recipeId in recipeIdsToCook) {
    final recipe = params.allRecipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => throw StateError('Рецепт $recipeId не найден в книге'),
    );

    final targetServings = params.customServings[recipeId] ?? recipe.baseServings;
    recipeServings[recipeId] = targetServings;

    // Масштабируем рецепт
    final scaled = scaleRecipe(
      recipe: recipe,
      targetServings: targetServings,
      scaleCookingTime: false,
    );

    // Считаем match для проверки заготовок
    final match = matchRecipe(
      recipe: recipe,
      productStock: params.productStock,
      prepStock: params.prepStock,
    );
    matchResults[recipeId] = match;

    // Создаём шаги с пометкой о заготовках
    final cookingSteps = <CookingStep>[];

    for (final step in recipe.steps) {
      final stepIndex = recipe.steps.indexOf(step);

      // Проверяем, использует ли этот шаг заготовку
      bool isPrepStep = false;
      String? prepUsedName;
      int? timeSavedSeconds;

      // Проверяем stepIngredients на наличие заготовок
      for (final stepIng in step.stepIngredients) {
        final prepReq = recipe.requiredPreps.firstWhere(
          (p) => p.id == stepIng.ingredientRefId,
          orElse: () => throw StateError('IngredientRef ${stepIng.ingredientRefId} не найден'),
        );

        // Проверяем, есть ли эта заготовка на складе
        final hasPrepInStock = params.prepStock.any(
          (v) => v.baseItemId == prepReq.basePrepId
        );

        if (hasPrepInStock) {
          isPrepStep = true;
          prepUsedName = prepReq.basePrepName;
          // Время экономится = время приготовки этой заготовки
          // (приблизительно = cookingTimeMinutes * 60)
          timeSavedSeconds = recipe.cookingTimeMinutes * 60;
          break;
        }
      }

      cookingSteps.add(CookingStep(
        originalStep: step,
        stepIndex: stepIndex,
        isCompleted: isPrepStep, // шаг с заготовкой сразу выполнен
        isPrepStepAutoCompleted: isPrepStep,
        prepUsedName: prepUsedName,
        timeSavedSeconds: timeSavedSeconds,
      ));
    }

    // Считаем время
    final totalSeconds = recipe.steps
        .where((s) => s.durationSeconds != null)
        .fold<int>(0, (sum, s) => sum + (s.durationSeconds ?? 0));

    final timeSaved = cookingSteps
        .where((s) => s.timeSavedSeconds != null)
        .fold<int>(0, (sum, s) => sum + (s.timeSavedSeconds ?? 0));

    final totalMinutes = (totalSeconds / 60).round();
    final effectiveMinutes = ((totalSeconds - timeSaved) / 60).round().clamp(0, totalMinutes);

    final hasAvailablePreps = match.prepResults.any((r) => r.isSufficient);
    final quickCookTag = hasAvailablePreps
        ? 'Можно быстро приготовить, есть заготовка'
        : null;

    recipes.add(CookingRecipe(
      originalRecipe: recipe,
      targetServings: targetServings,
      scaledIngredients: scaled.scaledIngredients,
      scaledPreps: scaled.scaledPreps,
      steps: cookingSteps,
      totalCookingTimeMinutes: totalMinutes,
      effectiveCookingTimeMinutes: effectiveMinutes,
      hasAvailablePreps: hasAvailablePreps,
      quickCookTag: quickCookTag,
    ));
  }

  return CookingSession(
    id: 'cooking_${DateTime.now().millisecondsSinceEpoch}',
    startedAt: DateTime.now(),
    recipes: recipes,
    recipeServings: recipeServings,
    productStockSnapshot: params.productStock,
    prepStockSnapshot: params.prepStock,
    matchResultsSnapshot: matchResults,
  );
}

/// Отмечает шаг как выполненный и открывает следующий.
CookingRecipe completeStep(CookingRecipe recipe, int stepIndex) {
  final updatedSteps = recipe.steps.map((s) {
    if (s.stepIndex == stepIndex) {
      return s.copyWith(isCompleted: true);
    }
    return s;
  }).toList();

  return CookingRecipe(
    originalRecipe: recipe.originalRecipe,
    targetServings: recipe.targetServings,
    scaledIngredients: recipe.scaledIngredients,
    scaledPreps: recipe.scaledPreps,
    steps: updatedSteps,
    totalCookingTimeMinutes: recipe.totalCookingTimeMinutes,
    effectiveCookingTimeMinutes: recipe.effectiveCookingTimeMinutes,
    hasAvailablePreps: recipe.hasAvailablePreps,
    quickCookTag: recipe.quickCookTag,
  );
}

/// Завершает готовку рецепта.
///
/// Для обычных рецептов: списывает продукты.
/// Для рецептов заготовок: списывает продукты + создаёт партию заготовки.
///
/// [eatNowQuantity] и [storedQuantity] применяются только для рецептов заготовок.
RecipeCompletionResult completeRecipe({
  required CookingRecipe cookingRecipe,
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
  required Map<String, BasePrep> prepsById,
  required Map<String, BaseProduct> productsById,
  required String Function() generateId,
  double eatNowQuantity = 0, // для рецептов заготовок
  double storedQuantity = 0, // для рецептов заготовок
  StockingZone? storageZone, // для рецептов заготовок
  DateTime? manualExpiryDate,
}) {
  final recipe = cookingRecipe.originalRecipe;
  final isPrepRecipe = recipe.type == RecipeType.prep;

  // Снимаем слепок доступности продуктов ДО готовки
  final beforeTotals = <String, double>{};
  for (final v in productStock) {
    beforeTotals[v.baseItemId] =
        (beforeTotals[v.baseItemId] ?? 0) + toBaseUnit(v.quantity, v.unit);
  }

  // Получаем matchResult для этого рецепта
  final match = matchRecipe(
    recipe: recipe,
    productStock: productStock,
    prepStock: prepStock,
  );

  if (!isPrepRecipe) {
    // Обычный рецепт: просто списываем
    final consumption = consumeForRecipe(
      match: match,
      productStock: productStock,
      prepStock: prepStock,
    );

    final depleted = _findDepletedProducts(
      beforeTotals: beforeTotals,
      afterStock: consumption.updatedProductStock,
      productsById: productsById,
    );

    return RecipeCompletionResult(
      updatedProductStock: consumption.updatedProductStock,
      updatedPrepStock: consumption.updatedPrepStock,
      isPrepRecipe: false,
      depletedProducts: depleted,
    );
  } else {
    // Рецепт заготовки: списываем + создаём партию
    final basePrep = prepsById[recipe.producesPrep!.basePrepId];
    if (basePrep == null) {
      throw StateError('BasePrep ${recipe.producesPrep!.basePrepId} не найден');
    }

    final result = completePrepCooking(
      recipe: recipe,
      match: match,
      productStock: productStock,
      prepStock: prepStock,
      basePrep: basePrep,
      eatNowQuantity: eatNowQuantity,
      storedQuantity: storedQuantity,
      storageZone: storageZone ?? basePrep.defaultZone,
      generateId: generateId,
      addedDate: DateTime.now(),
      manualExpiryDate: manualExpiryDate,
    );

    final depleted = _findDepletedProducts(
      beforeTotals: beforeTotals,
      afterStock: result.updatedProductStock,
      productsById: productsById,
    );

    return RecipeCompletionResult(
      updatedProductStock: result.updatedProductStock,
      updatedPrepStock: result.updatedPrepStock,
      createdPrepVariant: result.createdPrepVariant,
      isPrepRecipe: true,
      depletedProducts: depleted,
    );
  }
}

/// Вычисляет продукты, которые закончились (были > 0, стали 0).
List<DepletedProduct> _findDepletedProducts({
  required Map<String, double> beforeTotals,
  required List<ItemVariant> afterStock,
  required Map<String, BaseProduct> productsById,
}) {
  final afterTotals = <String, double>{};
  for (final v in afterStock) {
    afterTotals[v.baseItemId] =
        (afterTotals[v.baseItemId] ?? 0) + toBaseUnit(v.quantity, v.unit);
  }

  final depleted = <DepletedProduct>[];
  for (final entry in beforeTotals.entries) {
    if (entry.value <= 0.0001) continue; // и так не было
    final afterQty = afterTotals[entry.key] ?? 0;
    if (afterQty > 0.0001) continue; // ещё осталось

    final product = productsById[entry.key];
    if (product == null) continue;
    if (product.alwaysInStock) continue; // соль/перец не предлагаем

    depleted.add(DepletedProduct(
      baseProductId: entry.key,
      baseProductName: product.name,
      consumedQuantity: fromBaseUnit(entry.value, product.defaultUnit),
      unit: product.defaultUnit,
    ));
  }
  return depleted;
}

/// Меняет количество порций для рецепта в сессии и пересчитывает ингредиенты.
CookingRecipe updateServings({
  required CookingRecipe recipe,
  required int newServings,
}) {
  final scaled = scaleRecipe(
    recipe: recipe.originalRecipe,
    targetServings: newServings,
    scaleCookingTime: false,
  );

  return CookingRecipe(
    originalRecipe: recipe.originalRecipe,
    targetServings: newServings,
    scaledIngredients: scaled.scaledIngredients,
    scaledPreps: scaled.scaledPreps,
    steps: recipe.steps, // шаги не меняются
    totalCookingTimeMinutes: recipe.totalCookingTimeMinutes,
    effectiveCookingTimeMinutes: recipe.effectiveCookingTimeMinutes,
    hasAvailablePreps: recipe.hasAvailablePreps,
    quickCookTag: recipe.quickCookTag,
  );
}

/// Проверяет, есть ли все заготовки для рецепта в наличии.
bool checkAllPrepsAvailable({
  required Recipe recipe,
  required List<ItemVariant> prepStock,
}) {
  for (final prepReq in recipe.requiredPreps) {
    final hasPrep = prepStock.any((v) => v.baseItemId == prepReq.basePrepId);
    if (!hasPrep) return false;
  }
  return true;
}

/// Возвращает список заготок, которые есть в наличии для рецепта.
List<String> getAvailablePrepsForRecipe({
  required Recipe recipe,
  required List<ItemVariant> prepStock,
}) {
  final available = <String>[];
  for (final prepReq in recipe.requiredPreps) {
    final hasPrep = prepStock.any((v) => v.baseItemId == prepReq.basePrepId);
    if (hasPrep) {
      available.add(prepReq.basePrepName);
    }
  }
  return available;
}
