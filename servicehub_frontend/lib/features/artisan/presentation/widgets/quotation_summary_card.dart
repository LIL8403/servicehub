import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/models/service_request.dart';

/// A read-only view of the artisan's own submitted quotation.
/// Shown on the detail page once the artisan has sent one.
class QuotationSummaryCard extends StatelessWidget {
  const QuotationSummaryCard({super.key, required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 12,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'YOUR QUOTATION',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (quotation.validUntil != null)
                Text(
                  'Valid until ${_dateLabel(quotation.validUntil!)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (quotation.scope != null && quotation.scope!.isNotEmpty) ...[
            Text(
              'SCOPE OF WORK',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              quotation.scope!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _lineItem('Labour', quotation.labourTotal),
          const SizedBox(height: AppSpacing.sm),
          _lineItem('Materials', quotation.materialsTotal),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_money(quotation.grandTotal)} XAF',
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (quotation.status != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  _statusIcon(quotation.status!),
                  size: 14,
                  color: _statusColor(quotation.status!),
                ),
                const SizedBox(width: 4),
                Text(
                  _statusLabel(quotation.status!),
                  style: AppTypography.caption.copyWith(
                    color: _statusColor(quotation.status!),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineItem(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${_money(amount)} XAF',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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

  String _dateLabel(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.secondary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Customer accepted';
      case 'rejected':
        return 'Customer rejected';
      default:
        return 'Awaiting customer response';
    }
  }
}