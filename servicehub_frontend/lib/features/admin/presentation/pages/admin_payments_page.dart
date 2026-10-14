import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_payment_repository.dart';
import '../providers/admin_payment_providers.dart';
import '../widgets/transactions/payment_detail_dialog.dart';
import '../widgets/transactions/transaction_pagination_bar.dart';
import '../widgets/transactions/transaction_reference_cell.dart';
import '../widgets/transactions/transaction_status_pill.dart';

class AdminPaymentsPage extends ConsumerWidget {
  const AdminPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPaymentsPageProvider);
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
              onRetry: () => ref.invalidate(adminPaymentsPageProvider),
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
          'Payments',
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Escrow transactions from customers. Read-only view.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _filterBar(WidgetRef ref, AdminPaymentsResponse page) {
    final filter = ref.watch(adminPaymentsFilterProvider);

    return Row(
      children: [
        _statusFilter(ref, filter),
        const SizedBox(width: 16),
        _providerFilter(ref, filter),
        const Spacer(),
        Text(
          '${page.meta.total} payment${page.meta.total == 1 ? '' : 's'}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _statusFilter(WidgetRef ref, AdminPaymentsFilter filter) {
    const options = <({String? value, String label})>[
      (value: null, label: 'All statuses'),
      (value: 'held', label: 'Held'),
      (value: 'released', label: 'Released'),
      (value: 'failed', label: 'Failed'),
      (value: 'refunded', label: 'Refunded'),
      (value: 'refunding', label: 'Refunding'),
      (value: 'partially_refunded', label: 'Partially refunded'),
      (value: 'cancelled', label: 'Cancelled'),
      (value: 'reconciliation_required', label: 'Reconciliation'),
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
        ref.read(adminPaymentsFilterProvider.notifier).state =
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
      child: _filterShell(
        width: 200,
        child: Text(
          current.label,
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
    );
  }

  Widget _providerFilter(WidgetRef ref, AdminPaymentsFilter filter) {
    const options = <({String? value, String label})>[
      (value: null, label: 'All providers'),
      (value: 'campay', label: 'CamPay'),
      (value: 'campay_simulated', label: 'Simulated'),
    ];
    final current = options.firstWhere(
      (o) => o.value == filter.provider,
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
        ref.read(adminPaymentsFilterProvider.notifier).state =
            filter.copyWith(
          provider: value == '__all__' ? null : value,
          clearProvider: value == '__all__',
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
                fontWeight: o.value == filter.provider
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
      ],
      child: _filterShell(
        width: 180,
        child: Text(
          current.label,
          style: AppTypography.bodySmall.copyWith(
            color: filter.provider == null
                ? AppColors.textMuted
                : AppColors.primary,
            fontWeight: filter.provider == null
                ? FontWeight.w500
                : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _filterShell({
    required double width,
    required Widget child,
  }) {
    return Container(
      width: width,
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
          const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _tableCard(
    BuildContext context,
    WidgetRef ref,
    AdminPaymentsResponse page,
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
      child: page.payments.isEmpty
          ? _emptyState()
          : Column(
              children: [
                _headerRow(),
                for (var i = 0; i < page.payments.length; i++) ...[
                  _dataRow(context, page.payments[i]),
                  if (i < page.payments.length - 1)
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
                  itemLabel: 'payments',
                  onPrevious: () {
                    final f = ref.read(adminPaymentsFilterProvider);
                    if (f.page > 1) {
                      ref.read(adminPaymentsFilterProvider.notifier).state =
                          f.copyWith(page: f.page - 1);
                    }
                  },
                  onNext: () {
                    final f = ref.read(adminPaymentsFilterProvider);
                    if (f.page < page.meta.lastPage) {
                      ref.read(adminPaymentsFilterProvider.notifier).state =
                          f.copyWith(page: f.page + 1);
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
          Expanded(flex: 4, child: _header('REFERENCE')),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _header('CUSTOMER')),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerRight,
              child: _header('AMOUNT'),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerRight,
              child: _header('COMMISSION'),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 160, child: _header('STATUS')),
          const SizedBox(width: 16),
          SizedBox(width: 140, child: _header('CREATED')),
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

  Widget _dataRow(BuildContext context, AdminPayment payment) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showPaymentDetailDialog(context, payment: payment),
        hoverColor: AppColors.bgLight,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: TransactionReferenceCell(
                  externalReference: payment.externalReference,
                  shortId: payment.shortId,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  payment.customerName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatXaf(payment.amount),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    payment.commissionAmount != null
                        ? _formatXaf(payment.commissionAmount!)
                        : '—',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TransactionStatusPill(status: payment.status),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: Text(
                  _relativeTime(payment.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No payments match your filters',
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

  String _formatXaf(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';

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