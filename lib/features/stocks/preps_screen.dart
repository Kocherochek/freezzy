import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';
//import 'package:freezzy/core/theme/app_theme.dart';
import 'package:freezzy/core/theme/main_filled_button.dart';

class PrepsScreen extends StatelessWidget {
  const PrepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back,color: AppColors.textMain,)
          ),
        title: const Text(
          'Заготовки',
          style: AppTypography.h2,
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding
        (padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2,),
            Image.asset(
              'assets/images/EmptyPreps.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.kitchen, size: 64, color: AppColors.textSecondary,),
              ),
            ),
            const SizedBox(height: 32,),

            Text(
              'Здесь пока пусто.',
              style: AppTypography.h1.copyWith(color: AppColors.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12,),
            Text(
              'Сюда будут попадать блюда, которые вы приготовили впрок через конструктор меню. Также вы можете внести свои домашние полуфабрикаты вручную.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32,),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: MainFilledButton(
                onPressed: () {
                  // Логика открытия формы добавления продукта
                },
                child: const Text(
                  'Добавить заготовку',
                ),
                ),
            ),

            const Spacer(flex: 3,),
          ],
        ),
        ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Логика открытия формы добавления продукта
          },
          child: const Icon(Icons.add, size: 28,),),
    );
  }
}