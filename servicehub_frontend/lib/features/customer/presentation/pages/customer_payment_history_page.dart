import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/payment_record.dart';
import '../providers/customer_payments_providers.dart';

class CustomerPaymentHistoryPage extends ConsumerWidget {
  const CustomerPaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Payment history',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerPaymentsProvider);
          await ref.read(customerPaymentsProvider.future);
        },
        color: AppColors.primary,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
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
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (payments) {
            if (payments.isEmpty) {
              return const _EmptyView();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: payments.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm + 2),
              itemBuilder: (context, index) =>
                  _PaymentCard(record: payments[index]),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.record});

  final PaymentRecord record;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors(record.status);
    final dateLabel = record.createdAt == null
        ? ''
        : DateFormat.yMMMd().add_jm().format(record.createdAt!);

    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: record.serviceRequestId.isEmpty
            ? null
            : () => context.push(
                  '/customer-home/requests/request/${record.serviceRequestId}',
                ),
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
                children: [
                  Expanded(
                    child: Text(
                      record.serviceName ?? 'Service',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      record.statusLabel.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                record.channelLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (record.artisanFirstName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'To ${record.artisanFirstName}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm + 2),
              Container(
                padding: const EdgeInsets.only(top: AppSpacing.sm + 2),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_money(record.amount)} ${record.currency}',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (record.requestReference != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '#${record.requestReference}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'released':
        return (AppColors.successTint, AppColors.success);
      case 'held':
      case 'releasing':
        return (AppColors.cream, AppColors.secondary);
      case 'refunded':
      case 'partially_refunded':
        return (AppColors.infoTint, AppColors.info);
      case 'failed':
      case 'cancelled':
        return (AppColors.errorTint, AppColors.error);
      case 'disputed':
      case 'under_review':
        return (AppColors.warningTint, AppColors.warning);
      default:
        return (AppColors.neutralBadgeBg, AppColors.primary);
    }
  }

  String _money(double amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buf.write(',');
      buf.write(rounded[i]);
    }
    return buf.toString();
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
              'No payments yet',
              style: AppTypography.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'When you pay for a service, the transaction will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}