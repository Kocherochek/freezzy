// lib/core/logic/recipe_filtering.dart
//
// Фильтрация рецептов по предпочтениям пользователя + масштабирование порций.

import '../models/recipe.dart';
import '../models/enums.dart';
import '../models/base_item.dart';
import '../models/item_variant.dart';
import 'recipe_matching.dart';

/// Параметры фильтрации рецептов при генерации меню.
class RecipeFilter {
  /// Ингредиенты, которые пользователь НЕ хочет видеть в рецептах.
  /// Если рецепт содержит хоть один из этих baseProductId — он исключается.
  final Set<String> excludedProductIds;

  /// Только рецепты, содержащие ХОТЯ БЫ ОДИН из этих ингредиентов.
  /// Если список пуст — фильтр не применяется.
  final Set<String> requiredProductIds;

  /// Только вегетарианские рецепты (нет мяса/рыбы).
  /// Определяется через MenuRole.protein, но только если это животный белок.
  /// Для простоты: если в рецепте есть продукт с categoryId входит в "мясо/рыба" — исключаем.
  final bool vegetarianOnly;

  /// Только веганские рецепты (нет животных продуктов вообще).
  final bool veganOnly;

  /// Только любимые рецепты.
  final bool favoritesOnly;

  /// Максимальное время приготовления в минутах (null = без лимита).
  final int? maxCookingTimeMinutes;

  /// Исключить конкретные рецепты по ID (например, уже приготовленные сегодня).
  final Set<String> excludedRecipeIds;

  /// Категории продуктов, которые считаются "животными" для вегетарианского фильтра.
  /// Заполняется из справочника категорий приложения.
  final Set<String> animalProductCategoryIds;

  const RecipeFilter({
    this.excludedProductIds = const {},
    this.requiredProductIds = const {},
    this.vegetarianOnly = false,
    this.veganOnly = false,
    this.favoritesOnly = false,
    this.maxCookingTimeMinutes,
    this.excludedRecipeIds = const {},
    this.animalProductCategoryIds = const {},
  });

  /// Проверяет, проходит ли рецепт все фильтры.
  bool matches(Recipe recipe, Map<String, BaseProduct> productsById) {
    // 1. Исключённые рецепты
    if (excludedRecipeIds.contains(recipe.id)) return false;

    // 2. Только любимые
    if (favoritesOnly && !recipe.isFavorite) return false;

    // 3. Максимальное время приготовления
    if (maxCookingTimeMinutes != null && recipe.cookingTimeMinutes > maxCookingTimeMinutes!) {
      return false;
    }

    // 4. Обязательные ингредиенты (хотя бы один должен быть)
    if (requiredProductIds.isNotEmpty) {
      final recipeProductIds = recipe.ingredients.map((i) => i.baseProductId).toSet();
      final hasRequired = requiredProductIds.any(recipeProductIds.contains);
      if (!hasRequired) return false;
    }

    // 5. Исключённые ингредиенты (ни один не должен быть)
    if (excludedProductIds.isNotEmpty) {
      final recipeProductIds = recipe.ingredients.map((i) => i.baseProductId).toSet();
      final hasExcluded = excludedProductIds.any(recipeProductIds.contains);
      if (hasExcluded) return false;
    }

    // 6. Вегетарианский / веганский фильтры
    if (vegetarianOnly || veganOnly) {
      for (final ing in recipe.ingredients) {
        final product = productsById[ing.baseProductId];
        if (product == null) continue;
        
        final isAnimal = animalProductCategoryIds.contains(product.categoryId);
        if (isAnimal) {
          // Для веганов — любое животное продукт исключает
          // Для вегетарианцев — мясо/рыба исключает, молочка/яйца можно
          if (veganOnly || _isMeatOrFish(product)) {
            return false;
          }
        }
      }
      
      // Также проверяем заготовки (requiredPreps)
      // Здесь нужно было бы иметь BasePrep с categoryId, пока пропускаем
    }

    return true;
  }

  bool _isMeatOrFish(BaseProduct product) {
    // Эвристика: категории "мясо", "рыба", "птица" и т.п.
    final meatCategories = {
      'cat_meat', 'cat_fish', 'cat_poultry', 'cat_seafood', 'cat_deli',
    };
    return meatCategories.contains(product.categoryId);
  }

  /// Создаёт копию с изменёнными параметрами.
  RecipeFilter copyWith({
    Set<String>? excludedProductIds,
    Set<String>? requiredProductIds,
    bool? vegetarianOnly,
    bool? veganOnly,
    bool? favoritesOnly,
    int? maxCookingTimeMinutes,
    Set<String>? excludedRecipeIds,
    Set<String>? animalProductCategoryIds,
  }) {
    return RecipeFilter(
      excludedProductIds: excludedProductIds ?? this.excludedProductIds,
      requiredProductIds: requiredProductIds ?? this.requiredProductIds,
      vegetarianOnly: vegetarianOnly ?? this.vegetarianOnly,
      veganOnly: veganOnly ?? this.veganOnly,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      maxCookingTimeMinutes: maxCookingTimeMinutes ?? this.maxCookingTimeMinutes,
      excludedRecipeIds: excludedRecipeIds ?? this.excludedRecipeIds,
      animalProductCategoryIds: animalProductCategoryIds ?? this.animalProductCategoryIds,
    );
  }
}

/// Результат масштабирования рецепта на новое количество порций.
class ScaledRecipe {
  final Recipe originalRecipe;
  final int targetServings;
  final List<ScaledIngredient> scaledIngredients;
  final List<ScaledPrepRequirement> scaledPreps;
  final List<RecipeStep> steps; // шаги не меняются
  final int scaledCookingTimeMinutes; // время может масштабироваться

