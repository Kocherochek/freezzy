// lib/core/logic/prep_menu_generation.dart
//
// Генерация меню ЗАГОТОВОК (RecipeType.prep).
// В отличие от обычного меню: нет приёмов пищи/слотов, просто список рецептов.
// Пользователь задаёт: сколько рецептов нужно + предпочтительные ингредиенты (обязательные к использованию).
// Принципы скоринга те же, что и для обычного меню, НО без бонуса usesPrep.

import '../models/base_item.dart';
import '../models/enums.dart';
import '../models/item_variant.dart';
import '../models/prep_batch.dart';
import '../models/recipe.dart';
import 'prep_yield_stocking.dart';
import 'recipe_matching.dart';
import 'recipe_scoring.dart';
import 'stock_consumption.dart';

/// Параметры для генерации меню заготовок
class PrepMenuParams {
  final int recipeCount; // сколько рецептов сгенерировать
  final List<String> preferredProductIds; // ингредиенты, которые ОБЯЗАТЕЛЬНО должны быть в рецептах
  final Set<String> excludedRecipeIds; // рецепты, которые не показывать (уже приготовлены, не нравятся и т.д.)
  
  const PrepMenuParams({
    required this.recipeCount,
    this.preferredProductIds = const [],
    this.excludedRecipeIds = const {},
  });
}

/// Результат генерации меню заготовок
class GeneratedPrepMenu {
  final String id;
  final DateTime date;
  final List<PrepBatchDish> dishes;
  
  GeneratedPrepMenu({
    required this.id,
    required this.date,
    required this.dishes,
  });
  
  // Конвертер в GeneratedPrepBatch для совместимости с существующим кодом
  GeneratedPrepBatch toPrepBatch() {
    return GeneratedPrepBatch(
      id: id,
      date: date,
      dishes: dishes,
    );
  }
}

/// Генерирует меню заготовок на день
GeneratedPrepMenu generatePrepMenu({
  required PrepMenuParams params,
  required DateTime date,
  required List<Recipe> allRecipes, // фильтруется по type == prep внутри
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
  required String Function() generateId,
  GeneratedPrepMenu? previousMenu, // для сохранения закреплённых
}) {
  // Берём только рецепты типа prep
  final prepRecipes = allRecipes
      .where((r) => r.type == RecipeType.prep)
      .where((r) => !params.excludedRecipeIds.contains(r.id))
      .toList();

  // Если есть закреплённые рецепты из прошлого меню — восстанавливаем их
  final pinnedFromPrevious = previousMenu?.dishes
          .where((d) => d.isPinned)
          .map((d) => d.recipeId)
          .toSet() ??
      <String>{};

  // Оценка (score) всех рецептов с учётом предпочтительных продуктов
  final scoredRecipes = <RecipeScore>[];
  
  for (final recipe in prepRecipes) {
    final match = matchRecipe(
      recipe: recipe,
      productStock: productStock,
      prepStock: prepStock,
    );
    
    // Базовый скоринг
    final score = scoreRecipe(recipe: recipe, match: match);
    
    // Дополнительный бонус за предпочтительные ингредиенты
    double preferenceBonus = 0;
    if (params.preferredProductIds.isNotEmpty) {
      final recipeProductIds = recipe.ingredients.map((i) => i.baseProductId).toSet();
      final preferredInRecipe = params.preferredProductIds
          .where((id) => recipeProductIds.contains(id))
          .length;
      // Бонус пропорционален количеству предпочтительных продуктов в рецепте
      if (preferredInRecipe > 0) {
        preferenceBonus = preferredInRecipe * 50; // значительный бонус
      }
    }
    
    scoredRecipes.add(RecipeScore(
      recipe: recipe,
      match: match,
      availabilityRatio: score.availabilityRatio,
      totalScore: score.totalScore + preferenceBonus,
    ));
  }

  // Сортируем по score (убывание)
  scoredRecipes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

  // Закреплённые рецепты — поднимаем вверх, но сохраняем их относительный порядок
  final pinnedRecipes = scoredRecipes
      .where((s) => pinnedFromPrevious.contains(s.recipe.id))
      .toList();
  final otherRecipes = scoredRecipes
      .where((s) => !pinnedFromPrevious.contains(s.recipe.id))
      .toList();

  final selectedDishes = <PrepBatchDish>[];
  final usedRecipeIds = <String>{};

  // Сначала добавляем закреплённые
  for (final scored in pinnedRecipes) {
    if (selectedDishes.length >= params.recipeCount) break;
    selectedDishes.add(PrepBatchDish(
      id: generateId(),
      recipeId: scored.recipe.id,
      isPinned: true,
    ));
    usedRecipeIds.add(scored.recipe.id);
  }

  // Потом заполняем остальные из лучших
  for (final scored in otherRecipes) {
    if (selectedDishes.length >= params.recipeCount) break;
    if (usedRecipeIds.contains(scored.recipe.id)) continue;
    
    selectedDishes.add(PrepBatchDish(
      id: generateId(),
      recipeId: scored.recipe.id,
      isPinned: false,
    ));
    usedRecipeIds.add(scored.recipe.id);
  }

  // Если не набрали нужное количество — заполняем оставшиеся (даже с низким score)
  // Это edge case: рецептов в книге меньше, чем нужно пользователю
  if (selectedDishes.length < params.recipeCount) {
    for (final recipe in prepRecipes) {
      if (selectedDishes.length >= params.recipeCount) break;
      if (usedRecipeIds.contains(recipe.id)) continue;
      
      selectedDishes.add(PrepBatchDish(
        id: generateId(),
        recipeId: recipe.id,
        isPinned: false,
      ));
      usedRecipeIds.add(recipe.id);
    }
  }

  return GeneratedPrepMenu(
    id: generateId(),
    date: date,
    dishes: selectedDishes,
  );
}

