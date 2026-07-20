import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    super.key,
    required this.currentPage,
    this.pageCount = 3, // По ТЗ у нас 3 экрана онбординга
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final bool isActive = index == currentPage;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          // По ТЗ: активная — капсула 24×8, неактивная — кружок 8×8
          width: isActive ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            // Активная точка берет акцентный лавандовый, неактивная — пастельный серый
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}