import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/artisan/presentation/providers/artisan_conversations_providers.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';

class ArtisanShellPage extends ConsumerWidget {
  const ArtisanShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _ArtisanBottomBar(
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

class _ArtisanBottomBar extends ConsumerWidget {
  const _ArtisanBottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                label: 'Requests',
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _Tab(
                label: 'Messages',
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                showUnreadDot: ref.watch(artisanUnreadCountProvider) > 0,
              ),
              _Tab(
                label: 'Earnings',
                icon: Icons.payments_outlined,
                activeIcon: Icons.payments,
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
    this.showUnreadDot = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final bool showUnreadDot;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, size: 22, color: color),
                if (showUnreadDot)
                  Positioned(
                    top: -1,
                    right: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
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
