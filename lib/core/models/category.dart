// lib/core/models/category.dart
//
// Category используется как справочник и для продуктов, и для заготовок,
// но это будут ДВА РАЗНЫХ списка (например, productCategories и
// prepCategories) — просто одна и та же форма данных для обоих.
// Часть названий категорий может совпадать (например, "Мясные"),
// но это будут разные записи с разными id.

class Category {
  final String id;
  final String name;
  final bool isCustom; // true, если категорию добавил пользователь

  Category({
    required this.id,
    required this.name,
    this.isCustom = false,
  });
}