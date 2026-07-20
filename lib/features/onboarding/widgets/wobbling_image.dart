//import 'dart:math' as math;
import 'package:flutter/material.dart';

class WobblingImage extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;

  const WobblingImage({
    super.key,
    required this.assetPath,
    this.width = 393,
    this.height = 556,
  });

  @override
  State<WobblingImage> createState() => _WobblingImageState();
}

class _WobblingImageState extends State<WobblingImage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Инициализируем контроллер. Длительность 3 секунды для плавного, ленивого покачивания.
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Настраиваем кривую скорости: замедление к краям и ускорение к центру (easeInOut)
    // Поворачивать будем на небольшой угол (примерно на 2-3 градуса в радианах)
    _animation = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Запускаем анимацию в режиме "туда-обратно" бесконечно
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    // Обязательно освобождаем ресурсы контроллера, чтобы не было утечек памяти
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // ИСПОЛЬЗУЕМ МАТРИЦУ ТРАНСФОРМАЦИИ: 
          // Она слегка наклоняет (покачивает) картинку вокруг ее центра
          return Transform.rotate(
            angle: _animation.value,
            child: child,
          );
        },
        // Сам ассет передаем в child, чтобы он не перерисовывался каждый кадр впустую
        child: Image.asset(
          widget.assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}