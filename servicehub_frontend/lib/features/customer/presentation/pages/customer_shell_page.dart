import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';



/// The customer-side shell that hosts the five bottom tabs.
///
/// `StatefulShellRoute.indexedStack` in the router passes us a
/// [StatefulNavigationShell] which we use to render the tab bar and
/// switch between branches.
class CustomerShellPage extends ConsumerWidget {
  const CustomerShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _CustomerBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _CustomerBottomBar extends StatelessWidget {
  const _CustomerBottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _Tab(
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _Tab(
                label: 'Discover',
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _Tab(
                label: 'Requests',
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _Tab(
                label: 'Messages',
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _Tab(
                label: 'Profile',
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
