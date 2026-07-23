// test/logic/prep_menu_generation_test.dart
//
// Тесты для генерации меню заготовок и завершения готовки.

import 'package:flutter_test/flutter_test.dart';
import 'package:freezzy/core/logic/prep_menu_generation.dart';
import 'package:freezzy/core/logic/recipe_matching.dart';
import 'package:freezzy/core/logic/stock_matching.dart';
import 'package:freezzy/core/models/enums.dart';
import 'package:freezzy/core/models/recipe.dart';
import 'package:freezzy/core/models/base_item.dart';
import 'package:freezzy/core/models/item_variant.dart';

void main() {
  final dumplingsBase = BasePrep(
    id: 'bprep_dumplings', name: 'Пельмени', categoryId: 'cat_prep',
    menuRoles: [MenuRole.protein], defaultZone: StockingZone.freezer,
    defaultUnit: Unit.grams, defaultShelfLifeDays: 60,
  );

  final dumplingsRecipe = Recipe(
    id: 'r_dumplings_prep',
    title: 'Пельмени домашние',
    type: RecipeType.prep,
    ingredients: [
      RecipeIngredient(id: 'i1', baseProductId: 'bp_flour', baseProductName: 'Мука', quantity: 500, unit: Unit.grams),
      RecipeIngredient(id: 'i2', baseProductId: 'bp_meat', baseProductName: 'Фарш', quantity: 500, unit: Unit.grams),
    ],
    requiredPreps: [],
    steps: [],
    baseServings: 6,
    cookingTimeMinutes: 90,
    producesPrep: PrepYield(
      basePrepId: 'bprep_dumplings',
      basePrepName: 'Пельмени',
      quantity: 1200,
      unit: Unit.grams,
    ),
  );

  final stockRecipe = Recipe(
    id: 'r_stock_prep',
    title: 'Бульон',
    type: RecipeType.prep,
    ingredients: [
      RecipeIngredient(id: 'i3', baseProductId: 'bp_carrot', baseProductName: 'Морковь', quantity: 100, unit: Unit.grams),
    ],
    requiredPreps: [],
    steps: [],
    baseServings: 2,
    cookingTimeMinutes: 60,
    producesPrep: PrepYield(
      basePrepId: 'bprep_stock',
      basePrepName: 'Бульон',
      quantity: 500,
      unit: Unit.milliliters,
    ),
  );

  final allRecipes = [dumplingsRecipe, stockRecipe];

  group('generatePrepMenu', () {
    test('generates correct number of recipes', () {
      final menu = generatePrepMenu(
        params: const PrepMenuParams(recipeCount: 2),
        date: DateTime.now(),
        allRecipes: allRecipes,
        productStock: [],
        prepStock: [],
        generateId: () => 'id_${DateTime.now().millisecondsSinceEpoch}',
      );

      expect(menu.dishes.length, 2);
    });

    test('only includes prep recipes (not meal recipes)', () {
      final mealRecipe = Recipe(
        id: 'r_omelet',
        title: 'Омлет',
        type: RecipeType.meal, // тип meal, не должен попадать
        ingredients: [],
        requiredPreps: [],
        steps: [],
        baseServings: 1,
        cookingTimeMinutes: 10,
      );

      final menu = generatePrepMenu(
        params: const PrepMenuParams(recipeCount: 5),
        date: DateTime.now(),
        allRecipes: [...allRecipes, mealRecipe],
        productStock: [],
        prepStock: [],
        generateId: () => 'id',
      );

      // Только 2 рецепта заготовки, mealRecipe не должен попасть
      expect(menu.dishes.length, 2);
      final recipeIds = menu.dishes.map((d) => d.recipeId).toSet();
      expect(recipeIds, isNot(contains('r_omelet')));
    });

    test('excludes recipes in excludedRecipeIds', () {
      final menu = generatePrepMenu(
        params: const PrepMenuParams(
          recipeCount: 5,
          excludedRecipeIds: {'r_dumplings_prep'},
        ),
        date: DateTime.now(),
        allRecipes: allRecipes,
        productStock: [],
        prepStock: [],
        generateId: () => 'id',
      );

      expect(menu.dishes.length, 1);
      expect(menu.dishes.first.recipeId, 'r_stock_prep');
    });

    test('pinned recipes preserved on regeneration', () {
      final firstMenu = generatePrepMenu(
        params: const PrepMenuParams(recipeCount: 2),
        date: DateTime.now(),
        allRecipes: allRecipes,
        productStock: [],
        prepStock: [],
        generateId: () => 'id',
      );

      // "Закрепляем" первый рецепт
      firstMenu.dishes.first.isPinned = true;

      final secondMenu = generatePrepMenu(
        params: const PrepMenuParams(recipeCount: 2),
        date: DateTime.now(),
        allRecipes: allRecipes,
        productStock: [],
        prepStock: [],
        generateId: () => 'id',
        previousMenu: firstMenu,
      );

      // Закреплённый рецепт должен быть в новом меню
      expect(secondMenu.dishes.any((d) => d.isPinned), isTrue);
    });

    test('preferred ingredients boost score', () {
      final stockWithMeat = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_meat', name: 'Фарш',
          zone: StockingZone.freezer, quantity: 1000, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      final menu = generatePrepMenu(
        params: const PrepMenuParams(
          recipeCount: 1,
          preferredProductIds: ['bp_meat'],
        ),
        date: DateTime.now(),
        allRecipes: allRecipes,
        productStock: stockWithMeat,
        prepStock: [],
        generateId: () => 'id',
      );

      // Рецепт с фаршем (dumplings) должен быть выбран
      expect(menu.dishes.first.recipeId, 'r_dumplings_prep');
    });
  });

  group('completePrepCooking', () {
    test('consumes ingredients and creates prep variant', () {
      final productStock = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_flour', name: 'Мука',
          zone: StockingZone.pantry, quantity: 1000, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_meat', name: 'Фарш',
          zone: StockingZone.freezer, quantity: 1000, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      final match = matchRecipe(
        recipe: dumplingsRecipe,
        productStock: productStock,
        prepStock: [],
      );

      final result = completePrepCooking(
        recipe: dumplingsRecipe,
        match: match,
        productStock: productStock,
        prepStock: [],
        basePrep: dumplingsBase,
        eatNowQuantity: 200, // съесть 200г сейчас
        storedQuantity: 1000, // 1000г на хранение
        storageZone: StockingZone.freezer,
        generateId: () => 'new_prep',
        addedDate: DateTime.now(),
      );

      // Проверяем списание
      expect(result.updatedProductStock.length, 2);

      // Проверяем создание заготовки
      expect(result.createdPrepVariant, isNotNull);
      expect(result.createdPrepVariant!.quantity, 1000);
      expect(result.createdPrepVariant!.zone, StockingZone.freezer);
      expect(result.createdPrepVariant!.baseItemId, 'bprep_dumplings');
    });

    test('returns null prepVariant when all eaten immediately', () {
      final productStock = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_flour', name: 'Мука',
          zone: StockingZone.pantry, quantity: 500, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_meat', name: 'Фарш',
          zone: StockingZone.freezer, quantity: 500, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      final match = matchRecipe(
        recipe: dumplingsRecipe,
        productStock: productStock,
        prepStock: [],
      );

      final result = completePrepCooking(
        recipe: dumplingsRecipe,
        match: match,
        productStock: productStock,
        prepStock: [],
        basePrep: dumplingsBase,
        eatNowQuantity: 1200, // всё съесть
        storedQuantity: 0, // ничего не хранить
        storageZone: StockingZone.freezer,
        generateId: () => 'new_prep',
        addedDate: DateTime.now(),
      );

      expect(result.createdPrepVariant, isNull);
    });
  });
}
