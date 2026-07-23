// lib/core/logic/shopping_list_logic.dart
//
// Логика работы со списком покупок: добавление, слияние, группировка.

import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../models/base_item.dart';
import '../models/category.dart';
import '../models/cooking_session.dart';
import 'day_menu_alerts.dart';
import 'units.dart';

/// Вливает недостающие ингредиенты (из DayMenuAlerts) в список покупок.
/// Один продукт — одна строка: если такой baseProductId уже есть,
/// количество суммируется.
List<ShoppingListItem> addMissingFromDayAlerts({
  required List<DayIngredientNeed> missingIngredients,
  required List<ShoppingListItem> existingItems,
  required String shoppingListId,
  required Map<String, BaseProduct> productsById,
  required String Function() generateId,
}) {
  final result = List<ShoppingListItem>.from(existingItems);

  for (final need in missingIngredients) {
    final product = productsById[need.baseItemId];
    if (product == null) continue;
    if (product.alwaysInStock) continue;

    final qtyInDisplayUnit = fromBaseUnit(need.quantityInBaseUnit, product.defaultUnit);

    final idx = result.indexWhere((i) => i.baseProductId == need.baseItemId);
    if (idx >= 0) {
      result[idx].quantity += qtyInDisplayUnit;
    } else {
      result.add(ShoppingListItem(
        id: generateId(),
        shoppingListId: shoppingListId,
        baseProductId: need.baseItemId,
        baseProductName: need.displayName,
        categoryId: product.categoryId,
        quantity: qtyInDisplayUnit,
        unit: product.defaultUnit,
        reason: ShoppingReason.forRecipe,
        relatedRecipeId: need.recipeIds.length == 1 ? need.recipeIds.first : null,
      ));
    }
  }

  return result;
}

/// Вливает продукты, закончившиеся при готовке (DepletedProduct),
/// в список покупок. Аналогичное слияние по baseProductId.
List<ShoppingListItem> addDepletedFromCooking({
  required List<DepletedProduct> depletedProducts,
  required List<ShoppingListItem> existingItems,
  required String shoppingListId,
  required Map<String, BaseProduct> productsById,
  required String Function() generateId,
}) {
  final result = List<ShoppingListItem>.from(existingItems);

  for (final dp in depletedProducts) {
    final product = productsById[dp.baseProductId];
    if (product == null) continue;
    if (product.alwaysInStock) continue;

    final idx = result.indexWhere((i) => i.baseProductId == dp.baseProductId);
    if (idx >= 0) {
      result[idx].quantity += dp.consumedQuantity;
    } else {
      result.add(ShoppingListItem(
        id: generateId(),
        shoppingListId: shoppingListId,
        baseProductId: dp.baseProductId,
        baseProductName: dp.baseProductName,
        categoryId: product.categoryId,
        quantity: dp.consumedQuantity,
        unit: dp.unit,
        reason: ShoppingReason.forRecipe,
      ));
    }
  }

  return result;
}

/// Добавляет продукт вручную.
ShoppingListItem addManualItem({
  required String shoppingListId,
  required BaseProduct product,
  required double quantity,
  required String Function() generateId,
}) {
  return ShoppingListItem(
    id: generateId(),
    shoppingListId: shoppingListId,
    baseProductId: product.id,
    baseProductName: product.name,
    categoryId: product.categoryId,
    quantity: quantity,
    unit: product.defaultUnit,
    reason: ShoppingReason.manual,
  );
}

/// Группирует элементы списка по категориям.
/// Категории, в которых нет элементов, не включаются.
Map<Category, List<ShoppingListItem>> categorizeItems({
  required List<ShoppingListItem> items,
  required List<Category> categories,
}) {
  final catMap = {for (final c in categories) c.id: c};
  final result = <Category, List<ShoppingListItem>>{};

  for (final item in items) {
    final cat = catMap[item.categoryId];
    if (cat == null) continue;
    result.putIfAbsent(cat, () => []);
    result[cat]!.add(item);
  }

  return result;
}

/// Отмечает все элементы как купленные.
List<ShoppingListItem> markAllAsChecked(List<ShoppingListItem> items) {
  for (final item in items) {
    item.isChecked = true;
  }
  return items;
}

/// Снимает отметки со всех элементов.
List<ShoppingListItem> clearAllChecks(List<ShoppingListItem> items) {
  for (final item in items) {
    item.isChecked = false;
  }
  return items;
}

/// Удаляет купленные элементы из списка.
List<ShoppingListItem> removeChecked(List<ShoppingListItem> items) {
  return items.where((item) => !item.isChecked).toList();
}

/// Очищает список целиком.
List<ShoppingListItem> clearAll(List<ShoppingListItem> items) {
  return [];
}

/// Архивирует список (меняет статус).
ShoppingList archiveList(ShoppingList list) {
  return ShoppingList(
    id: list.id,
    createdAt: list.createdAt,
    status: ShoppingListStatus.archived,
  );
}
