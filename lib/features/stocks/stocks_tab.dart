import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/core/theme/app_typography.dart';
import 'package:freezzy/features/profile/presentation/profile_settings_screen.dart';
import 'package:freezzy/features/stocks/add_product_screen.dart';
import 'package:freezzy/features/stocks/products_screen.dart';
import 'package:freezzy/features/stocks/preps_screen.dart';
import 'package:freezzy/features/stocks/widgets/stock_card.dart';

class StocksTab extends StatelessWidget {
  const StocksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Мои запасы',
              style: AppTypography.h1,
            ),
            IconButton(onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(),
                  ),
              );
            },
             icon: const Icon(Icons.settings_outlined, size: 26, color: AppColors.accentMain,),
             ),
          ],
        ),
        ),
        Expanded( 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Expanded(
                child: StockCard(
                  title: 'Продукты',
                  subtitle: '14 категорий * 29 наименований',
                  backgroundColor: AppColors.accentSecondary,
                  badgeColor: const Color(0xFFB9E5D5),
                  imageAsset: 'assets/images/MyStocks.png',
                  onCardTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProductsScreen(),
                        ),
                    );
                  },
                  onPlusTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                        fullscreenDialog: true,
                        )
                    );
                  },
                  ),
                  ),

                  const SizedBox(height: 20,),

                  Expanded(
                    child: StockCard(
                      title: 'Заготовки',
                      subtitle: '8 видов • хватит на 12 блюд',
                      backgroundColor: AppColors.accentMain,
                      badgeColor: const Color(0xFFB9E5D5),
                      imageAsset: 'assets/images/MyPreps.png',
                      onCardTap: () {Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrepsScreen(),
                        ),
                    );},
                      onPlusTap: () {},
                      ),
                      ),
            ],
          ),
        ),)
      ],
    );
  }
}
