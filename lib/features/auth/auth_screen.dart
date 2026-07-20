import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart'; 
import 'package:freezzy/core/theme/app_typography.dart';
import 'package:freezzy/core/theme/main_filled_button.dart';
import 'package:freezzy/features/navigation/presentation/main_screen.dart';
//import 'package:freezzy/core/theme/app_theme.dart'; // Подключили файл шрифтов

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Контроллеры для считывания текста
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Состояния экрана
  bool _isLoginMode = true; // true = Вход, false = Регистрация
  bool _obscurePassword = true; // Скрытие/показ текста пароля
  bool _isFormValid = false; // Для динамического изменения состояния кнопки

  @override
  void initState() {
    super.initState();
    // Слушаем изменения в полях, чтобы вовремя активировать/деактивировать кнопку
    _emailController.addListener(_validateFormSilently);
    _passwordController.addListener(_validateFormSilently);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Метод «тихой» валидации для управления состоянием кнопки До нажатия на неё
  void _validateFormSilently() {
    final email = _emailController.text;
    final password = _passwordController.text;

    // Регулярное выражение для базовой проверки Email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    bool isValid = emailRegex.hasMatch(email) && password.length >= 6;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  // Действие при отправке формы
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLoginMode) {
        // debugPrint вместо print — профессиональный стандарт для логов разработки
        debugPrint('Выполняем вход для: $email (пароль: ${password.replaceAll(RegExp(r'.'), '*')})');
      } else {
        debugPrint('Регистрируем пользователя: $email (пароль длиной ${password.length} симв.)');
      }

      // Навигация: очищаем стек экранов и открываем главный экран
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainScreen(),
          ),
          (route) => false,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [                
                const SizedBox(height: 100),
                Image.asset('assets/images/Authorisation_screen.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,),

                const SizedBox(height: 60),

                // --- 2. ЦЕНТРАЛЬНЫЙ БЛОК (Форма ввода) ---
                // Поле №1: Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  // Основной текст ввода (Montserrat, Regular/Medium, 14)
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMain,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Email',                    
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Пожалуйста, введите Email';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Введите корректный адрес почты';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),

                // Поле №2: Пароль
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Пароль',                   
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть не менее 6 символов';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // --- 3. НИЖНИЙ БЛОК (Кнопки действия) ---
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: MainFilledButton(
                    onPressed: _isFormValid ? _submitForm : null,
                    child: Text(
                      _isLoginMode ? 'Войти' : 'Зарегистрироваться',
                      // Стиль для текста кнопок (Montserrat, SemiBold, 16)
                      style: AppTypography.button.copyWith(
                        color: _isFormValid ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Ссылка-переключатель режимов
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      _formKey.currentState?.reset();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      // Базовый стиль ссылки (Montserrat, Medium, 14)
                      style: AppTypography.searchHint,
                      children: [
                        TextSpan(
                          text: _isLoginMode ? 'Ещё нет аккаунта? ' : 'Уже есть аккаунт? ',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        TextSpan(
                          text: _isLoginMode ? 'Зарегистрироваться' : 'Войти',
                          style: const TextStyle(color: AppColors.accentMain),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}