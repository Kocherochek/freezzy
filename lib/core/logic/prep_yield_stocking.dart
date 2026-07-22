// lib/core/logic/prep_yield_stocking.dart
//
// Что происходит после готовки РЕЦЕПТА ЗАГОТОВКИ (RecipeType.prep):
// помимо обычного списания продуктов (это делает consumeForRecipe),
// нужно создать новую партию заготовки на складе — но не весь выход
// целиком, а за вычетом того, что пользователь решил съесть сразу.

import '../models/base_item.dart';
import '../models/enums.dart';
import '../models/item_variant.dart';
import '../models/recipe.dart';

/// Подставляет срок годности по умолчанию, если пользователь не указал
/// свой — используется не только для заготовок, но и для случая
/// "отметить продукт как в наличии" через чекбокс в модалке рецепта.
DateTime? computeDefaultExpiryDate({
  required DateTime addedDate,
  required int? defaultShelfLifeDays,
}) {
  if (defaultShelfLifeDays == null) return null;
  return addedDate.add(Duration(days: defaultShelfLifeDays));
}

/// Создаёт новую партию заготовки на складе по результату готовки рецепта.
///
/// [eatNowQuantity] — сколько из общего выхода съедается сразу и НЕ идёt
/// на склад (может быть 0, если пользователь решил всё убрать на хранение).
/// [storageZone] — куда кладём то, что осталось (обычно fridge или freezer).
/// Если пользователь не указал срок годности вручную — используется
/// дефолтный срок из BasePrep.
///
/// Возвращает null, если весь выход съеден сразу и на склад ничего не идёт —
/// в этом случае просто не создаём запись, а не PrepVariant с quantity == 0.
PrepVariant? createPrepVariantFromYield({
  required Recipe recipe,
  required BasePrep basePrep,
  required double eatNowQuantity,
  required StockingZone storageZone,
  required String id,
  required DateTime addedDate,
  DateTime? manualExpiryDate,
}) {
  final prepYield = recipe.producesPrep;
  if (prepYield == null) {
    throw ArgumentError(
      'Рецепт "${recipe.title}" не производит заготовку (producesPrep == null)',
    );
  }

  final storedQuantity = prepYield.quantity - eatNowQuantity;
  if (storedQuantity <= 0) return null; // всё съедено сразу, на склад ничего не кладём

  final expiryDate = manualExpiryDate ??
      computeDefaultExpiryDate(
        addedDate: addedDate,
        defaultShelfLifeDays: basePrep.defaultShelfLifeDays,
      );

  return PrepVariant(
    id: id,
    baseItemId: prepYield.basePrepId,
    name: prepYield.basePrepName,
    zone: storageZone,
    quantity: storedQuantity,
    unit: prepYield.unit,
    addedDate: addedDate,
    expiryDate: expiryDate,
  );
}