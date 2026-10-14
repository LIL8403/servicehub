import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ArtisanProfileTab extends ConsumerWidget {
  const ArtisanProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    final hasCustomerRole = user?.hasRole('customer') ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: AppRadii.borderLg,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (user?.firstName.isNotEmpty ?? false)
                        ? user!.firstName[0].toUpperCase()
                        : 'A',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user?.fullName ?? 'Artisan',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Tile(
            icon: Icons.badge_outlined,
            label: 'Verification center',
            onTap: () => context.push('/artisan-home/profile/verification'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Tile(
            icon: Icons.edit_outlined,
            label: 'Edit professional profile',
            onTap: () => context.push('/artisan-home/profile/edit'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Tile(
            icon: Icons.work_outline,
            label: 'Service offerings',
            onTap: () => context.push('/artisan-home/profile/offerings'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Tile(
            icon: Icons.schedule,
            label: 'Availability',
            onTap: () => context.push('/artisan-home/profile/availability'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Tile(
            icon: Icons.language,
            label: 'Language',
            trailingLabel: 'EN | FR',
            onTap: () => _comingSoon(context, 'Language'),
          ),
          if (hasCustomerRole) ...[
            const SizedBox(height: AppSpacing.sm),
            _Tile(
              icon: Icons.swap_horiz,
              label: 'Switch to customer view',
              onTap: () => _onSwitchToCustomer(context, ref),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: AppColors.cardLight,
            borderRadius: AppRadii.borderLg,
            child: InkWell(
              borderRadius: AppRadii.borderLg,
              onTap: () async {
                await ref.read(authStateProvider.notifier).logout();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.borderLg,
                  border: Border.all(color: AppColors.borderLight),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.errorTint,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.logout,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Log out',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSwitchToCustomer(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authStateProvider.notifier).switchRole('customer');
      if (!context.mounted) return;
      context.go('/customer-home');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not switch to customer: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming in a later batch.')),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
