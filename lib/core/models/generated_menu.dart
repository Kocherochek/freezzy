// lib/core/models/generated_menu.dart
//
// Результат нажатия "сгенерировать меню".
//
// ВАЖНО: fulfilledComponentSlotIds — это список, а не одно значение,
// потому что один рецепт с несколькими ролями (например, "Плов с курицей"
// = protein + sideDish) закрывает сразу несколько слотов одного приёма
// пищи — второй рецепт для них уже не нужен.
//
// Статусы "не хватает продуктов" / "нужно разморозить" сюда
// СОЗНАТЕЛЬНО не добавлены как поля — это вычисляемые значения,
// которые должна каждый раз считать логика сопоставления (matching),
// а не храниться и рисковать протухнуть.

class MenuDish {
  final String id;
  final String mealSlotId;
  final List<String> fulfilledComponentSlotIds;
  final String? recipeId; // null = блюдо удалено, слот пуст
  bool isPinned; // сохраняется при нажатии "сгенерировать заново"

  MenuDish({
    required this.id,
    required this.mealSlotId,
    required this.fulfilledComponentSlotIds,
    this.recipeId,
    this.isPinned = false,
  });
}

class GeneratedMenu {
  final String id;
  final String planTemplateId;
  final DateTime date;
  final List<MenuDish> dishes;

  GeneratedMenu({
    required this.id,
    required this.planTemplateId,
    required this.date,
    required this.dishes,
  });
}