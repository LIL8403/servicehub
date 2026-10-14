import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_verification_providers.dart';

class VerificationStatusCard extends ConsumerWidget {
  const VerificationStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(artisanVerificationProvider);

    return async.when(
      loading: () => _shimmer(),
      error: (_, _) => _card(
        context: context,
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        title: 'Verification status unavailable',
        subtitle: 'Tap to retry',
        trailing: null,
        onTap: () => ref.invalidate(artisanVerificationProvider),
      ),
      data: (snapshot) {
        final status = snapshot.status.status.toLowerCase();

        switch (status) {
          case 'verified':
            return _card(
              context: context,
              icon: Icons.verified_user,
              iconColor: AppColors.success,
              title: 'You are a verified artisan',
              subtitle: 'Your profile is visible to customers',
              trailing: _pill(
                text: 'VERIFIED',
                bg: AppColors.successTint,
                fg: AppColors.success,
              ),
              onTap: () => context.push('/artisan-home/profile/verification'),
            );
          case 'pending':
            return _card(
              context: context,
              icon: Icons.schedule,
              iconColor: AppColors.warning,
              title: 'Verification in review',
              subtitle: 'We are reviewing your submitted documents',
              trailing: _pill(
                text: 'PENDING',
                bg: AppColors.warningTint,
                fg: AppColors.warning,
              ),
              onTap: () => context.push('/artisan-home/profile/verification'),
            );
          case 'rejected':
            return _card(
              context: context,
              icon: Icons.error_outline,
              iconColor: AppColors.error,
              title: 'Verification needs attention',
              subtitle: 'Please review the feedback and resubmit',
              trailing: _pill(
                text: 'ACTION',
                bg: AppColors.errorTint,
                fg: AppColors.error,
              ),
              onTap: () => context.push('/artisan-home/profile/verification'),
            );
          default:
            return _card(
              context: context,
              icon: Icons.lock_outline,
              iconColor: AppColors.secondary,
              title: 'Become a verified artisan',
              subtitle: 'Submit your professional documents to unlock more jobs',
              trailing: _cta(),
              onTap: () => context.push('/artisan-home/profile/verification'),
            );
        }
      },
    );
  }

  Widget _shimmer() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.4),
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _card({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cream.withValues(alpha: 0.75),
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md - 2),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _cta() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Start',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Icon(
          Icons.chevron_right,
          size: 18,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}