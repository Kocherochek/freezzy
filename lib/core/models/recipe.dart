// lib/core/models/recipe.dart
//
// Recipe — "шаблон" блюда. Ссылается на BaseProduct (уровень "Молоко"),
// а не на конкретный вид ("Молоко 3% безлактозное") — рецепту не важно,
// какой именно вид продукта использовать. baseProductName продублирован
// для удобного отображения без похода в справочник каждый раз.
// Роль в меню отдельно тут не нужна — она уже есть у самого BaseProduct.

import 'enums.dart';

class RecipeIngredient {
  final String baseProductId; // ссылка на BaseProduct.id
  final String baseProductName; // "Молоко" — для отображения
  final double quantity;
  final Unit unit;

  RecipeIngredient({
    required this.baseProductId,
    required this.baseProductName,
    required this.quantity,
    required this.unit,
  });
}

class Recipe {
  final String id;
  final String title;
  final List<RecipeIngredient> ingredients;
  final String instructions;
  final int cookingTimeMinutes;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.cookingTimeMinutes,
    this.imageUrl,
  });
}