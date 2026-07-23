import 'package:flutter_test/flutter_test.dart';
import 'package:freezzy/core/logic/shopping_list_logic.dart';
import 'package:freezzy/core/logic/day_menu_alerts.dart';
import 'package:freezzy/core/models/shopping_list.dart';
import 'package:freezzy/core/models/shopping_list_item.dart';
import 'package:freezzy/core/models/base_item.dart';
import 'package:freezzy/core/models/category.dart';
import 'package:freezzy/core/models/cooking_session.dart';
import 'package:freezzy/core/models/enums.dart';

int _idCounter = 0;
String generateId() => 'id_${_idCounter++}';

void main() {
  setUp(() {
    _idCounter = 0;
  });

  final productsById = {
    'bp_milk': BaseProduct(
      id: 'bp_milk', name: 'Молоко', categoryId: 'cat_dairy',
      menuRoles: [MenuRole.dairy], defaultZone: StockingZone.fridge,
      defaultUnit: Unit.milliliters,
    ),
    'bp_chicken': BaseProduct(
      id: 'bp_chicken', name: 'Курица', categoryId: 'cat_meat',
      menuRoles: [MenuRole.protein], defaultZone: StockingZone.fridge,
      defaultUnit: Unit.grams,
    ),
    'bp_carrot': BaseProduct(
      id: 'bp_carrot', name: 'Морковь', categoryId: 'cat_veg',
      menuRoles: [MenuRole.vegetable], defaultZone: StockingZone.fridge,
      defaultUnit: Unit.grams,
    ),
    'bp_salt': BaseProduct(
      id: 'bp_salt', name: 'Соль', categoryId: 'cat_spice',
      menuRoles: [MenuRole.spiceOrCondiment], defaultZone: StockingZone.pantry,
      defaultUnit: Unit.grams, alwaysInStock: true,
    ),
  };

  final categories = [
    Category(id: 'cat_dairy', name: 'Молочные продукты'),
    Category(id: 'cat_meat', name: 'Мясо и птица'),
    Category(id: 'cat_veg', name: 'Овощи'),
    Category(id: 'cat_spice', name: 'Специи'),
  ];

  final shoppingList = ShoppingList(id: 'sl_1', createdAt: DateTime.now());

  group('addMissingFromDayAlerts', () {
    test('creates items for missing ingredients', () {
      final needs = [
        DayIngredientNeed(baseItemId: 'bp_milk', displayName: 'Молоко', quantityInBaseUnit: 500, recipeIds: ['r1']),
        DayIngredientNeed(baseItemId: 'bp_chicken', displayName: 'Курица', quantityInBaseUnit: 300, recipeIds: ['r2']),
      ];

      final items = addMissingFromDayAlerts(
        missingIngredients: needs,
        existingItems: [],
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 2);
      expect(items[0].baseProductName, 'Молоко');
      expect(items[0].quantity, 500);
      expect(items[0].unit, Unit.milliliters);
      expect(items[0].categoryId, 'cat_dairy');
      expect(items[0].reason, ShoppingReason.forRecipe);
    });

    test('sums quantities for duplicate baseProductId', () {
      final needs = [
        DayIngredientNeed(baseItemId: 'bp_milk', displayName: 'Молоко', quantityInBaseUnit: 500, recipeIds: ['r1']),
        DayIngredientNeed(baseItemId: 'bp_milk', displayName: 'Молоко', quantityInBaseUnit: 200, recipeIds: ['r2']),
      ];

      final items = addMissingFromDayAlerts(
        missingIngredients: needs,
        existingItems: [],
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 1);
      expect(items[0].quantity, 700);
    });

    test('merges into existing items', () {
      final existing = [
        ShoppingListItem(id: 'existing_1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 100, unit: Unit.milliliters, reason: ShoppingReason.manual),
      ];

      final needs = [
        DayIngredientNeed(baseItemId: 'bp_milk', displayName: 'Молоко', quantityInBaseUnit: 500, recipeIds: ['r1']),
      ];

      final items = addMissingFromDayAlerts(
        missingIngredients: needs,
        existingItems: existing,
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 1);
      expect(items[0].quantity, 600);
    });

    test('skips alwaysInStock products', () {
      final needs = [
        DayIngredientNeed(baseItemId: 'bp_salt', displayName: 'Соль', quantityInBaseUnit: 50, recipeIds: ['r1']),
      ];

      final items = addMissingFromDayAlerts(
        missingIngredients: needs,
        existingItems: [],
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 0);
    });

    test('skips unknown products', () {
      final needs = [
        DayIngredientNeed(baseItemId: 'unknown', displayName: 'Что-то', quantityInBaseUnit: 100, recipeIds: ['r1']),
      ];

      final items = addMissingFromDayAlerts(
        missingIngredients: needs,
        existingItems: [],
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 0);
    });
  });

  group('addDepletedFromCooking', () {
    test('creates items for depleted products', () {
      final depleted = [
        DepletedProduct(baseProductId: 'bp_milk', baseProductName: 'Молоко', consumedQuantity: 500, unit: Unit.milliliters),
      ];

      final items = addDepletedFromCooking(
        depletedProducts: depleted,
        existingItems: [],
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 1);
      expect(items[0].baseProductName, 'Молоко');
      expect(items[0].quantity, 500);
      expect(items[0].reason, ShoppingReason.forRecipe);
    });

    test('merges into existing items', () {
      final existing = [
        ShoppingListItem(id: 'existing_1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 200, unit: Unit.milliliters, reason: ShoppingReason.forRecipe),
      ];

      final depleted = [
        DepletedProduct(baseProductId: 'bp_milk', baseProductName: 'Молоко', consumedQuantity: 300, unit: Unit.milliliters),
      ];

      final items = addDepletedFromCooking(
        depletedProducts: depleted,
        existingItems: existing,
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 1);
      expect(items[0].quantity, 500);
    });

    test('skips alwaysInStock products', () {
      final depleted = [
        DepletedProduct(baseProductId: 'bp_salt', baseProductName: 'Соль', consumedQuantity: 10, unit: Unit.grams),
      ];

      final items = addDepletedFromCooking(
        depletedProducts: depleted,
        existingItems: [],
        shoppingListId: shoppingList.id,
        productsById: productsById,
        generateId: generateId,
      );

      expect(items.length, 0);
    });
  });

  group('categorizeItems', () {
    test('groups items by category', () {
      final items = [
        ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe),
        ShoppingListItem(id: 'i2', shoppingListId: shoppingList.id,
            baseProductId: 'bp_chicken', baseProductName: 'Курица', categoryId: 'cat_meat',
            quantity: 300, unit: Unit.grams, reason: ShoppingReason.forRecipe),
        ShoppingListItem(id: 'i3', shoppingListId: shoppingList.id,
            baseProductId: 'bp_carrot', baseProductName: 'Морковь', categoryId: 'cat_veg',
            quantity: 200, unit: Unit.grams, reason: ShoppingReason.forRecipe),
      ];

      final grouped = categorizeItems(items: items, categories: categories);

      expect(grouped.length, 3);
      expect(grouped[categories[0]]!.length, 1); // Молочные: 1
      expect(grouped[categories[0]]![0].baseProductName, 'Молоко');
      expect(grouped[categories[1]]!.length, 1); // Мясо: 1
      expect(grouped[categories[2]]!.length, 1); // Овощи: 1
      expect(grouped[categories[3]], isNull);  // Специи: пусто
    });

    test('puts same category items together', () {
      final items = [
        ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_chicken', baseProductName: 'Курица', categoryId: 'cat_meat',
            quantity: 300, unit: Unit.grams, reason: ShoppingReason.forRecipe),
        ShoppingListItem(id: 'i2', shoppingListId: shoppingList.id,
            baseProductId: 'bp_carrot', baseProductName: 'Морковь', categoryId: 'cat_veg',
            quantity: 200, unit: Unit.grams, reason: ShoppingReason.forRecipe),
        ShoppingListItem(id: 'i3', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe),
      ];

      final grouped = categorizeItems(items: items, categories: categories);

      expect(grouped[categories[0]]!.length, 1); // Молочные: Молоко
      expect(grouped[categories[1]]!.length, 1); // Мясо: Курица
      expect(grouped[categories[2]]!.length, 1); // Овощи: Морковь
    });

    test('returns empty map for empty items', () {
      final grouped = categorizeItems(items: [], categories: categories);
      expect(grouped.isEmpty, true);
    });
  });

  group('addManualItem', () {
    test('creates manual shopping list item', () {
      final product = productsById['bp_milk']!;
      final item = addManualItem(
        shoppingListId: shoppingList.id,
        product: product,
        quantity: 1000,
        generateId: generateId,
      );

      expect(item.baseProductId, 'bp_milk');
      expect(item.baseProductName, 'Молоко');
      expect(item.categoryId, 'cat_dairy');
      expect(item.quantity, 1000);
      expect(item.unit, Unit.milliliters);
      expect(item.reason, ShoppingReason.manual);
      expect(item.isChecked, false);
    });
  });

  group('mutation helpers', () {
    test('markAllAsChecked checks all items', () {
      final items = [
        ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe),
        ShoppingListItem(id: 'i2', shoppingListId: shoppingList.id,
            baseProductId: 'bp_chicken', baseProductName: 'Курица', categoryId: 'cat_meat',
            quantity: 300, unit: Unit.grams, reason: ShoppingReason.forRecipe),
      ];

      markAllAsChecked(items);
      expect(items.every((i) => i.isChecked), true);
    });

    test('clearAllChecks unchecks all items', () {
      final items = [
        ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe, isChecked: true),
        ShoppingListItem(id: 'i2', shoppingListId: shoppingList.id,
            baseProductId: 'bp_chicken', baseProductName: 'Курица', categoryId: 'cat_meat',
            quantity: 300, unit: Unit.grams, reason: ShoppingReason.forRecipe, isChecked: true),
      ];

      clearAllChecks(items);
      expect(items.every((i) => !i.isChecked), true);
    });

    test('removeChecked removes only checked items', () {
      final items = [
        ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe, isChecked: true),
        ShoppingListItem(id: 'i2', shoppingListId: shoppingList.id,
            baseProductId: 'bp_chicken', baseProductName: 'Курица', categoryId: 'cat_meat',
            quantity: 300, unit: Unit.grams, reason: ShoppingReason.forRecipe, isChecked: false),
      ];

      final remaining = removeChecked(items);
      expect(remaining.length, 1);
      expect(remaining[0].baseProductId, 'bp_chicken');
    });

    test('clearAll returns empty list', () {
      final items = [
        ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
            baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
            quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe),
      ];

      expect(clearAll(items), []);
    });

    test('archiveList changes status to archived', () {
      final list = ShoppingList(id: 'sl_1', createdAt: DateTime.now());
      final archived = archiveList(list);
      expect(archived.status, ShoppingListStatus.archived);
    });
  });

  group('ShoppingListItem mutable quantity', () {
    test('quantity can be changed directly', () {
      final item = ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
          baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
          quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe);

      item.quantity = 750;
      expect(item.quantity, 750);
    });

    test('isChecked can be toggled', () {
      final item = ShoppingListItem(id: 'i1', shoppingListId: shoppingList.id,
          baseProductId: 'bp_milk', baseProductName: 'Молоко', categoryId: 'cat_dairy',
          quantity: 500, unit: Unit.milliliters, reason: ShoppingReason.forRecipe);

      expect(item.isChecked, false);
      item.isChecked = true;
      expect(item.isChecked, true);
    });
  });
}
