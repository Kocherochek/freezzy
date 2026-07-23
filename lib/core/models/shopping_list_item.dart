// lib/core/models/shopping_list_item.dart
//
// Отдельный пункт списка покупок. Теперь принадлежит конкретному
// ShoppingList через shoppingListId — без этого архивация списков
// была бы невозможна (нечего было бы группировать).
// Ссылается на BaseProduct, а не на конкретный вид — заготовки
// в список покупок не попадают, их не покупают, а готовят.

import 'enums.dart';

enum ShoppingReason {
  forRecipe, // не хватает для конкретного рецепта
  runningLow, // заканчивается в запасах
  manual, // добавлено пользователем вручную
}

class ShoppingListItem {
  final String id;
  final String shoppingListId; // ссылка на ShoppingList.id
  final String baseProductId; // ссылка на BaseProduct.id
  final String baseProductName; // "Молоко" — для отображения
  final String categoryId; // из BaseProduct.categoryId — для группировки
  double quantity; // можно редактировать в магазине
  final Unit unit;
  final ShoppingReason reason;
  final String? relatedRecipeId; // заполнено, если reason == forRecipe
  bool isChecked;

  ShoppingListItem({
    required this.id,
    required this.shoppingListId,
    required this.baseProductId,
    required this.baseProductName,
    required this.categoryId,
    required this.quantity,
    required this.unit,
    required this.reason,
    this.relatedRecipeId,
    this.isChecked = false,
  });
}