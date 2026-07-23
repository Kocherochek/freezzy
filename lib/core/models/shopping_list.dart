// lib/core/models/shopping_list.dart
//
// ShoppingList — контейнер списка покупок. Активный список — один,
// а прошлые списки уходят в архив ТОЛЬКО по решению пользователя
// (если он не захотел сохранять список — он просто удаляется, а не
// архивируется, поэтому статус discarded отдельно не нужен).

enum ShoppingListStatus { active, archived }

class ShoppingList {
  final String id;
  final DateTime createdAt;
  final ShoppingListStatus status;

  ShoppingList({
    required this.id,
    required this.createdAt,
    this.status = ShoppingListStatus.active,
  });

  ShoppingList copyWith({ShoppingListStatus? status}) {
    return ShoppingList(
      id: id,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}