import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_typography.dart';
// Импортируй свои созданные виджеты. Пути могут немного отличаться в зависимости от твоей структуры папок:
import 'package:freezzy/features/onboarding/widgets/next_button.dart';
import 'package:freezzy/features/onboarding/widgets/onboarding_dots.dart';
import 'package:freezzy/features/onboarding/widgets/wobbling_image.dart';
import 'package:freezzy/features/auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  final int _pageCount = 3;

  // Твои три новых изображения для экранов онбординга
  final List<String> _onboardingImages = [
    'assets/images/Onboarding_1.png', // Например: умный учет запасов
    'assets/images/Onboarding_2.png', // Например: конструктор меню
    'assets/images/Onboarding_3.png', // Например: стартовые паки еды
  ];

  // Тексты для экранов
  final List<String> _titles = [
    "Умный учёт запасов",
    "Готовка впрок",
    "Экономия и баланс",
  ];

  final List<String> _descriptions = [
    "Приложение помнит всё, что лежит в вашем холодильнике и шкафах, и предупредит, если у продуктов истекает срок годности.",
    "Планируйте меню, создавайте домашние полуфабрикаты и замораживайте их правильно по нашим кулинарным лайфхакам.",
    "Тратьте меньше времени в магазинах. Конструктор сам соберёт меню на день и сформирует точный список покупок.",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Хедер: Индикатор страниц по центру и Крестик справа
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageIndicator(
                    currentPage: _currentPage,
                    pageCount: _pageCount,                    
                  ),
                  Positioned(
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        // Логика пропуска онбординга (например, переход на AuthScreen)
                      },
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(Icons.close, color: Color(0xFF3E3835)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Центральный контент с PageView
            Padding(
              padding: const EdgeInsets.only(top: 60.0, bottom: 80.0),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ИСПОЛЬЗУЕМ НАШУ АНИМИРОВАННУЮ КАРТИНКУ
                      WobblingImage(
                        assetPath: _onboardingImages[index],
                        width: 393,
                        height: 400, // Сделали чуть компактнее по высоте, чтобы точно влез текст
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _titles[index],
                          style: AppTypography.h1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _descriptions[index],
                          style: AppTypography.body,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Подвал: Кнопка действия «Далее» / «Начать» в правом нижнем углу
            Positioned(
              bottom: 24,
              right: 16,
              child: NextButton(
                text: _currentPage == _pageCount - 1 ? 'Начать' : 'Далее',
                onTap: () {
                  if (_currentPage < _pageCount - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}