// test/logic/recipe_filtering_test.dart
//
// Тесты для фильтрации рецептов и масштабирования порций.

import 'package:flutter_test/flutter_test.dart';
import 'package:freezzy/core/logic/recipe_filtering.dart';
import 'package:freezzy/core/models/enums.dart';
import 'package:freezzy/core/models/recipe.dart';
import 'package:freezzy/core/models/base_item.dart';

void main() {
  // Тестовые данные
  final productsById = {
    'bp_meat': BaseProduct(
      id: 'bp_meat', name: 'Фарш', categoryId: 'cat_meat',
      menuRoles: [MenuRole.protein], defaultZone: StockingZone.freezer,
      defaultUnit: Unit.grams,
    ),
    'bp_flour': BaseProduct(
      id: 'bp_flour', name: 'Мука', categoryId: 'cat_grain',
      menuRoles: [MenuRole.ingredient], defaultZone: StockingZone.pantry,
      defaultUnit: Unit.grams,
    ),
    'bp_eggs': BaseProduct(
      id: 'bp_eggs', name: 'Яйца', categoryId: 'cat_dairy',
      menuRoles: [MenuRole.protein, MenuRole.breakfastDish],
      defaultZone: StockingZone.fridge, defaultUnit: Unit.pieces,
    ),
    'bp_milk': BaseProduct(
      id: 'bp_milk', name: 'Молоко', categoryId: 'cat_dairy',
      menuRoles: [MenuRole.dairy, MenuRole.breakfastDish],
      defaultZone: StockingZone.fridge, defaultUnit: Unit.milliliters,
    ),
    'bp_tomato': BaseProduct(
      id: 'bp_tomato', name: 'Помидоры', categoryId: 'cat_veg',
      menuRoles: [MenuRole.vegetable, MenuRole.salad],
      defaultZone: StockingZone.fridge, defaultUnit: Unit.grams,
    ),
  };

  final meatRecipe = Recipe(
    id: 'r_meatballs',
    title: 'Фаршовые шарики',
    ingredients: [
      RecipeIngredient(id: 'i1', baseProductId: 'bp_meat', baseProductName: 'Фарш', quantity: 500, unit: Unit.grams),
      RecipeIngredient(id: 'i2', baseProductId: 'bp_flour', baseProductName: 'Мука', quantity: 100, unit: Unit.grams),
    ],
    requiredPreps: [],
    steps: [],
    baseServings: 4,
    cookingTimeMinutes: 30,
  );

  final vegetarianRecipe = Recipe(
    id: 'r_salad',
    title: 'Салат',
    ingredients: [
      RecipeIngredient(id: 'i3', baseProductId: 'bp_tomato', baseProductName: 'Помидоры', quantity: 200, unit: Unit.grams),
    ],
    requiredPreps: [],
    steps: [],
    baseServings: 2,
    cookingTimeMinutes: 10,
    isFavorite: true,
  );

  group('RecipeFilter.matches', () {
    test('passes recipe with no filters', () {
      final filter = RecipeFilter();
      expect(filter.matches(meatRecipe, productsById), isTrue);
    });

    test('excludes recipes with excluded ingredients', () {
      final filter = RecipeFilter(excludedProductIds: {'bp_meat'});
      expect(filter.matches(meatRecipe, productsById), isFalse);
      expect(filter.matches(vegetarianRecipe, productsById), isTrue);
    });

    test('requires at least one required ingredient', () {
      final filter = RecipeFilter(requiredProductIds: {'bp_meat'});
      expect(filter.matches(meatRecipe, productsById), isTrue);
      expect(filter.matches(vegetarianRecipe, productsById), isFalse);
    });

    test('vegetarianOnly excludes meat recipes', () {
      final filter = RecipeFilter(
        vegetarianOnly: true,
        animalProductCategoryIds: {'cat_meat', 'cat_fish', 'cat_poultry'},
      );
      expect(filter.matches(meatRecipe, productsById), isFalse);
      expect(filter.matches(vegetarianRecipe, productsById), isTrue);
    });

    test('favoritesOnly excludes non-favorite recipes', () {
      final filter = RecipeFilter(favoritesOnly: true);
      expect(filter.matches(meatRecipe, productsById), isFalse);
      expect(filter.matches(vegetarianRecipe, productsById), isTrue);
    });

    test('maxCookingTimeMinutes filters by time', () {
      final filter = RecipeFilter(maxCookingTimeMinutes: 20);
      expect(filter.matches(meatRecipe, productsById), isFalse); // 30 мин
      expect(filter.matches(vegetarianRecipe, productsById), isTrue); // 10 мин
    });

    test('excludedRecipeIds filters by recipe ID', () {
      final filter = RecipeFilter(excludedRecipeIds: {'r_meatballs'});
      expect(filter.matches(meatRecipe, productsById), isFalse);
    });
  });

  group('filterRecipes', () {
    test('filters list of recipes', () {
      final filter = RecipeFilter(excludedProductIds: {'bp_meat'});
      final recipes = [meatRecipe, vegetarianRecipe];

      final result = filterRecipes(
        recipes: recipes,
        filter: filter,
        productsById: productsById,
      );

      expect(result.length, 1);
      expect(result.first.id, 'r_salad');
    });
  });

  group('scaleRecipe', () {
    test('doubles ingredient quantities for 2x servings', () {
      final scaled = scaleRecipe(
        recipe: meatRecipe,
        targetServings: 8, // 2x от baseServings 4
      );

      expect(scaled.scaleFactor, 2.0);
      expect(scaled.scaledIngredients.length, 2);

      final meatIngredient = scaled.scaledIngredients.firstWhere(
        (i) => i.baseProductId == 'bp_meat'
      );
      expect(meatIngredient.scaledQuantity, 1000); // 500 * 2

      final flourIngredient = scaled.scaledIngredients.firstWhere(
        (i) => i.baseProductId == 'bp_flour'
      );
      expect(flourIngredient.scaledQuantity, 200); // 100 * 2
    });

    test('keeps cooking time when scaleCookingTime is false', () {
      final scaled = scaleRecipe(
        recipe: meatRecipe,
        targetServings: 8,
        scaleCookingTime: false,
      );
      expect(scaled.scaledCookingTimeMinutes, 30);
    });

    test('scales cooking time when scaleCookingTime is true', () {
      final scaled = scaleRecipe(
        recipe: meatRecipe,
        targetServings: 8,
        scaleCookingTime: true,
      );
      expect(scaled.scaledCookingTimeMinutes, 60); // 30 * 2
    });

    test('throws on zero or negative servings', () {
      expect(
        () => scaleRecipe(recipe: meatRecipe, targetServings: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns same quantities when servings match', () {
      final scaled = scaleRecipe(
        recipe: meatRecipe,
        targetServings: 4, // совпадает с baseServings
      );

      expect(scaled.scaleFactor, 1.0);
      final meatIngredient = scaled.scaledIngredients.firstWhere(
        (i) => i.baseProductId == 'bp_meat'
      );
      expect(meatIngredient.scaledQuantity, 500); // не изменено
    });

    test('handles fractional scaling correctly', () {
      final scaled = scaleRecipe(
        recipe: meatRecipe,
        targetServings: 2, // 0.5x от baseServings 4
      );

      expect(scaled.scaleFactor, 0.5);
      final meatIngredient = scaled.scaledIngredients.firstWhere(
        (i) => i.baseProductId == 'bp_meat'
      );
      expect(meatIngredient.scaledQuantity, 250); // 500 * 0.5
    });
  });
}
