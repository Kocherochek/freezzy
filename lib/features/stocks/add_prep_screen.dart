import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';
import 'package:freezzy/core/theme/main_filled_button.dart';

class AddPrepScreen extends StatefulWidget {
  const AddPrepScreen({super.key});

  @override
  State<AddPrepScreen> createState() => _AddPrepScreenState();
}

class _AddPrepScreenState extends State<AddPrepScreen> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей ввода
  final TextEditingController _customItemVariantController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Списки для выпадающих меню (в будущем пойдут из БД)
  final List<String> _categories = [
    'Мясные полуфабрикаты',
    'Готовые мясные блюда',
    'Бульоны, супы, соусы',
    'Овощи, заправки',
    'Рыбные полуфабрикаты',
    'Тесто, натертый сыр',
  ];
  final Map<String, List<String>> _baseItems = {
    'Мясные полуфабрикаты': ['Котлеты необжаренные', 'Фрикадельки', 'Пельмени', 'Фарш'],
    'Бульоны, супы, соусы': ['Бульон куриный', 'Борщ', 'Бульон рыбный', 'Песто соус'],
    'Овощи, заправки': ['Зажарка лук и морковь', 'Морковь натертая', 'Овощной микс', 'Шампиньоны с луком обжаренные'],
  };
  final Map<String, List<String>> _itemVariants = {
    'Фарш': ['Свинина и говядина', 'Куриное филе', 'Курица и индейка'],
    'Бульон куриный': ['Бульон куриный светлый', 'Бульон куриный темный (консоме)', 'Бульон куриный концентрат 1:2'],
    'Пельмени': ['Свинина и говядина', 'Курица', 'Индейка'],
  };
  final List<String> _units = ['шт', 'гр', 'кг', 'мл', 'л', 'упак'];

  String? _selectedCategory;
  String? _selectedBaseItem;
  String? _selectedItemVariant;
  bool _isCustomItemVariantMode =
      false; // Флаг для ручного ввода конкретного вида продукта
  String _selectedUnit = 'шт';

  @override
  void dispose() {
    _customItemVariantController.dispose();
    _dateController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Функция вызова календаря
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate:
          DateTime.now(), // Нельзя выбрать прошедшую дату для свежих продуктов
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Вычисляем доступную ширину для DropdownMenu с учетом боковых отступов формы (20 + 20 = 40)
    final double dropdownWidth = MediaQuery.of(context).size.width - 40;

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить заготовку'), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Основной скроллируемый контент формы ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- УРОВЕНЬ 1: КАТЕГОРИЯ (Обычный Дропдаун) ---
                      const Text('Категория', style: AppTypography.body),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        hint: const Text('Выберите категорию'),
                        items: _categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            _selectedBaseItem = null; // Сброс нижних уровней
                            _selectedItemVariant = null;
                            _isCustomItemVariantMode = false;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Укажите категорию' : null,
                      ),

                      const SizedBox(height: 24),

                      // --- УРОВЕНЬ 2: БАЗОВЫЙ ПРОДУКТ (С умным поиском по буквам) ---
                      const Text('Заготовка', style: AppTypography.body),
                      const SizedBox(height: 8),
                      DropdownMenu<String>(
                        key: ValueKey(
                          _selectedCategory,
                        ), // Пересоздает виджет и очищает текст при смене категории
                        width: dropdownWidth,
                        enabled: _selectedCategory != null,
                        enableFilter:
                            true, // Включает поиск по введенным буквам (напр. "тво")
                        requestFocusOnTap:
                            true, // Открывает клавиатуру при фокусе
                        hintText: _selectedCategory == null
                            ? 'Сначала выберите категорию'
                            : 'Что именно добавляем? (напр., Пельмени)',
                        inputDecorationTheme: Theme.of(
                          context,
                        ).inputDecorationTheme,
                        dropdownMenuEntries: _selectedCategory == null
                            ? []
                            : _baseItems[_selectedCategory]!.map((prod) {
                                return DropdownMenuEntry<String>(
                                  value: prod,
                                  label: prod,
                                );
                              }).toList(),
                        onSelected: (value) {
                          setState(() {
                            _selectedBaseItem = value;
                            _selectedItemVariant = null; // Сброс 3 уровня
                            _isCustomItemVariantMode = false;
                          });
                        },
                      ),
                      // Небольшой костыль для валидации DropdownMenu, так как у него нет встроенного валидатора
                      if (_selectedCategory != null &&
                          _selectedBaseItem == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0, left: 16.0),
                          child: Text(
                            'Выберите заготовку из списка или поиска',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24.0),

                      // --- УРОВЕНЬ 3: КОНКРЕТНЫЙ ВИД / МАРКА (Дропдаун + Свой вариант) ---
                      const Text('Вид или состав', style: AppTypography.body),
                      const SizedBox(height: 8.0),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedItemVariant,
                        hint: Text(
                          _selectedBaseItem == null
                              ? 'Сначала выберите заготовку'
                              : 'Выберите конкретный вид',
                        ),
                        items: _selectedBaseItem == null
                            ? []
                            : [
                                // Подгружаем готовые варианты, если для этого продукта они есть
                                if (_itemVariants.containsKey(
                                  _selectedBaseItem,
                                ))
                                  ..._itemVariants[_selectedBaseItem]!.map(
                                    (spec) => DropdownMenuItem(
                                      value: spec,
                                      child: Text(spec),
                                    ),
                                  ),
                                // Добавляем специальную фиолетовую кнопку ручного ввода
                                const DropdownMenuItem(
                                  value: 'custom_item',
                                  child: Text(
                                    '+ Добавить свой вариант...',
                                    style: TextStyle(
                                      color: AppColors.accentMain,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                        onChanged: _selectedBaseItem == null
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedItemVariant = value;
                                  _isCustomItemVariantMode =
                                      (value == 'custom_item');
                                });
                              },
                        validator: (value) =>
                            value == null ? 'Выберите вид заготовки' : null,
                      ),

                      // --- ДИНАМИЧЕСКОЕ ПОЛЕ РУЧНОГО ВВОДА ---
                      if (_isCustomItemVariantMode) ...[
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _customItemVariantController,
                          decoration: const InputDecoration(
                            labelText: 'Название вашего варианта',
                            hintText: 'Например: Вареники бабушкины с ежевикой',
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Введите название нового вида'
                              : null,
                        ),
                      ],

                      const SizedBox(height: 24.0),

                      // --- БЛОК: КОЛИЧЕСТВО И ЕДИНИЦЫ ИЗМЕРЕНИЯ ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Количество',
                                  style: AppTypography.body,
                                ),
                                const SizedBox(height: 8.0),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите количество';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Нужно число';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ед. изм.',
                                  style: AppTypography.body,
                                ),
                                const SizedBox(height: 8.0),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedUnit,
                                  items: _units
                                      .map(
                                        (unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedUnit = value!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24.0),

                      // --- БЛОК: СРОК ГОДНОСТИ ---
                      const Text('Срок годности', style: AppTypography.body),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _dateController,
                        readOnly:
                            true, // Запрет клавиатуры, ввод строго через календарь
                        decoration: InputDecoration(
                          hintText: 'ДД.ММ.ГГГГ',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.accentMain,
                            ),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Выберите дату'
                            : null,
                      ),

                      const SizedBox(height: 16.0),

                      // --- НИЖНИЙ БЛОК: ФИРМЕННАЯ КНОПКА СОХРАНЕНИЯ ---
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: MainFilledButton(                        
                          onPressed:
                              (_selectedBaseItem != null &&
                                  _selectedItemVariant != null)
                              ? () {
                                  if (_formKey.currentState!.validate()) {
                                    final finalSpecificName =
                                        _isCustomItemVariantMode
                                        ? _customItemVariantController.text
                                        : _selectedItemVariant;
                        
                                    // Логика отправки в локальную базу данных (Isar/Hive)
                                    debugPrint(
                                      'Успешно собрано для БД: '
                                      '$_selectedCategory -> $_selectedBaseItem -> $finalSpecificName '
                                      '(${_quantityController.text} $_selectedUnit) до ${_dateController.text}',
                                    );
                        
                                    Navigator.of(context).pop();
                                  }
                                }
                              : null, // Если null — кнопка красиво бледнеет благодаря твоей логике в MainFilledButton
                          child: const Text('Сохранить'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
