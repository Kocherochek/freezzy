// lib/core/logic/recipe_matching.dart
//
// Уровень 2: статус ЦЕЛОГО рецепта относительно текущих запасов —
// те самые 3 плашки ("в наличии", "не хватает", "нужно разморозить").
// Строится поверх matchIngredient() из stock_matching.dart: рецепт
// просто прогоняет через неё каждый свой ингредиент и заготовку,
// затем группирует результаты.

import '../models/item_variant.dart';
import '../models/recipe.dart';
import 'stock_matching.dart';

  /// Группирует партии склада по baseItemId — считаем один раз перед
  /// серией проверок, а не фильтруем весь склад на каждый ингредиент.
  Map<String, List<ItemVariant>> groupVariantsByBaseItem(
    List<ItemVariant> variants,
  ) {
    final map = <String, List<ItemVariant>>{};
    for (final v in variants) {
      if (!map.containsKey(v.baseItemId)) {
        map[v.baseItemId] = [];
      }
      map[v.baseItemId]!.add(v);
    }
    return map;
  }

class RecipeMatchResult {
  final String recipeId;
  final List<IngredientMatchResult> productResults;
  final List<IngredientMatchResult> prepResults;

  RecipeMatchResult({
    required this.recipeId,
    required this.productResults,
    required this.prepResults,
  });

  List<IngredientMatchResult> get _all => [...productResults, ...prepResults];

  /// Плашка "в наличии" — хватает без докупки (независимо от заморозки).
  List<IngredientMatchResult> get availableIngredients =>
      _all.where((r) => r.isSufficient).toList();

  /// Плашка "не хватает" — нужно докупить хотя бы часть.
  List<IngredientMatchResult> get missingIngredients =>
      _all.where((r) => !r.isSufficient).toList();

  /// Плашка "нужно разморозить" — хотя бы часть того, что реально
  /// пойдёт в дело, лежит в морозилке. Может пересекаться с missing.
  List<IngredientMatchResult> get needsDefrostIngredients =>
      _all.where((r) => r.needsDefrost).toList();

  /// Можно готовить прямо сейчас без докупок (разморозка не мешает готовке).
  bool get isReadyToCook => missingIngredients.isEmpty;

  /// Хотя бы один реально используемый ингредиент скоро испортится —
  /// сигнал для подбора рецептов: "используй это, пока не пропало".
  bool get usesExpiringStock => _all.any((r) => r.usesExpiringStock);
}

/// Сопоставляет рецепт целиком со складом продуктов и заготовок.
///
/// [productStock] и [prepStock] — обычно ВСЕ партии на складе (не только
/// относящиеся к этому рецепту) — функция сама сгруппирует и найдёт нужное.
RecipeMatchResult matchRecipe({
  required Recipe recipe,
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
}) {
  final productsByBaseId = groupVariantsByBaseItem(productStock);
  final prepsByBaseId = groupVariantsByBaseItem(prepStock);

  final productResults = recipe.ingredients.map((ing) {
    return matchIngredient(
      baseItemId: ing.baseProductId,
      displayName: ing.baseProductName,
      requiredQuantity: ing.quantity,
      requiredUnit: ing.unit,
      availableVariants: productsByBaseId[ing.baseProductId] ?? const [],
    );
  }).toList();

  final prepResults = recipe.requiredPreps.map((req) {
    return matchIngredient(
      baseItemId: req.basePrepId,
      displayName: req.basePrepName,
      requiredQuantity: req.quantity,
      requiredUnit: req.unit,
      availableVariants: prepsByBaseId[req.basePrepId] ?? const [],
    );
  }).toList();

  return RecipeMatchResult(
    recipeId: recipe.id,
    productResults: productResults,
    prepResults: prepResults,
  );
}