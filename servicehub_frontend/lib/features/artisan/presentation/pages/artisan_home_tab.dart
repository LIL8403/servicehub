import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../customer/domain/enums/service_request_status.dart';
import '../providers/artisan_request_providers.dart';
import '../widgets/artisan_request_card.dart';
import '../widgets/earnings_summary_card.dart';
import '../widgets/payout_phone_warning_card.dart';

class ArtisanHomeTab extends ConsumerWidget {
  const ArtisanHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final async = ref.watch(artisanRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(artisanRequestsProvider);
            await ref.read(artisanRequestsProvider.future);
          },
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _Greeting(firstName: user?.firstName ?? 'artisan'),
              const SizedBox(height: AppSpacing.md),
              const PayoutPhoneWarningCard(),
              const SizedBox(height: AppSpacing.md),
              const EarningsSummaryCard(),
              const SizedBox(height: AppSpacing.lg),
              async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => _ErrorCard(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(artisanRequestsProvider),
                ),
                data: (requests) {
                  if (requests.isEmpty) {
                    return const _EmptyState();
                  }

                  final awaiting = requests
                      .where(
                        (r) =>
                            r.status ==
                            ServiceRequestStatus.pendingArtisanResponse,
                      )
                      .toList();
                  final inProgress = requests
                      .where(
                        (r) =>
                            r.status == ServiceRequestStatus.paymentPending ||
                            r.status == ServiceRequestStatus.booked ||
                            r.status == ServiceRequestStatus.inProgress,
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (awaiting.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Awaiting your response',
                          count: awaiting.length,
                          onSeeAll: () => context.go('/artisan-home/requests'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < awaiting.length; i++) ...[
                          ArtisanRequestCard(
                            item: awaiting[i],
                            onTap: () => context.push(
                              '/artisan-home/requests/request/${awaiting[i].id}',
                            ),
                          ),
                          if (i < awaiting.length - 1)
                            const SizedBox(height: AppSpacing.sm + 2),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (inProgress.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'In progress',
                          count: inProgress.length,
                          onSeeAll: () => context.go('/artisan-home/requests'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < inProgress.length; i++) ...[
                          ArtisanRequestCard(
                            item: inProgress[i],
                            onTap: () => context.push(
                              '/artisan-home/requests/request/${inProgress[i].id}',
                            ),
                          ),
                          if (i < inProgress.length - 1)
                            const SizedBox(height: AppSpacing.sm + 2),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      const _SectionTitle(title: 'Quick actions'),
                      const SizedBox(height: AppSpacing.sm),
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.sm + AppSpacing.xs,
                        crossAxisSpacing: AppSpacing.sm + AppSpacing.xs,
                        childAspectRatio: 1.35,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _QuickTile(
                            icon: Icons.schedule,
                            label: 'Availability',
                            onTap: () =>
                                _comingSoon(context, 'Availability manager'),
                          ),
                          _QuickTile(
                            icon: Icons.star_outline,
                            label: 'My reviews',
                            onTap: () => _comingSoon(context, 'My reviews'),
                          ),
                          _QuickTile(
                            icon: Icons.payments_outlined,
                            label: 'Earnings',
                            onTap: () => context.go('/artisan-home/earnings'),
                          ),
                          _QuickTile(
                            icon: Icons.badge_outlined,
                            label: 'Verification',
                            onTap: () => context.push(
                              '/artisan-home/profile/verification',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming in a later batch.')),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _prefix(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                firstName,
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.secondary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _prefix() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onSeeAll,
  });

  final String title;
  final int count;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
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
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderLg,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
            Icons.inbox_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No jobs yet',
            style: AppTypography.h3.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'When a customer picks you, their request will appear here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
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
