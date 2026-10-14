import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class DisputeStatusPill extends StatelessWidget {
  const DisputeStatusPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _variant();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10 : 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (Color, Color, String) _variant() {
    switch (status) {
      case 'opened':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309), 'OPENED');
      case 'under_review':
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'UNDER REVIEW');
      case 'awaiting_information':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309), 'AWAITING INFO');
      case 'under_investigation':
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'INVESTIGATING');
      case 'pending_execution':
        return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C), 'PENDING EXECUTION');
      case 'reconciliation_required':
        return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C), 'RECONCILIATION');
      case 'resolved_with_manual_refund_pending':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309), 'MANUAL REFUND');
      case 'resolved':
        return (AppColors.successTint, AppColors.success, 'RESOLVED');
      case 'closed':
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF64748B), 'CLOSED');
    }
  }
}