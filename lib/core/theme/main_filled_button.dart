import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';

class MainFilledButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const MainFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  });

  @override
  State<MainFilledButton> createState() => _MainFilledButtonState();
}

class _MainFilledButtonState extends State<MainFilledButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
   
    // Состояния кнопки
    final List<BoxShadow> shadows = !_isEnabled
        ? [] // Нет тени у выключенной
        : _isPressed
            ? [
                // Тень при нажатии (сжатая)
                BoxShadow(
                  color: AppColors.accentMain.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                // Сложная "дорогая" тень в обычном состоянии
                BoxShadow(
                  color: AppColors.accentMain.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8), // Мягкая глубокая тень снизу
                ),
                BoxShadow(
                  color: const Color(0xFFB57EDC).withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ];

    // Градиент для глянца (сверху светлее, снизу темнее)
    final Gradient buttonGradient = !_isEnabled
        ? LinearGradient(
            colors: [
              AppColors.accentMain.withValues(alpha: 0.2),
              AppColors.accentMain.withValues(alpha: 0.15),
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFB8A9D1), // Светлый лавандовый блик вверху
              AppColors.accentMain,              // Основная лаванда в центре
              const Color(0xFF7D6A9C), // Глубокий лавандовый внизу (объем)
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    return GestureDetector(
      onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: _isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100), // StadiumBorder эффект
          gradient: buttonGradient,
          boxShadow: shadows,
          // Тонкий светлый кант сверху создает эффект глянцевой фаски стекла
          border: Border.all(
            color: _isEnabled 
                ? Colors.white.withValues(alpha: 0.25) 
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding,
                child: DefaultTextStyle(
                  style: AppTypography.button.copyWith(
                    color: _isEnabled ? Colors.white : AppColors.textSecondary,
                    
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}