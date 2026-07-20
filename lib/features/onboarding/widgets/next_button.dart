import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_typography.dart';
import 'package:freezzy/core/theme/main_filled_button.dart';

class NextButton extends StatelessWidget {
  final void Function()? onTap;
  final String text; //Добавляем поле для текста на кнопке

  const NextButton({
    super.key,
    required this.onTap,
    this.text = 'Далее',// по умолчанию будет Далее
  });

  @override
  Widget build(BuildContext context) {
    
    return MainFilledButton(
      onPressed: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text, 
        style: AppTypography.buttonSmall,
        )
      );
  }
}