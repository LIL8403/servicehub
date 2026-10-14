import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/become_artisan_modal.dart';

class CustomerProfileTab extends ConsumerWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    final hasArtisanRole = user?.hasRole('artisan') ?? false;
    final isCustomerActive = user?.activeRole == 'customer';
    final showBecomeArtisan = !hasArtisanRole;
    final showSwitchToArtisan = hasArtisanRole && isCustomerActive;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account settings are coming soon.'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _IdentityCard(
            name: user?.fullName ?? 'Customer',
            email: user?.email ?? '',
            initial: (user?.firstName.isNotEmpty ?? false)
                ? user!.firstName[0].toUpperCase()
                : '?',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (showBecomeArtisan) ...[
            const SizedBox(height: AppSpacing.md),
            _BecomeArtisanTile(onTap: () => _onBecomeArtisan(context, ref)),
          ],
          if (showSwitchToArtisan) ...[
            const SizedBox(height: AppSpacing.md),
            _SwitchToArtisanTile(onTap: () => _onSwitchToArtisan(context, ref)),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel(text: 'MY ACTIVITY'),
          const SizedBox(height: AppSpacing.sm),
          _CardGroup(
            children: [
              _RowTile(
                icon: Icons.receipt_long_outlined,
                label: 'Payment history',
                onTap: () => context.push('/customer-home/profile/payments'),
              ),
              const _Divider(),
              _RowTile(
                icon: Icons.favorite_border,
                label: 'Saved artisans',
                onTap: () => _comingSoon(context, 'Saved artisans'),
              ),
              const _Divider(),
              _RowTile(
                icon: Icons.place_outlined,
                label: 'Saved locations',
                onTap: () => _comingSoon(context, 'Saved locations'),
              ),
              const _Divider(),
              _RowTile(
                icon: Icons.star_border,
                label: 'My reviews',
                onTap: () => _comingSoon(context, 'My reviews'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel(text: 'PREFERENCES'),
          const SizedBox(height: AppSpacing.sm),
          _CardGroup(
            children: [
              const _LanguageTile(),
              const _Divider(),
              _RowTile(
                icon: Icons.notifications_none,
                label: 'Notifications',
                onTap: () => _comingSoon(context, 'Notification preferences'),
              ),
              const _Divider(),
              _RowTile(
                icon: Icons.lock_outline,
                label: 'Password and security',
                onTap: () => _comingSoon(context, 'Password and security'),
              ),
              const _Divider(),
              const _StaticRowTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark mode',
                trailingLabel: 'Coming soon',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel(text: 'SUPPORT'),
          const SizedBox(height: AppSpacing.sm),
          _CardGroup(
            children: [
              _RowTile(
                icon: Icons.help_outline,
                label: 'Help center',
                onTap: () => _comingSoon(context, 'Help center'),
              ),
              const _Divider(),
              _RowTile(
                icon: Icons.support_agent,
                label: 'Contact support',
                onTap: () => _comingSoon(context, 'Contact support'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _LogoutTile(
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'ServiceHUB v1.0.0 · Douala, Cameroon',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming in a later batch.')),
    );
  }

  Future<void> _onBecomeArtisan(BuildContext context, WidgetRef ref) async {
    final result = await showBecomeArtisanModal(context);
    if (result == null || !context.mounted) return;

    // The becomeArtisan flow already sets active_role = artisan.
    // Navigate straight to the verification center.
    context.go('/artisan-home/profile/verification');
  }

  Future<void> _onSwitchToArtisan(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authStateProvider.notifier).switchRole('artisan');
      if (!context.mounted) return;
      context.go('/artisan-home');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not switch to artisan: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.initial,
  });

  final String name;
  final String email;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTypography.display.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardLight, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Account active',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 60),
      child: Divider(height: 1, color: AppColors.borderLight),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              _IconBubble(icon: icon),
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

class _StaticRowTile extends StatelessWidget {
  const _StaticRowTile({
    required this.icon,
    required this.label,
    required this.trailingLabel,
  });

  final IconData icon;
  final String label;
  final String trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          _IconBubble(icon: icon),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              trailingLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          const _IconBubble(icon: Icons.language),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Text(
              'Language',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'EN',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  child: Text(
                    'FR',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
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
    );
  }
}

class _BecomeArtisanTile extends StatelessWidget {
  const _BecomeArtisanTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.cardLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.handyman_outlined,
                  size: 22,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Become an artisan',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Offer your services on ServiceHUB',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchToArtisanTile extends StatelessWidget {
  const _SwitchToArtisanTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(borderRadius: AppRadii.borderLg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.swap_horiz,
                  size: 22,
                  color: AppColors.textInverse,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Switch to artisan',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Access your artisan dashboard',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textInverse.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textInverse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
