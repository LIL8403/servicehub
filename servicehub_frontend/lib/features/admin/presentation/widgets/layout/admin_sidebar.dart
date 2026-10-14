import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class AdminNavItem {
  const AdminNavItem({
    required this.path,
    required this.label,
    required this.icon,
    this.badge,
  });

  final String path;
  final String label;
  final IconData icon;
  final int? badge;
}

const _navItems = <AdminNavItem>[
  AdminNavItem(
    path: '/admin/dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  AdminNavItem(
    path: '/admin/users',
    label: 'Users',
    icon: Icons.group_outlined,
  ),
  AdminNavItem(
    path: '/admin/verification',
    label: 'Artisan Verification',
    icon: Icons.verified_user_outlined,
  ),
  AdminNavItem(
    path: '/admin/service-categories',
    label: 'Service Categories',
    icon: Icons.category_outlined,
  ),
  AdminNavItem(
    path: '/admin/services',
    label: 'Services',
    icon: Icons.handyman_outlined,
  ),
  AdminNavItem(
    path: '/admin/service-requests',
    label: 'Service Requests',
    icon: Icons.assignment_outlined,
  ),
  AdminNavItem(
    path: '/admin/payments',
    label: 'Payments',
    icon: Icons.payments_outlined,
  ),
  AdminNavItem(
    path: '/admin/payouts',
    label: 'Payouts',
    icon: Icons.account_balance_wallet_outlined,
  ),
  AdminNavItem(
    path: '/admin/disputes',
    label: 'Disputes',
    icon: Icons.gavel_outlined,
  ),
  AdminNavItem(
    path: '/admin/reviews',
    label: 'Reviews',
    icon: Icons.star_outline,
  ),
  AdminNavItem(
    path: '/admin/ai-intelligence',
    label: 'AI Intelligence',
    icon: Icons.insights_outlined,
  ),
  AdminNavItem(
    path: '/admin/notifications',
    label: 'Notifications',
    icon: Icons.notifications_outlined,
  ),
  AdminNavItem(
    path: '/admin/reports',
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
  ),
  AdminNavItem(
    path: '/admin/audit-logs',
    label: 'Audit Logs',
    icon: Icons.history_outlined,
  ),
  AdminNavItem(
    path: '/admin/settings',
    label: 'Platform Settings',
    icon: Icons.settings_outlined,
  ),
];

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.currentPath,
    required this.onSignOut,
    this.verificationBadge,
    this.disputesBadge,
  });

  final String currentPath;
  final VoidCallback onSignOut;

  /// Live count for the Artisan Verification badge. When null, no
  /// badge is shown.
  final int? verificationBadge;

  /// Live count for the Disputes badge. When null, no badge is shown.
  final int? disputesBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brandBlock(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (var i = 0; i < _navItems.length; i++) ...[
                    _navRow(context, _navItems[i]),
                    if (i == 8) _divider(),
                  ],
                ],
              ),
            ),
          ),
          _logoutRow(context),
          _statusCard(),
        ],
      ),
    );
  }

  Widget _brandBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: SvgPicture.asset(
              'assets/brand/logo_symbol.svg',
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Service',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: 'HUB',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ADMINISTRATOR',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _navRow(BuildContext context, AdminNavItem item) {
    final isActive = currentPath == item.path ||
        (item.path == '/admin/dashboard' && currentPath == '/admin');

    // Use the live count for the two dynamic badges.
    int? effectiveBadge = item.badge;
    if (item.path == '/admin/verification') {
      effectiveBadge = verificationBadge;
    } else if (item.path == '/admin/disputes') {
      effectiveBadge = disputesBadge;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (currentPath == item.path) return;
          context.go(item.path);
        },
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.secondary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? AppColors.secondary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (effectiveBadge != null && effectiveBadge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    effectiveBadge > 99 ? '99+' : '$effectiveBadge',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutRow(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSignOut,
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                size: 20,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 16),
              Text(
                'Sign out',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ServiceHUB',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'v1.0 · Production',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}