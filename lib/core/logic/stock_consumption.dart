// lib/core/logic/stock_consumption.dart
//
// Уровень 4: списание при готовке. Использует allocations, которые
// matchIngredient() уже посчитал на уровне 1 (какая партия, сколько
// в базовых единицах, по правилу FEFO) — тут только применяем этот
// план к реальному списку партий на складе.
//
// Продукты и заготовки — РАЗНЫЕ склады (ProductVariant/PrepVariant),
// поэтому и списываются отдельно: allocations из productResults
// применяются к productStock, из prepResults — к prepStock.

import '../models/item_variant.dart';
import 'recipe_matching.dart';
import 'stock_matching.dart';
import 'units.dart';

/// ItemVariant абстрактный, а copyWith есть только у наследников —
/// поэтому решаем через проверку типа, а не через сам ItemVariant.
ItemVariant _withQuantity(ItemVariant variant, double quantity) {
  if (variant is ProductVariant) {
    return variant.copyWith(quantity: quantity);
  }
  if (variant is PrepVariant) {
    return variant.copyWith(quantity: quantity);
  }
  throw StateError('Неизвестный подтип ItemVariant: ${variant.runtimeType}');
}

/// Применяет список списаний к реальным партиям склада.
/// Партия с нулевым (или почти нулевым — с учётом погрешности float)
/// остатком убирается из списка целиком.
List<ItemVariant> applyAllocations({
  required List<ItemVariant> stock,
  required List<StockAllocation> allocations,
}) {
  if (allocations.isEmpty) return stock;

  final usedBaseByVariantId = <String, double>{};
  for (final allocation in allocations) {
    usedBaseByVariantId[allocation.variantId] =
        (usedBaseByVariantId[allocation.variantId] ?? 0) +
            allocation.quantityUsedInBaseUnit;
  }

  final result = <ItemVariant>[];
  for (final variant in stock) {
    final usedBase = usedBaseByVariantId[variant.id];
    if (usedBase == null) {
      result.add(variant); // эту партию не трогали
      continue;
    }

    final currentBase = toBaseUnit(variant.quantity, variant.unit);
    final remainingBase = currentBase - usedBase;

    if (remainingBase <= 0.0001) {
      continue; // партия израсходована полностью — не переносим в новый список
    }

    result.add(_withQuantity(variant, fromBaseUnit(remainingBase, variant.unit)));
  }
  return result;
}

class ConsumptionResult {
  final List<ItemVariant> updatedProductStock;
  final List<ItemVariant> updatedPrepStock;

  ConsumptionResult({
    required this.updatedProductStock,
    required this.updatedPrepStock,
  });
}

/// Списывает продукты и заготовки, использованные в рецепте, на основе
/// уже посчитанного RecipeMatchResult. Вызывать по кнопке "Блюдо готово" —
/// ВАЖНО: сейчас предполагает, что готовили на baseServings рецепта без
/// изменения порций. Если добавите изменение порций в моменте готовки,
/// нужно будет сначала пересчитать match с масштабированными количествами
/// (см. заметку про CookingSession) — эта функция сама не масштабирует.
ConsumptionResult consumeForRecipe({
  required RecipeMatchResult match,
  required List<ItemVariant> productStock,
  required List<ItemVariant> prepStock,
}) {
  final productAllocations =
      match.productResults.expand((r) => r.allocations).toList();
  final prepAllocations =
      match.prepResults.expand((r) => r.allocations).toList();

  return ConsumptionResult(
    updatedProductStock: applyAllocations(
      stock: productStock,
      allocations: productAllocations,
    ),
    updatedPrepStock: applyAllocations(
      stock: prepStock,
      allocations: prepAllocations,
    ),
  );
}