// lib/core/models/recipe.dart
//
// Recipe теперь бывает двух типов (RecipeType):
// - meal: обычное блюдо, попадает в дневное меню, закрывает menuRoles
// - prep: рецепт заготовки, производит PrepYield (конкретный BasePrep
//   в конкретном количестве), НЕ попадает в обычную генерацию меню,
//   зато участвует в отдельной генерации "сессии заготовок".

import 'enums.dart';

class RecipeIngredient {
  final String id;
  final String baseProductId;
  final String baseProductName;
  final double quantity;
  final Unit unit;

  RecipeIngredient({
    required this.id,
    required this.baseProductId,
    required this.baseProductName,
    required this.quantity,
    required this.unit,
  });
}

class RecipePrepRequirement {
  final String id;
  final String basePrepId;
  final String basePrepName;
  final double quantity;
  final Unit unit;

  RecipePrepRequirement({
    required this.id,
    required this.basePrepId,
    required this.basePrepName,
    required this.quantity,
    required this.unit,
  });
}

class RecipeStepIngredient {
  final String ingredientRefId;
  final double quantity;
  final Unit unit;

  RecipeStepIngredient({
    required this.ingredientRefId,
    required this.quantity,
    required this.unit,
  });
}

class RecipeStep {
  final String id;
  final int order;
  final String description;
  final int? durationSeconds;
  final List<RecipeStepIngredient> stepIngredients;

  RecipeStep({
    required this.id,
    required this.order,
    required this.description,
    this.durationSeconds,
    this.stepIngredients = const [],
  });
}

/// Что производит рецепт заготовки: какой BasePrep и сколько.
/// Заполнено только у рецептов с type == RecipeType.prep.
class PrepYield {
  final String basePrepId;
  final String basePrepName;
  final double quantity;
  final Unit unit;

  PrepYield({
    required this.basePrepId,
    required this.basePrepName,
    required this.quantity,
    required this.unit,
  });
}

class Recipe {
  final String id;
  final String title;
  final RecipeType type;
  final List<MenuRole> menuRoles; // пусто/не используется для type == prep
  final List<RecipeIngredient> ingredients;
  final List<RecipePrepRequirement> requiredPreps;
  final List<RecipeStep> steps;
  final int baseServings;
  final int? approxYieldGrams;
  final PrepYield? producesPrep; // заполнено только для type == prep
  final int cookingTimeMinutes;
  final bool isFavorite;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.requiredPreps,
    required this.steps,
    required this.baseServings,
    required this.cookingTimeMinutes,
    this.type = RecipeType.meal,
    this.menuRoles = const [],
    this.approxYieldGrams,
    this.producesPrep,
    this.isFavorite = false,
    this.imageUrl,
  });
}