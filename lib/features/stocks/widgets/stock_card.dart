import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';
import 'package:freezzy/features/stocks/widgets/category_badge.dart';

class StockCard extends StatelessWidget{
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color badgeColor;
  final String imageAsset;
  final VoidCallback onCardTap;
  final VoidCallback onPlusTap;

  const StockCard({
    super.key,
    required this.title,
    required this. subtitle,
    required this.backgroundColor,
    required this.badgeColor,
    required this.imageAsset,
    required this.onCardTap,
    required this.onPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                width: 150,
                height: 150,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.h2,
                          ),                        
                        const SizedBox(height: 8,),

                        CategoryBadge(
                          text: subtitle,
                          backgroundColor: badgeColor,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onPlusTap,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 24,
                          color: AppColors.accentMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );    
  }
}