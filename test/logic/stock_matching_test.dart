// test/logic/stock_matching_test.dart
//
// Тесты для логики сопоставления ингредиентов со складом.

import 'package:flutter_test/flutter_test.dart';
import 'package:freezzy/core/logic/stock_matching.dart';
import 'package:freezzy/core/models/enums.dart';
import 'package:freezzy/core/models/item_variant.dart';

void main() {
  group('matchIngredient', () {
    test('returns sufficient when stock covers requirement', () {
      final stock = [
        ProductVariant(
          id: 'p1',
          baseItemId: 'bp_eggs',
          name: 'Яйца',
          zone: StockingZone.fridge,
          quantity: 10,
          unit: Unit.pieces,
          addedDate: DateTime.now(),
        ),
      ];

      final result = matchIngredient(
        baseItemId: 'bp_eggs',
        displayName: 'Яйца',
        requiredQuantity: 5,
        requiredUnit: Unit.pieces,
        availableVariants: stock,
      );

      expect(result.isSufficient, isTrue);
      expect(result.missingInBaseUnit, 0);
      expect(result.availableInBaseUnit, 10);
      expect(result.unitType, Unit.pieces);
    });

    test('returns missing when stock insufficient', () {
      final stock = [
        ProductVariant(
          id: 'p1',
          baseItemId: 'bp_eggs',
          name: 'Яйца',
          zone: StockingZone.fridge,
          quantity: 3,
          unit: Unit.pieces,
          addedDate: DateTime.now(),
        ),
      ];

      final result = matchIngredient(
        baseItemId: 'bp_eggs',
        displayName: 'Яйца',
        requiredQuantity: 5,
        requiredUnit: Unit.pieces,
        availableVariants: stock,
      );

      expect(result.isSufficient, isFalse);
      expect(result.missingInBaseUnit, 2);
    });

    test('uses FEFO ordering - expiring first', () {
      final now = DateTime.now();
      final stock = [
        ProductVariant(
          id: 'p1',
          baseItemId: 'bp_milk',
          name: 'Молоко свежее',
          zone: StockingZone.fridge,
          quantity: 500,
          unit: Unit.milliliters,
          addedDate: now.subtract(const Duration(days: 1)),
          expiryDate: now.add(const Duration(days: 10)),
        ),
        ProductVariant(
          id: 'p2',
          baseItemId: 'bp_milk',
          name: 'Молоко скоро пропьётся',
          zone: StockingZone.fridge,
          quantity: 500,
          unit: Unit.milliliters,
          addedDate: now.subtract(const Duration(days: 5)),
          expiryDate: now.add(const Duration(days: 1)), // истекает раньше
        ),
      ];

      final result = matchIngredient(
        baseItemId: 'bp_milk',
        displayName: 'Молоко',
        requiredQuantity: 500,
        requiredUnit: Unit.milliliters,
        availableVariants: stock,
      );

      // Должна использоваться партия с ближайшим сроком годности
      expect(result.allocations.length, 1);
      expect(result.allocations.first.variantId, 'p2');
      expect(result.usesExpiringStock, isTrue);
    });

    test('detects frozen ingredients needing defrost', () {
      final stock = [
        ProductVariant(
          id: 'p1',
          baseItemId: 'bp_chicken',
          name: 'Курица замороженная',
          zone: StockingZone.freezer,
          quantity: 500,
          unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      final result = matchIngredient(
        baseItemId: 'bp_chicken',
        displayName: 'Курица',
        requiredQuantity: 300,
        requiredUnit: Unit.grams,
        availableVariants: stock,
      );

      expect(result.needsDefrost, isTrue);
      expect(result.allocations.first.fromFreezer, isTrue);
    });

    test('manual additions make insufficient stock sufficient', () {
      final stock = [
        ProductVariant(
          id: 'p1',
          baseItemId: 'bp_meat',
          name: 'Фарш',
          zone: StockingZone.freezer,
          quantity: 100,
          unit: Unit.grams,
          addedDate: DateTime.now(),
        ),
      ];

      // Без ручного добавления: не хватает 200г
      final resultWithoutManual = matchIngredient(
        baseItemId: 'bp_meat',
        displayName: 'Фарш',
        requiredQuantity: 300,
        requiredUnit: Unit.grams,
        availableVariants: stock,
      );
      expect(resultWithoutManual.isSufficient, isFalse);
      expect(resultWithoutManual.missingInBaseUnit, 200);

      // С ручным добавлением 200г: хватает
      final resultWithManual = matchIngredient(
        baseItemId: 'bp_meat',
        displayName: 'Фарш',
        requiredQuantity: 300,
        requiredUnit: Unit.grams,
        availableVariants: stock,
        manualAdditions: {'bp_meat': 200.0},
      );
      expect(resultWithManual.isSufficient, isTrue);
      expect(resultWithManual.missingInBaseUnit, 0);
    });

    test('converts units correctly (kg to g)', () {
      final stock = [
        ProductVariant(
          id: 'p1',
          baseItemId: 'bp_rice',
          name: 'Рис',
          zone: StockingZone.pantry,
          quantity: 1, // 1 кг
          unit: Unit.kilograms,
          addedDate: DateTime.now(),
        ),
      ];

      final result = matchIngredient(
        baseItemId: 'bp_rice',
        displayName: 'Рис',
        requiredQuantity: 1500, // 1500 г
        requiredUnit: Unit.grams,
        availableVariants: stock,
      );

      // 1 кг = 1000 г, нужно 1500 г → не хватает 500 г
      expect(result.isSufficient, isFalse);
      expect(result.missingInBaseUnit, 500);
      expect(result.availableInBaseUnit, 1000);
    });
  });

  group('groupVariantsByBaseItem', () {
    test('groups variants by baseItemId', () {
      final variants = [
        ProductVariant(
          id: 'p1', baseItemId: 'bp_1', name: 'A', zone: StockingZone.fridge,
          quantity: 100, unit: Unit.grams, addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p2', baseItemId: 'bp_1', name: 'B', zone: StockingZone.fridge,
          quantity: 200, unit: Unit.grams, addedDate: DateTime.now(),
        ),
        ProductVariant(
          id: 'p3', baseItemId: 'bp_2', name: 'C', zone: StockingZone.pantry,
          quantity: 300, unit: Unit.grams, addedDate: DateTime.now(),
        ),
      ];

      final grouped = groupVariantsByBaseItem(variants);

      expect(grouped.length, 2);
      expect(grouped['bp_1']!.length, 2);
      expect(grouped['bp_2']!.length, 1);
    });
  });
}
