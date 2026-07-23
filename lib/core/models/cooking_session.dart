// lib/core/models/cooking_session.dart
//
// Состояние процесса готовки. Создаётся при нажатии "Начать готовить"
// и хранится до нажатия "Блюдо готово" или отмены.

import 'enums.dart';
import 'base_item.dart';
import 'item_variant.dart';
import 'recipe.dart';
import 'generated_menu.dart';
import '../logic/recipe_matching.dart';
import '../logic/prep_menu_generation.dart';
import '../logic/recipe_filtering.dart';

/// Один шаг в процессе готовки с дополнительной инфой для UI.
class CookingStep {
  final RecipeStep originalStep;
  final int stepIndex; // 0-based в рецепте
  final bool isCompleted;
  final bool isPrepStepAutoCompleted; // использует заготовку — сразу выполнен
  final String? prepUsedName; // название заготовки, если применимо
  final int? timeSavedSeconds; // сэкономлено времени на готовке заготовки

  CookingStep({
    required this.originalStep,
    required this.stepIndex,
    this.isCompleted = false,
    this.isPrepStepAutoCompleted = false,
    this.prepUsedName,
    this.timeSavedSeconds,
  });

  CookingStep copyWith({
    bool? isCompleted,
    bool? isPrepStepAutoCompleted,
    String? prepUsedName,
    int? timeSavedSeconds,
  }) {
    return CookingStep(
      originalStep: originalStep,
      stepIndex: stepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isPrepStepAutoCompleted: isPrepStepAutoCompleted ?? this.isPrepStepAutoCompleted,
      prepUsedName: prepUsedName ?? this.prepUsedName,
      timeSavedSeconds: timeSavedSeconds ?? this.timeSavedSeconds,
    );
  }
}

/// Рецепт в процессе готовки с отмасштабированными ингредиентами.
class CookingRecipe {
  final Recipe originalRecipe;
  final int targetServings;
  final List<ScaledIngredient> scaledIngredients;
  final List<ScaledPrepRequirement> scaledPreps;
  final List<CookingStep> steps;
  final int totalCookingTimeMinutes; // сумма durationSeconds всех шагов
  final int effectiveCookingTimeMinutes; // минус время на заготовки, которые есть в наличии
  final bool hasAvailablePreps; // есть хоть одна заготовка в наличии
  final String? quickCookTag; // тег для UI: "Можно быстро приготовить, есть заготовка"

  CookingRecipe({
    required this.originalRecipe,
    required this.targetServings,
    required this.scaledIngredients,
    required this.scaledPreps,
    required this.steps,
    required this.totalCookingTimeMinutes,
    required this.effectiveCookingTimeMinutes,
    required this.hasAvailablePreps,
    this.quickCookTag,
  });

  /// Текущий активный шаг (первый невыполненный).
  CookingStep? get currentStep {
    try {
      return steps.firstWhere((s) => !s.isCompleted);
    } catch (_) {
      return null;
    }
  }

  /// Все ли шаги выполнены.
  bool get isFullyCompleted => steps.every((s) => s.isCompleted);

  /// Прогресс готовки 0.0 - 1.0.
  double get progress => steps.where((s) => s.isCompleted).length / steps.length;
}

/// Вся сессия готовки (один экран "Начать готовить").
class CookingSession {
  final String id;
  final DateTime startedAt;
  final List<CookingRecipe> recipes; // в порядке приёмов пищи / сессии заготовок
  final Map<String, int> recipeServings; // recipeId -> targetServings
  final List<ItemVariant> productStockSnapshot; // склад на момент начала
  final List<ItemVariant> prepStockSnapshot;
  final Map<String, RecipeMatchResult> matchResultsSnapshot; // recipeId -> match

  CookingSession({
    required this.id,
    required this.startedAt,
    required this.recipes,
    required this.recipeServings,
    required this.productStockSnapshot,
    required this.prepStockSnapshot,
    required this.matchResultsSnapshot,
  });

  /// Рецепт, который сейчас готовится (первый с невыполненными шагами).
  CookingRecipe? get currentRecipe {
    try {
      return recipes.firstWhere((r) => !r.isFullyCompleted);
    } catch (_) {
      return null;
    }
  }

  /// Все ли рецепты готовы.
  bool get isComplete => recipes.every((r) => r.isFullyCompleted);

  /// Прогресс всей сессии.
  double get overallProgress {
    if (recipes.isEmpty) return 1.0;
    return recipes.map((r) => r.progress).reduce((a, b) => a + b) / recipes.length;
  }
}

/// Параметры для создания сессии готовки.
class CookingSessionParams {
  final GeneratedMenu? menu; // для обычного меню
  final GeneratedPrepMenu? prepMenu; // для сессии заготовок
  final List<Recipe> allRecipes;
  final Map<String, BaseProduct> productsById;
  final Map<String, BasePrep> prepsById;
  final List<ItemVariant> productStock;
  final List<ItemVariant> prepStock;
  final Map<String, int> customServings; // recipeId -> servings (если пользователь изменил)

  CookingSessionParams({
    this.menu,
    this.prepMenu,
    required this.allRecipes,
    required this.productsById,
    required this.prepsById,
    required this.productStock,
    required this.prepStock,
    this.customServings = const {},
  });
}

/// Результат завершения готовки рецепта.
class RecipeCompletionResult {
  final List<ItemVariant> updatedProductStock;
  final List<ItemVariant> updatedPrepStock;
  final PrepVariant? createdPrepVariant; // для рецептов заготовок
  final bool isPrepRecipe;
  final List<DepletedProduct> depletedProducts; // продукты, которые закончились

  RecipeCompletionResult({
    required this.updatedProductStock,
    required this.updatedPrepStock,
    this.createdPrepVariant,
    required this.isPrepRecipe,
    this.depletedProducts = const [],
  });
}

/// Продукт, который закончился на складе после приготовления рецепта.
class DepletedProduct {
  final String baseProductId;
  final String baseProductName;
  final double consumedQuantity; // в единице измерения продукта (по defaultUnit)
  final Unit unit; // defaultUnit продукта

  DepletedProduct({
    required this.baseProductId,
    required this.baseProductName,
    required this.consumedQuantity,
    required this.unit,
  });
}