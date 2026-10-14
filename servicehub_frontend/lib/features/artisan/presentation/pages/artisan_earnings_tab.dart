import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_earnings_providers.dart';
import '../widgets/earnings/earnings_balance_card.dart';
import '../widgets/earnings/payout_history_tile.dart';

class ArtisanEarningsTab extends ConsumerWidget {
  const ArtisanEarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(earningsSummaryProvider);
    final history = ref.watch(payoutHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Earnings',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(earningsSummaryProvider);
          await ref.read(payoutHistoryProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            summaryAsync.when(
              loading: () => _LoadingCard(height: 180),
              error: (err, _) => _ErrorCard(
                message: err.toString(),
                onRetry: () => ref.invalidate(earningsSummaryProvider),
              ),
              data: (summary) => EarningsBalanceCard(summary: summary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Payout phone warning — surfaced here too
            summaryAsync.maybeWhen(
              data: (s) => s.payoutPhoneConfigured
                  ? const SizedBox.shrink()
                  : _PayoutPhoneCallout(
                      onTap: () => context.push('/artisan-home/profile/edit'),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),

            Text(
              'Payout history',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (history.error != null && history.payouts.isEmpty)
              _ErrorCard(
                message: history.error!,
                onRetry: () =>
                    ref.read(payoutHistoryProvider.notifier).refresh(),
              )
            else if (history.payouts.isEmpty)
              const _EmptyState()
            else
              Column(
                children: [
                  for (final payout in history.payouts) ...[
                    PayoutHistoryTile(payout: payout),
                    const SizedBox(height: AppSpacing.sm + 2),
                  ],
                  if (history.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: history.isLoadingMore
                              ? null
                              : () => ref
                                    .read(payoutHistoryProvider.notifier)
                                    .loadMore(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: history.isLoadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Load more'),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: AppRadii.borderLg,
      ),
    );
  }
}

class _PayoutPhoneCallout extends StatelessWidget {
  const _PayoutPhoneCallout({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningTint.withValues(alpha: 0.5),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.borderLg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Set your payout phone to receive earnings.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No payouts yet',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'When a job completes and the customer confirms, your '
            'payout appears here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: const StadiumBorder(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
