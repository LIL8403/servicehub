import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/enums/service_request_status.dart';
import '../providers/artisan_request_providers.dart';
import '../widgets/artisan_request_card.dart';

enum _Filter { all, pending, active, completed }

class ArtisanRequestsTab extends ConsumerStatefulWidget {
  const ArtisanRequestsTab({super.key});

  @override
  ConsumerState<ArtisanRequestsTab> createState() =>
      _ArtisanRequestsTabState();
}

class _ArtisanRequestsTabState extends ConsumerState<ArtisanRequestsTab> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artisanRequestsProvider);

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
                ref.invalidate(artisanRequestsProvider);
                await ref.read(artisanRequestsProvider.future);
              },
              color: AppColors.primary,
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                data: (all) {
                  final filtered = all.where(_matches).toList();
                  if (filtered.isEmpty) {
                    return const _EmptyView();
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
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ArtisanRequestCard(
                        item: item,
                        onTap: () => context.push(
                          '/artisan-home/requests/request/${item.id}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(dynamic item) {
    final status = item.status as ServiceRequestStatus;
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.pending:
        return status == ServiceRequestStatus.pendingArtisanResponse;
      case _Filter.active:
        return status == ServiceRequestStatus.artisanApproved ||
            status == ServiceRequestStatus.booked ||
            status == ServiceRequestStatus.inProgress ||
            status == ServiceRequestStatus.paymentPending ||
            status == ServiceRequestStatus.awaitingConfirmation ||
            status == ServiceRequestStatus.inspectionScheduled ||
            status == ServiceRequestStatus.inspectionCompleted;
      case _Filter.completed:
        return status == ServiceRequestStatus.completed;
    }
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.current, required this.onChanged});

  final _Filter current;
  final ValueChanged<_Filter> onChanged;

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
              active: current == _Filter.all,
              onTap: () => onChanged(_Filter.all),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Pending',
              active: current == _Filter.pending,
              onTap: () => onChanged(_Filter.pending),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Active',
              active: current == _Filter.active,
              onTap: () => onChanged(_Filter.active),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Completed',
              active: current == _Filter.completed,
              onTap: () => onChanged(_Filter.completed),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
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
              'No requests in this filter',
              style: AppTypography.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try a different filter.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}