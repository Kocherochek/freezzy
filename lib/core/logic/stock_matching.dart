// lib/core/logic/stock_matching.dart
//
// Уровень 1: статус ОДНОГО ингредиента рецепта относительно текущих
// запасов. Работает одинаково для продуктов и заготовок — обеим
// подходит любой список ItemVariant (ProductVariant или PrepVariant),
// потому что обе ссылаются на базовую сущность через baseItemId.
//
// Использует FEFO (first expired, first out): партии со сроком
// годности, который наступает раньше, расходуются первыми. Партии
// без указанного срока годности считаются "портятся последними".
// Список allocations — не только статус, а готовый план, что списывать,
// если дело дойдёт до готовки (см. следующий шаг — списание).

import '../models/enums.dart';
import '../models/item_variant.dart';
import 'units.dart';

/// Одна партия, которая будет израсходована для покрытия требования.
class StockAllocation {
  final String variantId;
  final double quantityUsedInBaseUnit;
  final bool fromFreezer;

  StockAllocation({
    required this.variantId,
    required this.quantityUsedInBaseUnit,
    required this.fromFreezer,
  });
}

class IngredientMatchResult {
  final String baseItemId;
  final String displayName;
  final double requiredInBaseUnit;
  final double availableInBaseUnit; // сумма ВСЕХ партий этого продукта, не только использованных
  final double missingInBaseUnit; // max(0, required - available)
  final bool isSufficient;
  final bool needsDefrost; // хотя бы одна из РЕАЛЬНО использованных партий — из морозилки
  final bool usesExpiringStock; // хотя бы одна из РЕАЛЬНО использованных партий скоро испортится
  final List<StockAllocation> allocations; // что списывать, если готовим это блюдо
  final Unit unitType; // точная единица измерения этого требования

  IngredientMatchResult({
    required this.baseItemId,
    required this.displayName,
    required this.requiredInBaseUnit,
    required this.availableInBaseUnit,
    required this.missingInBaseUnit,
    required this.isSufficient,
    required this.needsDefrost,
    required this.usesExpiringStock,
    required this.allocations,
    required this.unitType,
  });
}

/// Сопоставляет одно требование (сколько нужно) с партиями склада.
///
/// [availableVariants] — обычно это НЕ весь склад, а уже отфильтрованный
/// список партий конкретно этого baseItemId (см. группировку склада
/// в следующем комментарии), но функция сама подстрахуется и отфильтрует,
/// если передать более широкий список.
IngredientMatchResult matchIngredient({
  required String baseItemId,
  required String displayName,
  required double requiredQuantity,
  required Unit requiredUnit,
  required List<ItemVariant> availableVariants,
}) {
  final relevant = availableVariants
      .where((v) => v.baseItemId == baseItemId)
      .toList()
    ..sort((a, b) {
      final aExpiry = a.expiryDate;
      final bExpiry = b.expiryDate;
      if (aExpiry == null && bExpiry == null) return 0;
      if (aExpiry == null) return 1; // без срока — в конец очереди
      if (bExpiry == null) return -1;
      return aExpiry.compareTo(bExpiry);
    });

  final requiredBase = toBaseUnit(requiredQuantity, requiredUnit);

  double remaining = requiredBase;
  double availableTotal = 0;
  final allocations = <StockAllocation>[];
  bool needsDefrost = false;
  bool usesExpiringStock = false;
  for (final variant in relevant) {
    assertSameDimension(requiredUnit, variant.unit);
    
    final variantBase = toBaseUnit(variant.quantity, variant.unit);
    availableTotal += variantBase;

    if (remaining <= 0) continue; // нужное количество уже набрано этой партией не потребуется

    final usedFromThisVariant = variantBase <= remaining ? variantBase : remaining;
    if (usedFromThisVariant <= 0) continue;

    final isFrozen = variant.zone == StockingZone.freezer;
    allocations.add(StockAllocation(
      variantId: variant.id,
      quantityUsedInBaseUnit: usedFromThisVariant,
      fromFreezer: isFrozen,
    ));
    if (isFrozen) needsDefrost = true;
    if (variant.isExpiringSoon()) usesExpiringStock = true;

    remaining -= usedFromThisVariant;
  }

  final missing = remaining > 0 ? remaining : 0.0;

  return IngredientMatchResult(
    baseItemId: baseItemId,
    displayName: displayName,
    requiredInBaseUnit: requiredBase,
    availableInBaseUnit: availableTotal,
    missingInBaseUnit: missing,
    isSufficient: missing <= 0,
    needsDefrost: needsDefrost,
    usesExpiringStock: usesExpiringStock,
    allocations: allocations,
    unitType: requiredUnit,
  );
}