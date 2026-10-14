import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_profile_providers.dart';

/// Shows a warning at the top of the artisan home when the payout
/// phone is not configured. Silent when it is configured.
///
/// Rationale: without a payout phone, `reportCompletion` is blocked
/// by the backend. The artisan should learn this before they reach
/// the end of a job, not when they try to close it.
class PayoutPhoneWarningCard extends ConsumerWidget {
  const PayoutPhoneWarningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(artisanProfileProvider);

    return profileAsync.maybeWhen(
      data: (profile) {
        // The backend hides `payout_phone` (it's PII) and exposes
        // `payout_phone_configured` as a boolean instead.
        final configured = profile['payout_phone_configured'] == true;
        if (configured) return const SizedBox.shrink();

        return Material(
          color: AppColors.warningTint.withValues(alpha: 0.5),
          borderRadius: AppRadii.borderLg,
          child: InkWell(
            borderRadius: AppRadii.borderLg,
            onTap: () => context.push('/artisan-home/profile/edit'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: AppRadii.borderLg,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set your payout phone',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You need it before you can complete a job.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
