// lib/playground.dart
//
// Тестовый прогон всей логики на примерных данных, без БД и без UI.
// Запуск из корня проекта: dart run lib/playground.dart
//
// Тут ничего не нужно копировать в реальный проект "как есть" — это
// одноразовый скрипт для проверки, что логика работает на живых данных.
// Можно менять цифры и смотреть, как меняется результат.

import 'core/models/enums.dart';
import 'core/models/base_item.dart';
import 'core/models/item_variant.dart';
import 'core/models/recipe.dart';
import 'core/models/meal_plan.dart';
import 'core/models/shopping_list.dart';
import 'core/models/category.dart';
import 'core/models/cooking_session.dart';
import 'core/logic/recipe_matching.dart';
import 'core/logic/recipe_filtering.dart';
import 'core/logic/day_menu_generation.dart';
import 'core/logic/day_menu_alerts.dart';
import 'core/logic/stock_consumption.dart';
import 'core/logic/prep_yield_stocking.dart';
import 'core/logic/cooking_session.dart';
import 'core/logic/shopping_list_logic.dart';

int _idCounter = 0;
String generateId() => 'id_${_idCounter++}';

void main() {
  final now = DateTime.now();

  // ===================== СПРАВОЧНИК: БАЗОВЫЕ ПРОДУКТЫ =====================

  final milk = BaseProduct(
    id: 'bp_milk',
    name: 'Молоко',
    categoryId: 'cat_dairy',
    menuRoles: [MenuRole.breakfastDish, MenuRole.dairy],
    defaultZone: StockingZone.fridge,
    defaultUnit: Unit.milliliters,
    defaultShelfLifeDays: 7,
  );
  final eggs = BaseProduct(
    id: 'bp_eggs',
    name: 'Яйца',
    categoryId: 'cat_dairy',
    menuRoles: [MenuRole.breakfastDish, MenuRole.protein],
    defaultZone: StockingZone.fridge,
    defaultUnit: Unit.pieces,
    defaultShelfLifeDays: 21,
  );
  final chicken = BaseProduct(
    id: 'bp_chicken',
    name: 'Куриная грудка',
    categoryId: 'cat_meat',
    menuRoles: [MenuRole.protein],
    defaultZone: StockingZone.fridge,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 3,
  );
  final carrot = BaseProduct(
    id: 'bp_carrot',
    name: 'Морковь',
    categoryId: 'cat_veg',
    menuRoles: [MenuRole.vegetable, MenuRole.soup],
    defaultZone: StockingZone.fridge,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 14,
  );
  final onion = BaseProduct(
    id: 'bp_onion',
    name: 'Лук',
    categoryId: 'cat_veg',
    menuRoles: [MenuRole.vegetable, MenuRole.soup],
    defaultZone: StockingZone.pantry,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 30,
  );
  final rice = BaseProduct(
    id: 'bp_rice',
    name: 'Рис',
    categoryId: 'cat_grain',
    menuRoles: [MenuRole.sideDish],
    defaultZone: StockingZone.pantry,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 365,
  );
  final buckwheat = BaseProduct(
    id: 'bp_buckwheat',
    name: 'Гречка',
    categoryId: 'cat_grain',
    menuRoles: [MenuRole.sideDish],
    defaultZone: StockingZone.pantry,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 365,
  );
  final cucumber = BaseProduct(
    id: 'bp_cucumber',
    name: 'Огурец',
    categoryId: 'cat_veg',
    menuRoles: [MenuRole.salad, MenuRole.vegetable],
    defaultZone: StockingZone.fridge,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 7,
  );
  final tomato = BaseProduct(
    id: 'bp_tomato',
    name: 'Помидор',
    categoryId: 'cat_veg',
    menuRoles: [MenuRole.salad, MenuRole.vegetable],
    defaultZone: StockingZone.fridge,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 5,
  );
  final feta = BaseProduct(
    id: 'bp_feta',
    name: 'Сыр фета',
    categoryId: 'cat_dairy',
    menuRoles: [MenuRole.salad, MenuRole.dairy],
    defaultZone: StockingZone.fridge,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 14,
  );
  final oliveOil = BaseProduct(
    id: 'bp_olive_oil',
    name: 'Оливковое масло',
    categoryId: 'cat_condiment',
    menuRoles: [MenuRole.ingredient, MenuRole.spiceOrCondiment],
    defaultZone: StockingZone.pantry,
    defaultUnit: Unit.milliliters,
    alwaysInStock: true,
  );
  final flour = BaseProduct(
    id: 'bp_flour',
    name: 'Мука',
    categoryId: 'cat_grain',
    menuRoles: [MenuRole.ingredient],
    defaultZone: StockingZone.pantry,
    defaultUnit: Unit.grams,
    alwaysInStock: true,
  );
  final mince = BaseProduct(
    id: 'bp_mince',
    name: 'Фарш свиной',
    categoryId: 'cat_meat',
    menuRoles: [MenuRole.protein],
    defaultZone: StockingZone.freezer,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 2,
  );

  final productsById = <String, BaseProduct>{
    milk.id: milk,
    eggs.id: eggs,
    chicken.id: chicken,
    carrot.id: carrot,
    onion.id: onion,
    rice.id: rice,
    buckwheat.id: buckwheat,
    cucumber.id: cucumber,
    tomato.id: tomato,
    feta.id: feta,
    oliveOil.id: oliveOil,
    flour.id: flour,
    mince.id: mince,
  };

  final categories = [
    Category(id: 'cat_dairy', name: 'Молочные продукты'),
    Category(id: 'cat_meat', name: 'Мясо и птица'),
    Category(id: 'cat_veg', name: 'Овощи'),
    Category(id: 'cat_grain', name: 'Крупы'),
    Category(id: 'cat_condiment', name: 'Соусы и приправы'),
    Category(id: 'cat_prep', name: 'Заготовки'),
  ];

  // ===================== СПРАВОЧНИК: БАЗОВЫЕ ЗАГОТОВКИ =====================

  final dumplings = BasePrep(
    id: 'bprep_dumplings',
    name: 'Пельмени',
    categoryId: 'cat_prep',
    menuRoles: [MenuRole.protein],
    defaultZone: StockingZone.freezer,
    defaultUnit: Unit.grams,
    defaultShelfLifeDays: 60,
  );

  // ===================== СКЛАД: ПРОДУКТЫ =====================

  var productStock = <ItemVariant>[
    ProductVariant(
      id: 'pv_milk_1',
      baseItemId: milk.id,
      name: 'Молоко 3.2%',
      zone: StockingZone.fridge,
      quantity: 500,
      unit: Unit.milliliters,
      addedDate: now.subtract(const Duration(days: 3)),
      expiryDate: now.add(const Duration(days: 1)), // скоро испортится
    ),
    ProductVariant(
      id: 'pv_eggs_1',
      baseItemId: eggs.id,
      name: 'Яйца С1',
      zone: StockingZone.fridge,
      quantity: 10,
      unit: Unit.pieces,
      addedDate: now.subtract(const Duration(days: 5)),
      expiryDate: now.add(const Duration(days: 20)),
    ),
    // Курица специально в двух партиях — свежая почти испортилась,
    // мороженая лежит давно без указанного срока.
    ProductVariant(
      id: 'pv_chicken_fridge',
      baseItemId: chicken.id,
      name: 'Грудка охлаждённая',
      zone: StockingZone.fridge,
      quantity: 150,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 1)),
    ),
    ProductVariant(
      id: 'pv_chicken_freezer',
      baseItemId: chicken.id,
      name: 'Грудка замороженная',
      zone: StockingZone.freezer,
      quantity: 200,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 10)),
    ),
    ProductVariant(
      id: 'pv_carrot_1',
      baseItemId: carrot.id,
      name: 'Морковь',
      zone: StockingZone.fridge,
      quantity: 150,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 10)),
    ),
    ProductVariant(
      id: 'pv_onion_1',
      baseItemId: onion.id,
      name: 'Лук',
      zone: StockingZone.pantry,
      quantity: 200,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 5)),
      expiryDate: now.add(const Duration(days: 20)),
    ),
    ProductVariant(
      id: 'pv_rice_1',
      baseItemId: rice.id,
      name: 'Рис',
      zone: StockingZone.pantry,
      quantity: 500,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 30)),
    ),
    ProductVariant(
      id: 'pv_buckwheat_1',
      baseItemId: buckwheat.id,
      name: 'Гречка',
      zone: StockingZone.pantry,
      quantity: 400,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 20)),
    ),
    ProductVariant(
      id: 'pv_cucumber_1',
      baseItemId: cucumber.id,
      name: 'Огурец',
      zone: StockingZone.fridge,
      quantity: 150,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 4)),
    ),
    ProductVariant(
      id: 'pv_tomato_1',
      baseItemId: tomato.id,
      name: 'Помидор',
      zone: StockingZone.fridge,
      quantity: 100, // меньше, чем нужно рецепту — недостача
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 3)),
    ),
    // Фета в стоке ОТСУТСТВУЕТ вообще — намеренно, для проверки полной нехватки.
    ProductVariant(
      id: 'pv_olive_oil_1',
      baseItemId: oliveOil.id,
      name: 'Оливковое масло',
      zone: StockingZone.pantry,
      quantity: 300,
      unit: Unit.milliliters,
      addedDate: now.subtract(const Duration(days: 60)),
    ),
    ProductVariant(
      id: 'pv_flour_1',
      baseItemId: flour.id,
      name: 'Мука',
      zone: StockingZone.pantry,
      quantity: 1000,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 15)),
    ),
    ProductVariant(
      id: 'pv_mince_1',
      baseItemId: mince.id,
      name: 'Фарш свиной',
      zone: StockingZone.freezer,
      quantity: 500,
      unit: Unit.grams,
      addedDate: now.subtract(const Duration(days: 10)),
    ),
  ];

  // Заготовок на складе пока НЕТ — проверим, как это влияет на "Суп с пельменями".
  var prepStock = <ItemVariant>[];

  // ===================== КНИГА РЕЦЕПТОВ =====================

  final rOmelet = Recipe(
    id: 'r_omelet',
    title: 'Омлет',
    menuRoles: [MenuRole.breakfastDish],
    ingredients: [
      RecipeIngredient(id: 'ri_1', baseProductId: eggs.id, baseProductName: eggs.name, quantity: 2, unit: Unit.pieces),
      RecipeIngredient(id: 'ri_2', baseProductId: milk.id, baseProductName: milk.name, quantity: 100, unit: Unit.milliliters),
    ],
    requiredPreps: [],
    steps: [
      RecipeStep(id: 'step_1', order: 1, description: 'Взбить яйца с молоком', durationSeconds: 120),
      RecipeStep(id: 'step_2', order: 2, description: 'Готовить на сковороде 3 минуты', durationSeconds: 180),
    ],
    baseServings: 1,
    cookingTimeMinutes: 10,
  );

  final rSoup = Recipe(
    id: 'r_soup',
    title: 'Суп с пельменями',
    menuRoles: [MenuRole.soup],
    ingredients: [
      RecipeIngredient(id: 'ri_3', baseProductId: carrot.id, baseProductName: carrot.name, quantity: 50, unit: Unit.grams),
      RecipeIngredient(id: 'ri_4', baseProductId: onion.id, baseProductName: onion.name, quantity: 30, unit: Unit.grams),
    ],
    requiredPreps: [
      RecipePrepRequirement(id: 'rp_1', basePrepId: dumplings.id, basePrepName: dumplings.name, quantity: 300, unit: Unit.grams),
    ],
    steps: [
      RecipeStep(id: 'step_3', order: 1, description: 'Сварить бульон с овощами', durationSeconds: 900),
      RecipeStep(id: 'step_4', order: 2, description: 'Добавить пельмени, варить 10 минут', durationSeconds: 600),
    ],
    baseServings: 3,
    cookingTimeMinutes: 30,
  );

  final rPlov = Recipe(
    id: 'r_plov',
    title: 'Плов с курицей',
    menuRoles: [MenuRole.protein, MenuRole.sideDish], // закрывает 2 роли одним рецептом
    ingredients: [
      RecipeIngredient(id: 'ri_5', baseProductId: chicken.id, baseProductName: chicken.name, quantity: 200, unit: Unit.grams),
      RecipeIngredient(id: 'ri_6', baseProductId: rice.id, baseProductName: rice.name, quantity: 200, unit: Unit.grams),
      RecipeIngredient(id: 'ri_7', baseProductId: carrot.id, baseProductName: carrot.name, quantity: 50, unit: Unit.grams),
      RecipeIngredient(id: 'ri_8', baseProductId: onion.id, baseProductName: onion.name, quantity: 30, unit: Unit.grams),
    ],
    requiredPreps: [],
    steps: [
      RecipeStep(id: 'step_5', order: 1, description: 'Обжарить курицу с овощами', durationSeconds: 600),
      RecipeStep(id: 'step_6', order: 2, description: 'Добавить рис и воду, тушить 25 минут', durationSeconds: 1500),
    ],
    baseServings: 4,
    cookingTimeMinutes: 40,
  );

  final rBuckwheat = Recipe(
    id: 'r_buckwheat',
    title: 'Гречка на гарнир',
    menuRoles: [MenuRole.sideDish],
    ingredients: [
      RecipeIngredient(id: 'ri_9', baseProductId: buckwheat.id, baseProductName: buckwheat.name, quantity: 150, unit: Unit.grams),
    ],
    requiredPreps: [],
    steps: [
      RecipeStep(id: 'step_7', order: 1, description: 'Отварить гречку 15 минут', durationSeconds: 900),
    ],
    baseServings: 2,
    cookingTimeMinutes: 15,
  );

  final rSalad = Recipe(
    id: 'r_salad',
    title: 'Греческий салат',
    menuRoles: [MenuRole.salad],
    ingredients: [
      RecipeIngredient(id: 'ri_10', baseProductId: cucumber.id, baseProductName: cucumber.name, quantity: 100, unit: Unit.grams),
      RecipeIngredient(id: 'ri_11', baseProductId: tomato.id, baseProductName: tomato.name, quantity: 250, unit: Unit.grams),
      RecipeIngredient(id: 'ri_12', baseProductId: feta.id, baseProductName: feta.name, quantity: 150, unit: Unit.grams),
      RecipeIngredient(id: 'ri_13', baseProductId: oliveOil.id, baseProductName: oliveOil.name, quantity: 20, unit: Unit.milliliters),
    ],
    requiredPreps: [],
    steps: [
      RecipeStep(id: 'step_8', order: 1, description: 'Нарезать овощи, смешать с сыром и маслом', durationSeconds: 300),
    ],
    baseServings: 2,
    cookingTimeMinutes: 10,
  );

  final rDumplingsPrep = Recipe(
    id: 'r_dumplings_prep',
    title: 'Пельмени домашние',
    type: RecipeType.prep,
    ingredients: [
      RecipeIngredient(id: 'ri_14', baseProductId: flour.id, baseProductName: flour.name, quantity: 500, unit: Unit.grams),
      RecipeIngredient(id: 'ri_15', baseProductId: mince.id, baseProductName: mince.name, quantity: 500, unit: Unit.grams),
      RecipeIngredient(id: 'ri_16', baseProductId: onion.id, baseProductName: onion.name, quantity: 100, unit: Unit.grams),
      RecipeIngredient(id: 'ri_17', baseProductId: eggs.id, baseProductName: eggs.name, quantity: 1, unit: Unit.pieces),
    ],
    requiredPreps: [],
    steps: [
      RecipeStep(id: 'step_9', order: 1, description: 'Замесить тесто, приготовить фарш', durationSeconds: 1800),
      RecipeStep(id: 'step_10', order: 2, description: 'Слепить пельмени', durationSeconds: 2400),
    ],
    baseServings: 6,
    cookingTimeMinutes: 90,
    producesPrep: PrepYield(basePrepId: dumplings.id, basePrepName: dumplings.name, quantity: 1200, unit: Unit.grams),
  );

  final allRecipes = [rOmelet, rSoup, rPlov, rBuckwheat, rSalad, rDumplingsPrep];
  final recipesById = {for (final r in allRecipes) r.id: r};

  // ===================== ФОРМУЛА ПЛАНА ПИТАНИЯ =====================

  final plan = MealPlanTemplate(
    id: 'plan_classic',
    name: 'Завтрак + Обед + Ужин',
    mealSlots: [
      MealSlot(
        id: 'meal_breakfast',
        name: 'Завтрак',
        components: [MealComponentSlot(id: 'slot_breakfast', role: MenuRole.breakfastDish)],
      ),
      MealSlot(
        id: 'meal_lunch',
        name: 'Обед',
        components: [
          MealComponentSlot(id: 'slot_soup', role: MenuRole.soup),
          MealComponentSlot(id: 'slot_lunch_protein', role: MenuRole.protein),
          MealComponentSlot(id: 'slot_lunch_side', role: MenuRole.sideDish),
        ],
      ),
      MealSlot(
        id: 'meal_dinner',
        name: 'Ужин',
        components: [
          MealComponentSlot(id: 'slot_dinner_protein', role: MenuRole.protein),
          MealComponentSlot(id: 'slot_salad', role: MenuRole.salad),
        ],
      ),
    ],
  );

  // ===================== ШАГ 1: ГЕНЕРАЦИЯ МЕНЮ НА ДЕНЬ =====================

  print('\n=== Генерация меню на день ===');
  final menu = generateMenuForDay(
    plan: plan,
    date: now,
    allRecipes: allRecipes,
    productStock: productStock,
    prepStock: prepStock,
    generateId: generateId,
  );

  for (final mealSlot in plan.mealSlots) {
    print('\n${mealSlot.name}:');
    final dishesHere = menu.dishes.where((d) => d.mealSlotId == mealSlot.id);
    for (final dish in dishesHere) {
      final title = dish.recipeId == null ? '(пусто)' : recipesById[dish.recipeId]!.title;
      print('  - $title  [слоты: ${dish.fulfilledComponentSlotIds.join(", ")}]');
    }
  }

  // ===================== ШАГ 2: АГРЕГИРОВАННЫЙ БАННЕР НА ДЕНЬ =====================

  print('\n=== Баннер "перед первым рецептом" (агрегация на весь день) ===');
  final dayAlerts = computeDayAlerts(
    menu: menu,
    recipesById: recipesById,
    productStock: productStock,
    prepStock: prepStock,
  );

  print('Не хватает:');
  for (final need in dayAlerts.missingIngredients) {
    print('  - ${need.displayName}: не хватает ${need.quantityInBaseUnit} (нужно для рецептов: ${need.recipeIds.map((id) => recipesById[id]!.title).join(", ")})');
  }
  print('Нужно разморозить:');
  for (final need in dayAlerts.needsDefrostIngredients) {
    print('  - ${need.displayName} (для рецептов: ${need.recipeIds.map((id) => recipesById[id]!.title).join(", ")})');
  }

  // ===================== ШАГ 3: 3 ПЛАШКИ ДЛЯ КОНКРЕТНОГО РЕЦЕПТА =====================

  print('\n=== 3 плашки рецепта "Греческий салат" ===');
  final saladMatch = matchRecipe(recipe: rSalad, productStock: productStock, prepStock: prepStock);
  print('В наличии: ${saladMatch.availableIngredients.map((r) => r.displayName).join(", ")}');
  print('Не хватает: ${saladMatch.missingIngredients.map((r) => '${r.displayName} (не хватает ${r.missingInBaseUnit})').join(", ")}');
  print('Разморозить: ${saladMatch.needsDefrostIngredients.map((r) => r.displayName).join(", ")}');

  print('\n=== 3 плашки рецепта "Плов с курицей" (проверка FEFO: истекает + заморожено одновременно) ===');
  final plovMatch = matchRecipe(recipe: rPlov, productStock: productStock, prepStock: prepStock);
  print('В наличии: ${plovMatch.availableIngredients.map((r) => r.displayName).join(", ")}');
  print('Не хватает: ${plovMatch.missingIngredients.map((r) => r.displayName).join(", ")}');
  print('Разморозить: ${plovMatch.needsDefrostIngredients.map((r) => r.displayName).join(", ")}');
  print('Использует истекающий срок: ${plovMatch.usesExpiringStock}');

  // ===================== ШАГ 4: ГОТОВИМ ПЛОВ — СПИСАНИЕ =====================

  print('\n=== Готовим "Плов с курицей" — списание продуктов ===');
  final plovConsumption = consumeForRecipe(
    match: plovMatch,
    productStock: productStock,
    prepStock: prepStock,
  );
  productStock = plovConsumption.updatedProductStock;
  prepStock = plovConsumption.updatedPrepStock;

  print('Остатки курицы после готовки:');
  for (final v in productStock.where((v) => v.baseItemId == chicken.id)) {
    print('  - ${v.id}: ${v.quantity} ${v.unit} (зона: ${v.zone})');
  }
  print('Остаток риса: ${productStock.where((v) => v.baseItemId == rice.id).map((v) => v.quantity).toList()}');
  print('Остаток моркови: ${productStock.where((v) => v.baseItemId == carrot.id).map((v) => v.quantity).toList()}');

  // ===================== ШАГ 5: ГОТОВИМ ЗАГОТОВКУ (ПЕЛЬМЕНИ) =====================

  print('\n=== Готовим рецепт заготовки "Пельмени домашние" ===');
  final dumplingsMatch = matchRecipe(recipe: rDumplingsPrep, productStock: productStock, prepStock: prepStock);
  print('Готово к готовке (все продукты в наличии): ${dumplingsMatch.isReadyToCook}');
  print('Нужно разморозить: ${dumplingsMatch.needsDefrostIngredients.map((r) => r.displayName).join(", ")}');

  final dumplingsConsumption = consumeForRecipe(
    match: dumplingsMatch,
    productStock: productStock,
    prepStock: prepStock,
  );
  productStock = dumplingsConsumption.updatedProductStock;
  prepStock = dumplingsConsumption.updatedPrepStock;

  // Пользователь решил: 200г съесть сразу, остальное — в морозилку.
  final newDumplingsBatch = createPrepVariantFromYield(
    recipe: rDumplingsPrep,
    basePrep: dumplings,
    eatNowQuantity: 200,
    storageZone: StockingZone.freezer,
    id: generateId(),
    addedDate: now,
  );
  if (newDumplingsBatch != null) {
    prepStock = [...prepStock, newDumplingsBatch];
    print('Новая партия заготовки: ${newDumplingsBatch.quantity} ${newDumplingsBatch.unit}, '
        'зона ${newDumplingsBatch.zone}, срок годности до ${newDumplingsBatch.expiryDate}');
  }

  // ===================== ШАГ 6: ТЕПЕРЬ СУП С ПЕЛЬМЕНЯМИ ГОТОВ? =====================

  print('\n=== Проверяем "Суп с пельменями" ПОСЛЕ появления заготовки на складе ===');
  final soupMatchAfter = matchRecipe(recipe: rSoup, productStock: productStock, prepStock: prepStock);
  print('Готово к готовке: ${soupMatchAfter.isReadyToCook}');
  print('Нужно разморозить: ${soupMatchAfter.needsDefrostIngredients.map((r) => r.displayName).join(", ")}');

  // ===================== ШАГ 7: СПИСОК ПОКУПОК ИЗ БАННЕРА ДНЯ =====================

  print('\n=== Формируем список покупок из недостающего за день ===');
  final shoppingList = ShoppingList(id: generateId(), createdAt: now);
  var shoppingItems = addMissingFromDayAlerts(
    missingIngredients: dayAlerts.missingIngredients,
    existingItems: [],
    shoppingListId: shoppingList.id,
    productsById: productsById,
    generateId: generateId,
  );

  for (final item in shoppingItems) {
    print('  - ${item.baseProductName}: ${item.quantity} ${item.unit}');
  }

  // ===================== ШАГ 8: ГОТОВИМ РЕЦЕПТ ЧЕРЕЗ СЕССИЮ — ПРОВЕРКА ЗАКОНЧИВШИХСЯ ПРОДУКТОВ =====================

  final prepsById = <String, BasePrep>{dumplings.id: dumplings};

  print('\n=== Сессия готовки: готовим "Греческий салат" — проверка закончившихся продуктов ===');
  // Восстанавливаем сток до состояния ДО готовки плова (для чистоты демо)
  // Создадим свежий сток с помидором, который ДО готовки салата ещё есть
  final saladPrepStock = <ItemVariant>[]; // заготовок нет
  final saladProductStock = <ItemVariant>[
    ProductVariant(id: 'pv_cuc_1', baseItemId: cucumber.id, name: 'Огурец',
        zone: StockingZone.fridge, quantity: 100, unit: Unit.grams,
        addedDate: now),
    ProductVariant(id: 'pv_tom_1', baseItemId: tomato.id, name: 'Помидор',
        zone: StockingZone.fridge, quantity: 150, unit: Unit.grams,
        addedDate: now),
    ProductVariant(id: 'pv_feta_1', baseItemId: feta.id, name: 'Сыр фета',
        zone: StockingZone.fridge, quantity: 150, unit: Unit.grams,
        addedDate: now),
    ProductVariant(id: 'pv_oil_1', baseItemId: oliveOil.id, name: 'Оливковое масло',
        zone: StockingZone.pantry, quantity: 200, unit: Unit.milliliters,
        addedDate: now),
  ];

  final saladCookingRecipe = CookingRecipe(
    originalRecipe: rSalad,
    targetServings: 2,
    scaledIngredients: [
      ScaledIngredient(ingredientId: 'ri_10', baseProductId: cucumber.id,
          baseProductName: cucumber.name, scaledQuantity: 100, unit: Unit.grams),
    ],
    scaledPreps: [],
    steps: [
      CookingStep(originalStep: rSalad.steps[0], stepIndex: 0),
    ],
    totalCookingTimeMinutes: 10,
    effectiveCookingTimeMinutes: 10,
    hasAvailablePreps: false,
  );

  final saladResult = completeRecipe(
    cookingRecipe: saladCookingRecipe,
    productStock: saladProductStock,
    prepStock: saladPrepStock,
    prepsById: prepsById,
    productsById: productsById,
    generateId: generateId,
  );

  print('Закончились продукты:');
  if (saladResult.depletedProducts.isEmpty) {
    print('  (нет — все продукты остались на складе)');
  } else {
    for (final dp in saladResult.depletedProducts) {
      print('  - ${dp.baseProductName}: было израсходовано ${dp.consumedQuantity} ${dp.unit}');
    }
  }

  // Добавим их в список покупок
  shoppingItems = addDepletedFromCooking(
    depletedProducts: saladResult.depletedProducts,
    existingItems: shoppingItems,
    shoppingListId: shoppingList.id,
    productsById: productsById,
    generateId: generateId,
  );

  print('\n=== Итоговый список покупок (после добавления закончившихся) ===');
  final grouped = categorizeItems(items: shoppingItems, categories: categories);
  for (final entry in grouped.entries) {
    print('  ${entry.key.name}:');
    for (final item in entry.value) {
      print('    - ${item.baseProductName}: ${item.quantity} ${item.unit}'
          '${item.isChecked ? " [куплено]" : ""}');
    }
  }

  print('\n=== Отмечаем всё купленным, потом очищаем купленное ===');
  markAllAsChecked(shoppingItems);
  print('  После отметить всё: ${shoppingItems.where((i) => i.isChecked).length} куплено');
  shoppingItems = removeChecked(shoppingItems);
  print('  После очистки купленного: ${shoppingItems.length} осталось');
  shoppingItems = clearAll(shoppingItems);
  print('  После очистки всего списка: ${shoppingItems.length} элементов');
}