import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_service_request_repository.dart';
import '../providers/admin_service_request_providers.dart';
import '../widgets/transactions/transaction_pagination_bar.dart';
import '../widgets/requests/service_request_detail_dialog.dart';
import '../widgets/requests/service_request_status_pill.dart';

class AdminServiceRequestsPage extends ConsumerWidget {
  const AdminServiceRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminServiceRequestsPageProvider);
    final page = async.valueOrNull;
    final isLoadingFirstTime = async.isLoading && page == null;
    final hasError = async.hasError && page == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _pageHeader(),
          const SizedBox(height: 24),
          if (isLoadingFirstTime)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 120),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasError)
            _ErrorView(
              message: async.error.toString(),
              onRetry: () =>
                  ref.invalidate(adminServiceRequestsPageProvider),
            )
          else if (page != null) ...[
            _filterBar(ref, page),
            const SizedBox(height: 24),
            _tableCard(context, ref, page),
          ],
        ],
      ),
    );
  }

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Requests',
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Every request across the platform. Read-only view.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _filterBar(WidgetRef ref, AdminServiceRequestsResponse page) {
    final filter = ref.watch(adminServiceRequestsFilterProvider);

    return Row(
      children: [
        _statusFilter(ref, filter),
        const SizedBox(width: 16),
        const Spacer(),
        Text(
          '${page.meta.total} request${page.meta.total == 1 ? '' : 's'}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _statusFilter(WidgetRef ref, AdminServiceRequestsFilter filter) {
    const options = <({String? value, String label})>[
      (value: null, label: 'All statuses'),
      (value: 'created', label: 'Created'),
      (value: 'awaiting_artisan_selection', label: 'Awaiting artisan selection'),
      (value: 'pending_artisan_response', label: 'Pending artisan response'),
      (value: 'artisan_approved', label: 'Artisan approved'),
      (value: 'artisan_selected', label: 'Artisan selected'),
      (value: 'no_artisan_available', label: 'No artisan available'),
      (value: 'inspection_scheduled', label: 'Inspection scheduled'),
      (value: 'inspection_completed', label: 'Inspection completed'),
      (value: 'quotation_pending', label: 'Quotation pending'),
      (value: 'quotation_received', label: 'Quotation received'),
      (value: 'quotation_accepted', label: 'Quotation accepted'),
      (value: 'payment_pending', label: 'Payment pending'),
      (value: 'booked', label: 'Booked'),
      (value: 'in_progress', label: 'In progress'),
      (value: 'awaiting_confirmation', label: 'Awaiting confirmation'),
      (value: 'completed', label: 'Completed'),
      (value: 'cancelled', label: 'Cancelled'),
      (value: 'disputed', label: 'Disputed'),
    ];
    final current = options.firstWhere(
      (o) => o.value == filter.status,
      orElse: () => options.first,
    );

    return PopupMenuButton<String>(
      tooltip: '',
      color: AppColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      offset: const Offset(0, 48),
      onSelected: (value) {
        ref.read(adminServiceRequestsFilterProvider.notifier).state =
            filter.copyWith(
          status: value == '__all__' ? null : value,
          clearStatus: value == '__all__',
          page: 1,
        );
      },
      itemBuilder: (ctx) => [
        for (final o in options)
          PopupMenuItem<String>(
            value: o.value ?? '__all__',
            height: 40,
            child: Text(
              o.label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: o.value == filter.status
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
      ],
      child: Container(
        width: 240,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                current.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: filter.status == null
                      ? AppColors.textMuted
                      : AppColors.primary,
                  fontWeight: filter.status == null
                      ? FontWeight.w500
                      : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCard(
    BuildContext context,
    WidgetRef ref,
    AdminServiceRequestsResponse page,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: page.requests.isEmpty
          ? _emptyState()
          : Column(
              children: [
                _headerRow(),
                for (var i = 0; i < page.requests.length; i++) ...[
                  _dataRow(context, page.requests[i]),
                  if (i < page.requests.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderLight,
                    ),
                ],
                TransactionPaginationBar(
                  total: page.meta.total,
                  from: page.meta.from,
                  to: page.meta.to,
                  currentPage: page.meta.currentPage,
                  lastPage: page.meta.lastPage,
                  itemLabel: 'requests',
                  onPrevious: () {
                    final f =
                        ref.read(adminServiceRequestsFilterProvider);
                    if (f.page > 1) {
                      ref
                          .read(adminServiceRequestsFilterProvider.notifier)
                          .state = f.copyWith(page: f.page - 1);
                    }
                  },
                  onNext: () {
                    final f =
                        ref.read(adminServiceRequestsFilterProvider);
                    if (f.page < page.meta.lastPage) {
                      ref
                          .read(adminServiceRequestsFilterProvider.notifier)
                          .state = f.copyWith(page: f.page + 1);
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _headerRow() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _header('REQUEST')),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _header('CUSTOMER')),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _header('SERVICE')),
          const SizedBox(width: 16),
          SizedBox(width: 200, child: _header('STATUS')),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerRight,
              child: _header('CREATED'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String label) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _dataRow(BuildContext context, AdminServiceRequest request) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            showServiceRequestDetailDialog(context, request: request),
        hoverColor: AppColors.bgLight,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'REQ #${request.shortId}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.cream,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        request.customerInitials,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.customerName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  request.serviceName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ServiceRequestStatusPill(status: request.status),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _relativeTime(request.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No requests match your filters',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inMinutes} min ago';
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
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
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
                foregroundColor: Colors.white,
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