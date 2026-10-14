import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/enums/service_request_status.dart';


/// A pill-shaped status badge. Colour depends on whether the request
/// is waiting, in flight, action-required, or done.
class TrackingStatusBadge extends StatelessWidget {
  const TrackingStatusBadge({super.key, required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _colorsFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _colorsFor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.completed:
        return (
          AppColors.successTint,
          AppColors.success,
          'COMPLETED',
        );
      case ServiceRequestStatus.cancelled:
        return (
          AppColors.errorTint,
          AppColors.error,
          'CANCELLED',
        );
      case ServiceRequestStatus.disputed:
        return (
          AppColors.errorTint,
          AppColors.error,
          'DISPUTED',
        );
      case ServiceRequestStatus.awaitingArtisanSelection:
      case ServiceRequestStatus.noArtisanAvailable:
        return (
          AppColors.warningTint,
          AppColors.warning,
          'ACTION NEEDED',
        );
      case ServiceRequestStatus.quotationReceived:
      case ServiceRequestStatus.awaitingConfirmation:
        return (
          AppColors.cream,
          AppColors.secondary,
          status.label.toUpperCase(),
        );
      case ServiceRequestStatus.pendingArtisanResponse:
      case ServiceRequestStatus.booked:
      case ServiceRequestStatus.inProgress:
      case ServiceRequestStatus.inspectionScheduled:
        return (
          AppColors.cream,
          AppColors.secondary,
          status.label.toUpperCase(),
        );
      default:
        return (
          AppColors.neutralBadgeBg,
          AppColors.primary,
          status.label.toUpperCase(),
        );
    }
  }
}