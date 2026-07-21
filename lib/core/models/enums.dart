// lib/core/models/enums.dart
//
// Общие перечисления (enum), которые используются в разных моделях.

/// Роль в меню. Один и тот же enum используется и для BaseProduct/BasePrep
/// (какую роль играет продукт), и для Recipe (какую роль закрывает рецепт),
/// и для MealComponentSlot (какая роль нужна в этом слоте плана питания) —
/// это единый язык, на котором конструктор меню сравнивает "что нужно"
/// с "что есть".
enum MenuRole {
  protein, // белок: мясо, рыба, яйца, бобовые
  sideDish, // гарнир
  soup, // суп
  salad, // салат
  breakfastDish, // блюдо на завтрак
  snack, // перекус
  dessert,
  ingredient, // компонент блюда (подсолнечное масло)
  vegetable,
  fruit,
  dairy,
  spiceOrCondiment, // специи, соусы, приправы  
  deli, // гастрономия, мясные/сырные нарезки, деликатесы
}

/// Зона хранения.
enum StockingZone {
  fridge,
  freezer,
  pantry,  
}

/// Единица измерения количества.
enum Unit {
  grams,
  kilograms,
  milliliters,
  liters,
  pieces,
  packs,
}