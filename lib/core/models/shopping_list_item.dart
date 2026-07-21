// lib/core/models/shopping_list_item.dart
//
// ShoppingListItem — отдельный пункт в списке покупок.
// Ссылается на BaseProduct (уровень "Молоко"), а не на конкретный вид —
// в магазине неважно, брать безлактозное или обычное, если явно
// не указано (это можно уточнить как отдельную будущую доработку).
// Заготовки в список покупок не попадают — их не покупают, а готовят.

import 'enums.dart';

enum ShoppingReason {
  forRecipe, // не хватает для конкретного рецепта
  runningLow, // заканчивается в запасах
  manual, // добавлено пользователем вручную
}

class ShoppingListItem {
  final String id;
  final String baseProductId; // ссылка на BaseProduct.id
  final String baseProductName; // "Молоко" — для отображения
  final double quantity;
  final Unit unit;
  final ShoppingReason reason;
  final String? relatedRecipeId; // заполнено, если reason == forRecipe
  bool isChecked;

  ShoppingListItem({
    required this.id,
    required this.baseProductId,
    required this.baseProductName,
    required this.quantity,
    required this.unit,
    required this.reason,
    this.relatedRecipeId,
    this.isChecked = false,
  });
}