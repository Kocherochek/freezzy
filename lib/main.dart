import 'package:flutter/material.dart';
//import 'package:freezzy/features/auth/auth_screen.dart';
import 'package:freezzy/features/navigation/presentation/main_screen.dart';
//import 'package:freezzy/features/onboarding/welcome_screen.dart';
import 'core/theme/app_theme.dart';
// Импортируем нашу тему

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Исправили key для поддержки современных стандартов Dart

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freezzy - Кулинарный планировщик',
      debugShowCheckedModeBanner: false, // Отключаем красный баннер "Debug" в углу
      
      // Передаем нашу настроенную прованскую тему!
      theme: AppTheme.lightTheme,
      
      // Временный стартовый экран, пока мы верстаем Onboarding
      home: const MainScreen(), 
    );
  }
}

// Временная заглушка, чтобы проверить, как применились цвета и шрифты
class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Хедер автоматически покрасится в цвет фона, а текст возьмет настройки темы
      appBar: AppBar(
        title: Text(
          'Прованс Кухня', 
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Умный учёт запасов',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center, // Исправили Center на TextAlign.center
            ),
            const SizedBox(height: 12),
            Text(
              'Приложение помнит всё, что лежит в вашем холодильнике, и предупредит о сроках годности.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Стандартная кнопка — цвета и скругления подтянутся автоматически из темы!
            FilledButton(
              onPressed: () {},
              child: const Text('Далее'),
            ),
            const SizedBox(height: 12),
            // Пример того, как кнопка выглядит в неактивном состоянии (onPressed: null)
            const FilledButton(
              onPressed: null,
              child: Text('Кнопка неактивна'),
            ),
          ],
        ),
      ),
      // FAB тоже автоматически станет лавандовой с белым плюсиком
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}