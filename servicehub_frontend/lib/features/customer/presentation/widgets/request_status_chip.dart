import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/enums/service_request_status.dart';

/// A compact status pill shown on the customer home and request list.
class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _colorsFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          fontSize: 10,
        ),
      ),
    );
  }

  (Color, Color, String) _colorsFor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.completed:
        return (AppColors.successTint, AppColors.success, 'COMPLETED');
      case ServiceRequestStatus.cancelled:
        return (AppColors.errorTint, AppColors.error, 'CANCELLED');
      case ServiceRequestStatus.disputed:
        return (AppColors.errorTint, AppColors.error, 'DISPUTED');
      case ServiceRequestStatus.awaitingArtisanSelection:
      case ServiceRequestStatus.noArtisanAvailable:
        return (AppColors.warningTint, AppColors.warning, 'ACTION NEEDED');
      case ServiceRequestStatus.pendingArtisanResponse:
        return (AppColors.cream, AppColors.secondary, 'WAITING');
      case ServiceRequestStatus.artisanApproved:
      case ServiceRequestStatus.artisanSelected:
        return (AppColors.cream, AppColors.secondary, 'ARTISAN ACCEPTED');
      case ServiceRequestStatus.inspectionScheduled:
        return (AppColors.infoTint, AppColors.info, 'INSPECTION');
      case ServiceRequestStatus.inspectionCompleted:
        return (AppColors.infoTint, AppColors.info, 'INSPECTED');
      case ServiceRequestStatus.quotationPending:
      case ServiceRequestStatus.quotationReceived:
      case ServiceRequestStatus.awaitingConfirmation:
        return (AppColors.warningTint, AppColors.warning, 'ACTION NEEDED');
      case ServiceRequestStatus.quotationAccepted:
      case ServiceRequestStatus.paymentPending:
        return (AppColors.warningTint, AppColors.warning, 'PAYMENT DUE');
      case ServiceRequestStatus.booked:
        return (AppColors.successTint, AppColors.success, 'BOOKED');
      case ServiceRequestStatus.inProgress:
        return (AppColors.successTint, AppColors.success, 'IN PROGRESS');
      case ServiceRequestStatus.created:
        return (AppColors.neutralBadgeBg, AppColors.primary, 'CREATED');
      case ServiceRequestStatus.unknown:
        return (AppColors.neutralBadgeBg, AppColors.primary, 'PROCESSING');
    }
  }
}
