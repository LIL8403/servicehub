import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/enums/service_request_status.dart';

/// A compact 5-segment progress bar for the "current request" card.
///
/// The 5 segments represent the coarse lifecycle groups:
///   1. Matching (awaiting selection / no artisan)
///   2. Awaiting artisan response
///   3. Quotation
///   4. Payment / booking
///   5. Execution
class RequestProgressStepper extends StatelessWidget {
  const RequestProgressStepper({super.key, required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (step, total, label) = _stageFor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(total, (i) {
            final isCompleted = i < step - 1;
            final isActive = i == step - 1;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : isActive
                            ? AppColors.secondary
                            : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $step of $total',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  (int, int, String) _stageFor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.created:
      case ServiceRequestStatus.awaitingArtisanSelection:
      case ServiceRequestStatus.noArtisanAvailable:
        return (1, 5, 'Choose an artisan');

      case ServiceRequestStatus.pendingArtisanResponse:
        return (2, 5, 'Awaiting response');

      case ServiceRequestStatus.artisanApproved:
      case ServiceRequestStatus.artisanSelected:
      case ServiceRequestStatus.inspectionScheduled:
      case ServiceRequestStatus.inspectionCompleted:
      case ServiceRequestStatus.quotationPending:
      case ServiceRequestStatus.quotationReceived:
        return (3, 5, 'Quotation stage');

      case ServiceRequestStatus.quotationAccepted:
      case ServiceRequestStatus.paymentPending:
      case ServiceRequestStatus.booked:
        return (4, 5, 'Payment & booking');

      case ServiceRequestStatus.inProgress:
      case ServiceRequestStatus.awaitingConfirmation:
        return (5, 5, 'In progress');

      case ServiceRequestStatus.completed:
        return (5, 5, 'Completed');

      case ServiceRequestStatus.cancelled:
        return (1, 5, 'Cancelled');

      case ServiceRequestStatus.disputed:
        return (3, 5, 'Disputed');
      
      case ServiceRequestStatus.unknown:
        return (1, 5, 'Processing');
    }
  }
}