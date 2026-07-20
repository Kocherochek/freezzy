import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';
import 'package:freezzy/core/theme/main_filled_button.dart';
import 'package:freezzy/core/theme/secondary_outlined_button.dart';
import 'package:freezzy/features/auth/auth_screen.dart';

class ProfileSettingsScreen extends StatefulWidget{
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _expiryNotification = true;
  bool _defrostNotification = false;

  // Метод для вызова диалога подтверждения выхода
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.all(24),
          title: const Text(
            'Выйти из аккаунта',
            style: AppTypography.h2,
          ),
          content: Text(
            'Вы сможете войти снова, используя свой email. Все ваши запасы и списки сохранятся',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: MainFilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ОТМЕНА', style: AppTypography.button,)
                    ),
                ),
                const SizedBox(height: 12,),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: SecondaryOutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      // Полностью сбрасываем стек и уходим на экран авторизации
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen()
                          ),
                        (route) => false,
                        );
                    },
                    child: const Text(
                      'Выйти',
                      style: AppTypography.button,
                    )
                    ),
                )
              ],
            )
          ],
        );
      }
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain,)
          ),
          title: const Text(
            'Профиль и настройки',
            style: AppTypography.h2,
          ),
          centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accentSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.textSecondary, width: 1.0),
                  ),
                  child: const Icon(
                    Icons.person_2_outlined,
                    size: 36,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: 16,),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Катя', style: AppTypography.h2,),
                      Text(
                        'kate@freezzy.com',
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6,),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFB8A9D1), // Светлый лавандовый блик вверху
                              AppColors.accentMain,              // Основная лаванда в центре
                              const Color(0xFF7D6A9C),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Базовый тариф',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
              ],
              ),
              const SizedBox(height: 32,),
              const Divider(color: AppColors.textSecondary, thickness: 0.5,),
              const SizedBox(height: 16),

              const Text('Уведомления', style: AppTypography.h2,),
              const SizedBox(height: 16),

              // Сроки годности
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.accentMain,
                title: const Text('Сроки годности продуктов', style: AppTypography.body,),
                subtitle: Text(
                  'Напоминать когда у продуктов в холодильнике истекает срок годности',
                  style: AppTypography.chips,
                ),
                value: _expiryNotification,
                onChanged: (bool value) {
                  setState(() {
                    _expiryNotification = value;
                  });
                }
                ),
                const SizedBox(height: 8,),

                SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.accentMain,
                title: const Text('Разморозка продуктов/заготовок', style: AppTypography.body,),
                subtitle: Text(
                  'Напоминать о необходимости достать продукт из морозилки',
                  style: AppTypography.chips,
                ),
                value: _defrostNotification,
                onChanged: (bool value) {
                  setState(() {
                    _defrostNotification = value;
                  });
                },
                ),

                const SizedBox(height: 24,),
                const Divider(color: AppColors.textSecondary, thickness: 0.5,),
                const SizedBox(height: 16,),

                // --- Блок "О приложении" ---
                const Text('О приложении', style: AppTypography.h2),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    'Политика конфеденциальности',
                    style: AppTypography.body,
                  ),
                  ),

                  const SizedBox(height: 4),

                  TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    'Пользовательское соглашение',
                    style: AppTypography.body,
                  ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Версия приложения', style: AppTypography.body,),
                      Text(
                        '1.0.0', style: AppTypography.body,
                      )
                    ],
                  ),

                  const SizedBox(height: 48),

                  Center(
                    child: TextButton(
                      onPressed: _showLogoutDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Выйти из аккаунта?',
                        style: AppTypography.body.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                      ),
                  )
          ],
          
        ),
        
      ),
    );
  }
}