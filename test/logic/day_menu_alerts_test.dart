// test/logic/day_menu_alerts_test.dart
//
// Тесты для агрегации дневных оповещений и ре-валидации.

import 'package:flutter_test/flutter_test.dart';
import 'package:freezzy/core/logic/day_menu_alerts.dart';
import 'package:freezzy/core/logic/recipe_matching.dart';
import 'package:freezzy/core/models/enums.dart';
import 'package:freezzy/core/models/recipe.dart';
import 'package:freezzy/core/models/generated_menu.dart';
import 'package:freezzy/core/models/item_variant.dart';

void main() {
  final simpleRecipe = Recipe(
    id: 'r_omelet',
    title: 'Омлет',
    ingredients: [
      RecipeIngredient(id: 'i1', baseProductId: 'bp_eggs', baseProductName: 'Яйца', quantity: 2, unit: Unit.pieces),
      RecipeIngredient(id: 'i2', baseProductId: 'bp_milk', baseProductName: 'Молоко', quantity: 100, unit: Unit.milliliters),
    ],
    requiredPreps: [],
    steps: [],
    baseServings: 1,
    cookingTimeMinutes: 10,
  );

  final stockRecipe = Recipe(
    id: 'r_plov',
    title: 'Плов',
    ingredients: [
      RecipeIngredient(id: 'i3', baseProductId: 'bp_rice', baseProductName: 'Рис', quantity: 200, unit: Unit.grams),
      RecipeIngredient(id: 'i4', baseProductId: 'bp_chicken', baseProductName: 'Курица', quantity: 200, unit: Unit.grams),
    ],
    requiredPreps: [],
    steps: [],
    baseServings: 4,
    cookingTimeMinutes: 40,
  );

  final recipesById = {
    'r_omelet': simpleRecipe,
    'r_plov': stockRecipe,
  };

  group('computeDayAlerts', () {
    test('detects missing ingredients', () {
      final menu = GeneratedMenu(
        id: 'menu1',
        planTemplateId: 'plan1',
        date: DateTime.now(),
        dishes: [
          MenuDish(id: 'd1', mealSlotId: 'breakfast', fulfilledComponentSlotIds: ['slot1'], recipeId: 'r_omelet'),
        ],
      );

      // Только 1 яйцо в наличии, нужно 2. Молоко есть.
      final productStock = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_eggs', name: 'Яйца',
          zone: StockingZone.fridge, quantity: 1, unit: Unit.pieces,
          addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_milk', name: 'Молоко',
          zone: StockingZone.fridge, quantity: 200, unit: Unit.milliliters,
          addedDate: DateTime.now(),
        ),
      ];

      final alerts = computeDayAlerts(
        menu: menu,
        recipesById: recipesById,
        productStock: productStock,
        prepStock: [],
      );

      expect(alerts.hasMissingIngredients, isTrue);
      expect(alerts.missingIngredients.length, 1);
      expect(alerts.missingIngredients.first.baseItemId, 'bp_eggs');
      expect(alerts.missingIngredients.first.quantityInBaseUnit, 1);
    });

    test('aggregates missing across multiple recipes', () {
      final menu = GeneratedMenu(
        id: 'menu1',
        planTemplateId: 'plan1',
        date: DateTime.now(),
        dishes: [
          MenuDish(id: 'd1', mealSlotId: 'lunch', fulfilledComponentSlotIds: ['slot1'], recipeId: 'r_plov'),
        ],
      );

      // Нет ни риса, ни курицы
      final alerts = computeDayAlerts(
        menu: menu,
        recipesById: recipesById,
        productStock: [],
        prepStock: [],
      );

      expect(alerts.missingIngredients.length, 2);
      final missingIds = alerts.missingIngredients.map((m) => m.baseItemId).toSet();
      expect(missingIds, containsAll(['bp_rice', 'bp_chicken']));
    });

    test('detects frozen ingredients needing defrost', () {
      final menu = GeneratedMenu(
        id: 'menu1',
        planTemplateId: 'plan1',
        date: DateTime.now(),
        dishes: [
          MenuDish(id: 'd1', mealSlotId: 'lunch', fulfilledComponentSlotIds: ['slot1'], recipeId: 'r_plov'),
        ],
      );

      final productStock = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_rice', name: 'Рис',
          zone: StockingZone.pantry, quantity: 500, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_chicken', name: 'Курица',
          zone: StockingZone.freezer, quantity: 300, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      final alerts = computeDayAlerts(
        menu: menu,
        recipesById: recipesById,
        productStock: productStock,
        prepStock: [],
      );

      expect(alerts.hasItemsToDefrost, isTrue);
      expect(alerts.needsDefrostIngredients.length, 1);
      expect(alerts.needsDefrostIngredients.first.baseItemId, 'bp_chicken');
    });

    test('virtual stock prevents double-counting', () {
      final menu = GeneratedMenu(
        id: 'menu1',
        planTemplateId: 'plan1',
        date: DateTime.now(),
        dishes: [
          // Два блюда, оба используют курицу
          MenuDish(id: 'd1', mealSlotId: 'lunch', fulfilledComponentSlotIds: ['slot1'], recipeId: 'r_plov'),
          MenuDish(id: 'd2', mealSlotId: 'dinner', fulfilledComponentSlotIds: ['slot1'], recipeId: 'r_plov'),
        ],
      );

      // Только 300г курицы, нужно 400г (200г * 2 блюда)
      final productStock = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_rice', name: 'Рис',
          zone: StockingZone.pantry, quantity: 1000, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_chicken', name: 'Курица',
          zone: StockingZone.freezer, quantity: 300, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      final alerts = computeDayAlerts(
        menu: menu,
        recipesById: recipesById,
        productStock: productStock,
        prepStock: [],
      );

      // Должно не хватить 100г курицы (400 - 300)
      final chickenMissing = alerts.missingIngredients.firstWhere(
        (m) => m.baseItemId == 'bp_chicken'
      );
      expect(chickenMissing.quantityInBaseUnit, 100);
    });
  });

  group('recomputeDayAlertsWithManualAdditions', () {
    test('re-validation reduces missing ingredients', () {
      final menu = GeneratedMenu(
        id: 'menu1',
        planTemplateId: 'plan1',
        date: DateTime.now(),
        dishes: [
          MenuDish(id: 'd1', mealSlotId: 'lunch', fulfilledComponentSlotIds: ['slot1'], recipeId: 'r_plov'),
        ],
      );

      final productStock = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_rice', name: 'Рис',
          zone: StockingZone.pantry, quantity: 500, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_chicken', name: 'Курица',
          zone: StockingZone.freezer, quantity: 100, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      // Без ручного добавления: не хватает 100г курицы
      final alertsBefore = computeDayAlerts(
        menu: menu,
        recipesById: recipesById,
        productStock: productStock,
        prepStock: [],
      );
      expect(alertsBefore.missingIngredients.length, 1);

      // С ручным добавлением 100г курицы: хватает
      final alertsAfter = recomputeDayAlertsWithManualAdditions(
        menu: menu,
        recipesById: recipesById,
        productStock: productStock,
        prepStock: [],
        manualAdditions: {'bp_chicken': 100.0},
      );

      expect(alertsAfter.missingIngredients.length, 0);
    });

    test('re-validation updates defrost alerts', () {
      final menu = GeneratedMenu(
        id: 'menu1',
        planTemplateId: 'plan1',
        date: DateTime.now(),
        dishes: [
          MenuDish(id: 'd1', mealSlotId: 'lunch', fulfilledComponentSlotIds: ['slot1'], recipeId: 'r_plov'),
        ],
      );

      final productStock = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_rice', name: 'Рис',
          zone: StockingZone.pantry, quantity: 500, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_chicken', name: 'Курица замороженная',
          zone: StockingZone.freezer, quantity: 100, unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      final alertsBefore = computeDayAlerts(
        menu: menu,
        recipesById: recipesById,
        productStock: productStock,
        prepStock: [],
      );
      expect(alertsBefore.hasItemsToDefrost, isTrue);

      // Добавляем 100г курицы "из холодильника"
      final alertsAfter = recomputeDayAlertsWithManualAdditions(
        menu: menu,
        recipesById: recipesById,
        productStock: productStock,
        prepStock: [],
        manualAdditions: {'bp_chicken': 100.0},
      );

      // Теперь хватает (100 в морозилке + 100 ручных = 200)
      final chickenMissing = alertsAfter.missingIngredients
          .where((m) => m.baseItemId == 'bp_chicken')
          .toList();
      expect(chickenMissing.isEmpty, isTrue);
    });
  });
}