  ScaledRecipe({
    required this.originalRecipe,
    required this.targetServings,
    required this.scaledIngredients,
    required this.scaledPreps,
    required this.steps,
    required this.scaledCookingTimeMinutes,
  });

  /// Фактор масштабирования (targetServings / baseServings).
  double get scaleFactor => targetServings / originalRecipe.baseServings;

  /// Создаёт RecipeMatchResult для масштабированного рецепта.
  RecipeMatchResult toMatchResult({
    required List<ItemVariant> productStock,
    required List<ItemVariant> prepStock,
    Map<String, double> manualAdditions = const {},
  }) {
    // Используем Recipe.recipe для matchRecipe, но с отмасштабированными ингредиентами
    // Проще: создаём временный Recipe с новыми количествами
    final tempRecipe = Recipe(
      id: originalRecipe.id,
      title: originalRecipe.title,
      type: originalRecipe.type,
      menuRoles: originalRecipe.menuRoles,
      ingredients: scaledIngredients.map((s) => RecipeIngredient(
        id: s.ingredientId,
        baseProductId: s.baseProductId,
        baseProductName: s.baseProductName,
        quantity: s.scaledQuantity,
        unit: s.unit,
      )).toList(),
      requiredPreps: scaledPreps.map((s) => RecipePrepRequirement(
        id: s.prepRequirementId,
        basePrepId: s.basePrepId,
        basePrepName: s.basePrepName,
        quantity: s.scaledQuantity,
        unit: s.unit,
      )).toList(),
      steps: originalRecipe.steps,
      baseServings: targetServings, // теперь базовые порции = целевые
      cookingTimeMinutes: scaledCookingTimeMinutes,
      producesPrep: originalRecipe.producesPrep != null 
          ? PrepYield(
              basePrepId: originalRecipe.producesPrep!.basePrepId,
              basePrepName: originalRecipe.producesPrep!.basePrepName,
              quantity: originalRecipe.producesPrep!.quantity * scaleFactor,
              unit: originalRecipe.producesPrep!.unit,
            )
          : null,
      isFavorite: originalRecipe.isFavorite,
      imageUrl: originalRecipe.imageUrl,
    );
    
    return matchRecipe(
      recipe: tempRecipe,
      productStock: productStock,
      prepStock: prepStock,
    );
  }
}

class ScaledIngredient {
  final String ingredientId;
  final String baseProductId;
  final String baseProductName;
  final double scaledQuantity;
  final Unit unit;

  ScaledIngredient({
    required this.ingredientId,
    required this.baseProductId,
    required this.baseProductName,
    required this.scaledQuantity,
    required this.unit,
  });
}

class ScaledPrepRequirement {
  final String prepRequirementId;
  final String basePrepId;
  final String basePrepName;
  final double scaledQuantity;
  final Unit unit;

  ScaledPrepRequirement({
    required this.prepRequirementId,
    required this.basePrepId,
    required this.basePrepName,
    required this.scaledQuantity,
    required this.unit,
  });
}

/// Масштабирует рецепт на новое количество порций.
ScaledRecipe scaleRecipe({
  required Recipe recipe,
  required int targetServings,
  bool scaleCookingTime = false, // по умолчанию время не масштабируем
}) {
  if (targetServings <= 0) {
    throw ArgumentError('targetServings должен быть > 0');
  }
  
  if (targetServings == recipe.baseServings) {
    return ScaledRecipe(
      originalRecipe: recipe,
      targetServings: targetServings,
      scaledIngredients: recipe.ingredients.map((i) => ScaledIngredient(
        ingredientId: i.id,
        baseProductId: i.baseProductId,
        baseProductName: i.baseProductName,
        scaledQuantity: i.quantity,
        unit: i.unit,
      )).toList(),
      scaledPreps: recipe.requiredPreps.map((p) => ScaledPrepRequirement(
        prepRequirementId: p.id,
        basePrepId: p.basePrepId,
        basePrepName: p.basePrepName,
        scaledQuantity: p.quantity,
        unit: p.unit,
      )).toList(),
      steps: recipe.steps,
      scaledCookingTimeMinutes: recipe.cookingTimeMinutes,
    );
  }

  final factor = targetServings / recipe.baseServings;

  return ScaledRecipe(
    originalRecipe: recipe,
    targetServings: targetServings,
    scaledIngredients: recipe.ingredients.map((i) => ScaledIngredient(
      ingredientId: i.id,
      baseProductId: i.baseProductId,
      baseProductName: i.baseProductName,
      scaledQuantity: i.quantity * factor,
      unit: i.unit,
    )).toList(),
    scaledPreps: recipe.requiredPreps.map((p) => ScaledPrepRequirement(
      prepRequirementId: p.id,
      basePrepId: p.basePrepId,
      basePrepName: p.basePrepName,
      scaledQuantity: p.quantity * factor,
      unit: p.unit,
    )).toList(),
    steps: recipe.steps,
    scaledCookingTimeMinutes: scaleCookingTime 
        ? (recipe.cookingTimeMinutes * factor).round() 
        : recipe.cookingTimeMinutes,
  );
}

/// Фильтрует список рецептов по заданным критериям.
List<Recipe> filterRecipes({
  required List<Recipe> recipes,
  required RecipeFilter filter,
  required Map<String, BaseProduct> productsById,
}) {
  return recipes.where((r) => filter.matches(r, productsById)).toList();
}