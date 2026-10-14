import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_payout_repository.dart';
import 'copyable_reference_field.dart';
import 'event_timeline.dart';
import 'transaction_status_pill.dart';

Future<void> showPayoutDetailDialog(
  BuildContext context, {
  required AdminPayout payout,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.5),
    useRootNavigator: false,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.cardLight,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 700,
        ),
        child: _PayoutDetailBody(payout: payout),
      ),
    ),
  );
}

class _PayoutDetailBody extends StatelessWidget {
  const _PayoutDetailBody({required this.payout});

  final AdminPayout payout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borderLight,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _referenceBlock(),
                const SizedBox(height: 24),
                _sectionLabel('FINANCIAL BREAKDOWN'),
                const SizedBox(height: 8),
                _breakdown(),
                const SizedBox(height: 24),
                _sectionLabel('TRANSACTION INFO'),
                const SizedBox(height: 8),
                _metadata(),
                const SizedBox(height: 24),
                _sectionLabel('EVENT TIMELINE'),
                const SizedBox(height: 12),
                EventTimeline(events: payout.events),
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borderLight,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderLight),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 22,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payout details',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: CopyableReferenceField(
                  label: 'External reference',
                  value: payout.externalReference,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CopyableReferenceField(
                  label: 'Provider reference',
                  value: payout.providerReference,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TransactionStatusPill(status: payout.status),
          ),
        ],
      ),
    );
  }

  Widget _breakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _kv(
            'Artisan gross',
            payout.grossAmount != null ? _formatXaf(payout.grossAmount!) : '—',
          ),
          const SizedBox(height: 10),
          _kv(
            'Platform commission',
            payout.commissionAmount != null
                ? '- ${_formatXaf(payout.commissionAmount!)}'
                : '—',
            valueColor: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          _kv(
            'Net payout',
            _formatXaf(payout.amount),
            bold: true,
            large: true,
          ),
        ],
      ),
    );
  }

  Widget _metadata() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _metaRow('Payout ID', payout.id),
          _metaRow('Payment ID', payout.paymentId),
          _metaRow('Artisan profile', payout.artisanProfileId),
          _metaRow('Artisan', payout.artisanName ?? '—'),
          _metaRow('Service request', payout.serviceRequestId),
          _metaRow('Provider', payout.provider ?? '—'),
          _metaRow('Currency', payout.currency),
          _metaRow('Created at', _formatDateTime(payout.createdAt)),
          _metaRow('Last updated', _formatDateTime(payout.updatedAt),
              isLast: true),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(
    String label,
    String value, {
    bool bold = false,
    bool large = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: valueColor ?? AppColors.primary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: large ? 16 : 13,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 0.6,
      ),
    );
  }

  String _formatXaf(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${months[local.month - 1]}-$day $h:$m';
  }
}