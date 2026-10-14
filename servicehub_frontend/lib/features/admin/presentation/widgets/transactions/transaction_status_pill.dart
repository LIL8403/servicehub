import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// Status pill used in both Payments and Payouts tables.
///
/// Color mapping covers every status in PaymentStatus and PayoutStatus.
class TransactionStatusPill extends StatelessWidget {
  const TransactionStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _variant();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (Color, Color, String) _variant() {
    const success = (AppColors.successTint, AppColors.success);
    const warning = (Color(0xFFFEF3C7), Color(0xFFB45309));
    const error = (AppColors.errorTint, AppColors.error);
    const info = (Color(0xFFDBEAFE), Color(0xFF1D4ED8));
    const neutral = (Color(0xFFF1F5F9), AppColors.textMuted);

    (Color, Color) c;
    switch (status.toLowerCase()) {
      case 'held':
        c = warning;
        break;
      case 'released':
      case 'paid':
        c = success;
        break;
      case 'failed':
      case 'disputed':
      case 'under_review':
      case 'reconciliation_required':
        c = error;
        break;
      case 'initiated':
      case 'processing':
      case 'releasing':
      case 'refunding':
        c = info;
        break;
      case 'cancelled':
      case 'refunded':
      case 'partially_refunded':
      case 'refund_pending_manual':
      case 'closed':
        c = neutral;
        break;
      default:
        c = neutral;
    }

    return (c.$1, c.$2, _label());
  }

  String _label() {
    switch (status.toLowerCase()) {
      case 'refund_pending_manual':
        return 'Refund pending';
      case 'reconciliation_required':
        return 'Reconciliation';
      case 'partially_refunded':
        return 'Partially refunded';
      default:
        return status
            .split('_')
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }
}