// lib/core/models/item_variant.dart
//
// ItemVariant — конкретный вид продукта/заготовки, который реально
// лежит на кухне (например, "Молоко 3% безлактозное").
// Хранит только id базовой сущности (baseItemId), а не сам объект
// BaseProduct/BasePrep целиком — так одни и те же данные не дублируются
// в каждом экземпляре на полке (это называется "нормализация данных").

import 'enums.dart';

abstract class ItemVariant {
  final String id;
  final String baseItemId; // ссылка на BaseProduct.id или BasePrep.id
  final String name; // "Молоко 3% безлактозное"
  final StockingZone zone; // фактическая зона хранения (может отличаться от дефолтной)
  final double quantity;
  final Unit unit;
  final DateTime? expiryDate;
  final DateTime addedDate;
  final bool isCustom; // true, если юзер добавил свой вариант, не выбирая из списка

  ItemVariant({
    required this.id,
    required this.baseItemId,
    required this.name,
    required this.zone,
    required this.quantity,
    required this.unit,
    required this.addedDate,
    this.expiryDate,
    this.isCustom = false,
  });

  bool isExpiringSoon({int daysThreshold = 2}) {
    if (expiryDate == null) return false;
    return expiryDate!.difference(DateTime.now()).inDays <= daysThreshold;
  }
}

class ProductVariant extends ItemVariant {
  ProductVariant({
    required super.id,
    required super.baseItemId,
    required super.name,
    required super.zone,
    required super.quantity,
    required super.unit,
    required super.addedDate,
    super.expiryDate,
    super.isCustom = false,
  });

  ProductVariant copyWith({
    double? quantity,
    StockingZone? zone,
    DateTime? expiryDate,
  }) {
    return ProductVariant(
      id: id,
      baseItemId: baseItemId,
      name: name,
      zone: zone ?? this.zone,
      quantity: quantity ?? this.quantity,
      unit: unit,
      addedDate: addedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isCustom: isCustom,
    );
  }
}

class PrepVariant extends ItemVariant {
  PrepVariant({
    required super.id,
    required super.baseItemId,
    required super.name,
    required super.zone,
    required super.quantity,
    required super.unit,
    required super.addedDate,
    super.expiryDate,
    super.isCustom = false,
  });

  PrepVariant copyWith({
    double? quantity,
    StockingZone? zone,
    DateTime? expiryDate,
  }) {
    return PrepVariant(
      id: id,
      baseItemId: baseItemId,
      name: name,
      zone: zone ?? this.zone,
      quantity: quantity ?? this.quantity,
      unit: unit,
      addedDate: addedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isCustom: isCustom,
    );
  }
}