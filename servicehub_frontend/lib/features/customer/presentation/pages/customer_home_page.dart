import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/enums/service_request_status.dart';
import '../providers/my_requests_providers.dart';

class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'ServiceHUB',
          style: AppTypography.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/artisan-home'),
        child: const Icon(Icons.engineering),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myRequestsProvider);
            await ref.read(myRequestsProvider.future);
          },
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Primary CTA — start a new request
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/service-categories'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Book a Service',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.add,
                        size: 20,
                        color: AppColors.textInverse,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Section heading
              Text(
                'My requests',
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Requests list
              _MyRequestsSection(ref: ref),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRequestsSection extends StatelessWidget {
  const _MyRequestsSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myRequestsProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => _ErrorCard(
        message: err is Exception ? err.toString() : 'Failed to load requests.',
        onRetry: () => ref.invalidate(myRequestsProvider),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const _EmptyCard();
        }
        return Column(
          children: [
            for (var i = 0; i < requests.length; i++) ...[
              _RequestRow(item: requests[i]),
              if (i < requests.length - 1)
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.item});

  final RequestListItem item;

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg, badgeText) = _badgeFor(item.status);

    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: () => context.push('/service-request/${item.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.serviceName,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.locationLabel,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTypography.caption.copyWith(
                        color: badgeFg,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ref: ${item.shortRef}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, String) _badgeFor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.completed:
        return (AppColors.successTint, AppColors.success, 'COMPLETED');
      case ServiceRequestStatus.cancelled:
        return (AppColors.errorTint, AppColors.error, 'CANCELLED');
      case ServiceRequestStatus.disputed:
        return (AppColors.errorTint, AppColors.error, 'DISPUTED');
      case ServiceRequestStatus.awaitingArtisanSelection:
      case ServiceRequestStatus.noArtisanAvailable:
        return (AppColors.warningTint, AppColors.warning, 'ACTION NEEDED');
      case ServiceRequestStatus.pendingArtisanResponse:
      case ServiceRequestStatus.artisanApproved:
      case ServiceRequestStatus.booked:
      case ServiceRequestStatus.inProgress:
        return (AppColors.cream, AppColors.secondary, 'IN PROGRESS');
      case ServiceRequestStatus.quotationReceived:
      case ServiceRequestStatus.awaitingConfirmation:
        return (AppColors.cream, AppColors.secondary, 'ACTION NEEDED');
      default:
        return (AppColors.neutralBadgeBg, AppColors.primary,
            status.label.toUpperCase());
    }
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

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
          const Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No requests yet',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Book a Service" above to get started.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
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
          const Icon(
            Icons.error_outline,
            size: 32,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
            ),
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

