// lib/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_constants.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/communes')) return 1;
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/signal')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _getIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: _BudgetNavBar(currentIndex: index),
    );
  }
}

class _BudgetNavBar extends StatelessWidget {
  final int currentIndex;

  const _BudgetNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil', path: '/accueil'),
      _NavItem(icon: Icons.location_city_outlined, activeIcon: Icons.location_city, label: 'Communes', path: '/communes'),
      _NavItem(icon: Icons.qr_code_scanner, activeIcon: Icons.qr_code_scanner, label: 'Scan', path: '/scan'),
      _NavItem(icon: Icons.flag_outlined, activeIcon: Icons.flag, label: 'Signal', path: '/signal'),
    ];

    return Container(
      height: AppDimens.navBarHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = i == currentIndex;
            final isCenter = i == 2; // Scan is special

            return Expanded(
              child: GestureDetector(
                onTap: () => context.go(item.path),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isCenter
                        ? Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.accent : AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: AppColors.white,
                              size: 20,
                            ),
                          )
                        : Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive ? AppColors.accent : AppColors.navInactive,
                            size: 22,
                          ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.accent : AppColors.navInactive,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
