import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';

class CategoryBadge extends StatelessWidget{
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const CategoryBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor = AppColors.textMain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        text,
        style: AppTypography.chips.copyWith(color: textColor),
      ),
    ); 
  }
}