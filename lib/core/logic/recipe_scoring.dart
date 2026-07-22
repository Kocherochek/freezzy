// lib/core/logic/recipe_scoring.dart
//
// Уровень 3, часть 1: оценка ОДНОГО рецепта по критериям из твоего
// описания — истекающий срок, наличие заготовки, доля наличия
// ингредиентов, любимые рецепты. Веса вынесены в константы —
// это единственное место, которое нужно трогать, если баланс
// критериев покажется неправильным на практике.

import '../models/recipe.dart';
import 'recipe_matching.dart';

class ScoringWeights {
  static const double availability = 40; // доля ингредиентов, которых хватает
  static const double expiringProduct = 30; // использует продукт с истекающим сроком
  static const double usesPrep = 20; // в составе есть заготовка
  static const double favorite = 10; // рецепт в любимых
}

class RecipeScore {
  final Recipe recipe;
  final RecipeMatchResult match;
  final double availabilityRatio; // 0..1
  final double totalScore;

  RecipeScore({
    required this.recipe,
    required this.match,
    required this.availabilityRatio,
    required this.totalScore,
  });
}

double _availabilityRatio(RecipeMatchResult match) {
  final all = [...match.productResults, ...match.prepResults];
  if (all.isEmpty) return 1; // рецепт без ингредиентов — вырожденный случай, считаем "готов"
  final sufficientCount = all.where((r) => r.isSufficient).length;
  return sufficientCount / all.length;
}

/// Считает score рецепта относительно текущих запасов.
/// Не смотрит на роли/слоты — это чисто "насколько хорош рецепт
/// сам по себе прямо сейчас", выбор слотов — отдельным шагом.
RecipeScore scoreRecipe({
  required Recipe recipe,
  required RecipeMatchResult match,
}) {
  final ratio = _availabilityRatio(match);

  double score = ratio * ScoringWeights.availability;
  if (match.usesExpiringStock) score += ScoringWeights.expiringProduct;
  if (recipe.requiredPreps.isNotEmpty) score += ScoringWeights.usesPrep;
  if (recipe.isFavorite) score += ScoringWeights.favorite;

  return RecipeScore(
    recipe: recipe,
    match: match,
    availabilityRatio: ratio,
    totalScore: score,
  );
}