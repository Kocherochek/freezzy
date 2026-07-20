import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';

class SecondaryOutlinedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const SecondaryOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<SecondaryOutlinedButton> createState() =>
      _SecondaryOutlinedButtonState();
}

class _SecondaryOutlinedButtonState extends State<SecondaryOutlinedButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    // Состояния кнопки
    final List<BoxShadow> shadows = !_isEnabled
        ? [] // нет тени у выключенной
        : _isPressed
        ? [
            // тень при нажатии сжатая
            BoxShadow(
              color: AppColors.neonLimeShadow.withValues(alpha: 0.05),
              blurRadius: 4.0,
              offset: const Offset(1, 8),
            ),
          ]
        : [
            // Сложная "дорогая" тень в обычном состоянии
            BoxShadow(
              color: AppColors.neonLimeShadow.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(4, 16), // Мягкое парение над экраном
            ),
            BoxShadow(
              color: AppColors.accentSecondary.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(2, 6),
            ),
          ];
    // Логика цвета рамки и текста
    final Gradient? glassGradient = !_isEnabled
        ? null
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.12),
                AppColors.background,
              ),
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.06),
                AppColors.background,
              ),
              Color.alphaBlend(
                AppColors.accentSecondary.withValues(alpha: 0.04),
                AppColors.background,
              ),
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    final Color currentElementColor = !_isEnabled
        ? AppColors.neonLimeShadow
        : AppColors.accentSecondary;

    // Легкий глянцевый/матовый задний фон "стекла" внутри кнопки
    final Color glassColor = _isEnabled
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.transparent;

    return GestureDetector(
      onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: _isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(microseconds: 100),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: shadows,
          gradient: glassGradient,

          // Оливковая рамка толщиной 2.5px
          border: Border.all(
            color: currentElementColor.withValues(
              alpha: _isEnabled ? 0.6 : 0.2,
            ),
            width: _isPressed ? 2.0 : 3.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: glassColor,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  // Эффект волны при нажатии окрашиваем в цвет рамки
                  splashColor: currentElementColor.withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: DefaultTextStyle(
                      style: AppTypography.button.copyWith(
                        color: currentElementColor,
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
        ),
      ),
    );
  }
}