import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class ServiceRequestStatusPill extends StatelessWidget {
  const ServiceRequestStatusPill({super.key, required this.status});

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
    switch (status) {
      case 'completed':
        c = success;
        break;
      case 'cancelled':
      case 'disputed':
      case 'no_artisan_available':
        c = error;
        break;
      case 'booked':
      case 'in_progress':
      case 'awaiting_confirmation':
      case 'quotation_accepted':
      case 'payment_pending':
      case 'artisan_selected':
        c = info;
        break;
      case 'pending_artisan_response':
      case 'awaiting_artisan_selection':
      case 'artisan_approved':
      case 'inspection_scheduled':
      case 'inspection_completed':
      case 'quotation_pending':
      case 'quotation_received':
        c = warning;
        break;
      default:
        c = neutral;
    }

    return (c.$1, c.$2, _label());
  }

  String _label() {
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}