/// Комплексное завершение готовки рецепта заготовки:
/// 1. Списывает израсходованные продукты (как consumeForRecipe)
/// 2. Создаёт партию заготовки на складе (как createPrepVariantFromYield)
/// 
/// Возвращает обновлённые стоки продуктов и заготовок.
class PrepCookingResult {
  final List<ItemVariant> updatedProductStock;
  final List<ItemVariant> updatedPrepStock;
  final PrepVariant? createdPrepVariant; // null, если всё съели сразу

  PrepCookingResult({
    required this.updatedProductStock,
    required this.updatedPrepStock,
    this.createdPrepVariant,
  });
}

/// Завершает готовку рецепта заготовки.
/// 
/// [recipe] — приготовленный рецепт (type == prep)
/// [match] — результат matchRecipe для этого рецепта (уже посчитанный)
/// [productStock] — текущий склад продуктов
/// [prepStock] — текущий склад заготовок
/// [basePrep] — базовая заготовка, которую производит рецепт (recipe.producesPrep.basePrepId)
/// [eatNowQuantity] — сколько съедается прямо сейчас (не идёт на склад)
/// [storedQuantity] — сколько уходит на хранение
/// [storageZone] — куда кладём (fridge/freezer)
/// [generateId] — генератор ID для новой партии
/// [addedDate] — дата добавления на склад (обычно now)
/// [manualExpiryDate] — ручной срок годности (если пользователь указал)
PrepCookingResult completePrepCooking({
  required Recipe recipe,
  required RecipeMatchResult match,
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
  required BasePrep basePrep,
  required double eatNowQuantity,
  required double storedQuantity,
  required StockingZone storageZone,
  required String Function() generateId,
  required DateTime addedDate,
  DateTime? manualExpiryDate,
}) {
  // 1. Списание продуктов
  final consumption = consumeForRecipe(
    match: match,
    productStock: productStock,
    prepStock: prepStock,
  );
  
  // 2. Создание партии заготовки (если что-то ушло на хранение)
  PrepVariant? newPrepVariant;
  if (storedQuantity > 0) {
    newPrepVariant = createPrepVariantFromYield(
      recipe: recipe,
      basePrep: basePrep,
      eatNowQuantity: eatNowQuantity, // передаем 0, так как уже учли в storedQuantity
      storageZone: storageZone,
      id: generateId(),
      addedDate: addedDate,
      manualExpiryDate: manualExpiryDate,
    );
    // Добавляем новую партию к списку заготовок
    final updatedPrepStockWithNew = [...consumption.updatedPrepStock];
    if (newPrepVariant != null) {
      updatedPrepStockWithNew.add(newPrepVariant);
    }
    return PrepCookingResult(
      updatedProductStock: consumption.updatedProductStock,
      updatedPrepStock: updatedPrepStockWithNew,
      createdPrepVariant: newPrepVariant,
    );
  }
  
  return PrepCookingResult(
    updatedProductStock: consumption.updatedProductStock,
    updatedPrepStock: consumption.updatedPrepStock,
    createdPrepVariant: null,
  );
}