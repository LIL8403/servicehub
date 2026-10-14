import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/enums/service_request_status.dart';
import '../../domain/models/artisan_request_summary.dart';
import 'artisan_status_badge.dart';

class ArtisanRequestCard extends StatelessWidget {
  const ArtisanRequestCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ArtisanRequestSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showAccent = _isActionable(item.status);

    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showAccent)
                  Container(width: 3.5, color: AppColors.secondary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.serviceName,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ArtisanStatusBadge(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${item.customerFirstName} · '
                                '${item.locationLabel}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm + 2),
                        Container(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm + 2,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.borderLight,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (item.urgency != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _urgencyBg(item.urgency!),
                                    borderRadius:
                                        BorderRadius.circular(9999),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    'Urgency · '
                                    '${_capitalize(item.urgency!)}',
                                    style: AppTypography.caption.copyWith(
                                      color: _urgencyFg(item.urgency!),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                'Ref: ${item.shortRef}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isActionable(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pendingArtisanResponse:
      case ServiceRequestStatus.quotationPending:
      case ServiceRequestStatus.quotationReceived:
      case ServiceRequestStatus.awaitingConfirmation:
      case ServiceRequestStatus.paymentPending:
        return true;
      default:
        return false;
    }
  }

  Color _urgencyBg(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return AppColors.warningTint;
      case 'medium':
        return AppColors.cream;
      default:
        return AppColors.cream.withValues(alpha: 0.8);
    }
  }

  Color _urgencyFg(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}