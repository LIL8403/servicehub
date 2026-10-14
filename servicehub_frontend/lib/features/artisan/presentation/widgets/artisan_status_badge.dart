import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/enums/service_request_status.dart';

enum ArtisanStatusBadgeSize { small, medium }

/// A colour-coded pill showing the current request status.
/// Reused on the artisan dashboard, request detail, and request list.
class ArtisanStatusBadge extends StatelessWidget {
  const ArtisanStatusBadge({
    super.key,
    required this.status,
    this.size = ArtisanStatusBadgeSize.small,
    this.overrideLabel,
  });

  final ServiceRequestStatus status;
  final ArtisanStatusBadgeSize size;
  final String? overrideLabel;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _colorsFor(status);
    final displayLabel = overrideLabel ?? label;

    final hPadding = size == ArtisanStatusBadgeSize.medium ? 12.0 : 10.0;
    final vPadding = size == ArtisanStatusBadgeSize.medium ? 5.0 : 3.0;
    final fontSize = size == ArtisanStatusBadgeSize.medium ? 11.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: hPadding,
        vertical: vPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        displayLabel,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          fontSize: fontSize,
        ),
      ),
    );
  }

  (Color, Color, String) _colorsFor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pendingArtisanResponse:
        return (AppColors.cream, AppColors.secondary, 'NEW');
      case ServiceRequestStatus.artisanApproved:
        return (AppColors.cream, AppColors.secondary, 'ACCEPTED');
      case ServiceRequestStatus.inspectionScheduled:
        return (AppColors.infoTint, AppColors.info, 'INSPECTION');
      case ServiceRequestStatus.inspectionCompleted:
        return (AppColors.infoTint, AppColors.info, 'INSPECTED');
      case ServiceRequestStatus.quotationReceived:
      case ServiceRequestStatus.quotationPending:
        return (AppColors.cream, AppColors.secondary, 'QUOTED');
      case ServiceRequestStatus.paymentPending:
        return (AppColors.warningTint, AppColors.warning, 'PAYMENT');
      case ServiceRequestStatus.booked:
        return (AppColors.successTint, AppColors.success, 'BOOKED');
      case ServiceRequestStatus.inProgress:
        return (AppColors.successTint, AppColors.success, 'IN PROGRESS');
      case ServiceRequestStatus.awaitingConfirmation:
        return (AppColors.warningTint, AppColors.warning, 'AWAITING');
      case ServiceRequestStatus.completed:
        return (AppColors.successTint, AppColors.success, 'COMPLETED');
      case ServiceRequestStatus.cancelled:
        return (AppColors.errorTint, AppColors.error, 'CANCELLED');
      case ServiceRequestStatus.disputed:
        return (AppColors.errorTint, AppColors.error, 'DISPUTED');
      default:
        return (
          AppColors.neutralBadgeBg,
          AppColors.primary,
          status.label.toUpperCase()
        );
    }
  }
}