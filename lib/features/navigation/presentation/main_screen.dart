import 'package:flutter/material.dart';
import 'package:freezzy/core/theme/app_typography.dart';
import 'package:freezzy/core/theme/app_colors.dart';
import 'package:freezzy/features/stocks/stocks_tab.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}
  
  class _MainScreenState extends State<MainScreen> {
    int _currentIndex = 0;

    //Список под-экранов, которые будут подставляться в центральную часть
    late final List<Widget> _pages;

    @override
    void initState() {
      super.initState();
      _pages = [
        const StocksTab(),
        const Center(
          child: Text('Конструктор меню в разработке', style: AppTypography.h1, textAlign: TextAlign.center),),
        const Center(
          child: Text('Рецепты в разработке', style: AppTypography.h1, textAlign: TextAlign.center),),
        const Center(
          child: Text('Список покупок в разработке', style: AppTypography.h1, textAlign: TextAlign.center),), 
      ];
    }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _pages[_currentIndex],
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFooterTab(index: 0, icon: Icons.kitchen_outlined, label: 'мои запасы'),
          _buildFooterTab(index: 1, icon: Icons.blender_outlined, label: 'конструктор меню'),
          _buildFooterTab(index: 2, icon: Icons.menu_book_outlined, label: 'рецепты\nбаза знаний'),
          _buildFooterTab(index: 3, icon: Icons.shopping_bag_outlined, label: 'покупки'),
        ],        
      ),
    );
  }


  Widget _buildFooterTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: isActive
        ? null
        : () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.accentMain : Colors.grey.withValues(alpha: 0.6),
                size: 26,
              ),
              const SizedBox(height: 4,),
              SizedBox(
                height: 32,
                child: Text(
                  label,
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: AppTypography.buttonSmall.copyWith(
                    color: isActive ? AppColors.accentMain : Colors.grey.withValues(alpha: 0.6),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  }
