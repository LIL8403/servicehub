import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/enums/service_request_status.dart';
import '../providers/my_requests_providers.dart';
import '../widgets/request_status_chip.dart';

enum _RequestFilter { all, active, upcoming, completed, cancelled, disputed }

class CustomerRequestsTab extends ConsumerStatefulWidget {
  const CustomerRequestsTab({super.key});

  @override
  ConsumerState<CustomerRequestsTab> createState() =>
      _CustomerRequestsTabState();
}

class _CustomerRequestsTabState extends ConsumerState<CustomerRequestsTab> {
  _RequestFilter _filter = _RequestFilter.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My requests',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Advanced filters coming later.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterStrip(
            current: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myRequestsProvider);
                await ref.read(myRequestsProvider.future);
              },
              color: AppColors.primary,
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(myRequestsProvider),
                ),
                data: (all) {
                  final filtered = all.where(_matches).toList();
                  if (filtered.isEmpty) {
                    return _EmptyView(
                      filter: _filter,
                      onBook: () => context.go('/service-categories'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm + 2),
                    itemBuilder: (context, index) =>
                        _RequestCard(item: filtered[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(RequestListItem item) {
    switch (_filter) {
      case _RequestFilter.all:
        return true;
      case _RequestFilter.active:
        return item.status != ServiceRequestStatus.completed &&
            item.status != ServiceRequestStatus.cancelled;
      case _RequestFilter.upcoming:
        return item.status == ServiceRequestStatus.booked ||
            item.status == ServiceRequestStatus.inProgress;
      case _RequestFilter.completed:
        return item.status == ServiceRequestStatus.completed;
      case _RequestFilter.cancelled:
        return item.status == ServiceRequestStatus.cancelled;
      case _RequestFilter.disputed:
        return item.status == ServiceRequestStatus.disputed;
    }
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.current, required this.onChanged});

  final _RequestFilter current;
  final ValueChanged<_RequestFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgLight,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm + 2,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'All',
              active: current == _RequestFilter.all,
              onTap: () => onChanged(_RequestFilter.all),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Active',
              active: current == _RequestFilter.active,
              onTap: () => onChanged(_RequestFilter.active),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Upcoming',
              active: current == _RequestFilter.upcoming,
              onTap: () => onChanged(_RequestFilter.upcoming),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Completed',
              active: current == _RequestFilter.completed,
              onTap: () => onChanged(_RequestFilter.completed),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Cancelled',
              active: current == _RequestFilter.cancelled,
              onTap: () => onChanged(_RequestFilter.cancelled),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Disputed',
              active: current == _RequestFilter.disputed,
              onTap: () => onChanged(_RequestFilter.disputed),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: active ? AppColors.textInverse : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});

  final RequestListItem item;

  @override
  Widget build(BuildContext context) {
    final showAccent = _shouldShowAccent(item.status);

    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: () => context.push('/customer-home/requests/request/${item.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showAccent)
                  Container(width: 3, color: AppColors.secondary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.serviceName,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            RequestStatusChip(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.borderLight),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Ref: ${item.shortRef}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowAccent(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.awaitingArtisanSelection:
      case ServiceRequestStatus.noArtisanAvailable:
      case ServiceRequestStatus.quotationReceived:
      case ServiceRequestStatus.paymentPending:
      case ServiceRequestStatus.awaitingConfirmation:
        return true;
      default:
        return false;
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filter, required this.onBook});

  final _RequestFilter filter;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      _RequestFilter.all => 'No requests yet',
      _RequestFilter.active => 'No active requests',
      _RequestFilter.upcoming => 'Nothing upcoming',
      _RequestFilter.completed => 'No completed requests',
      _RequestFilter.cancelled => 'No cancelled requests',
      _RequestFilter.disputed => 'No disputes',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: AppTypography.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'When you book a service, it will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Book a service'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                shape: const StadiumBorder(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}