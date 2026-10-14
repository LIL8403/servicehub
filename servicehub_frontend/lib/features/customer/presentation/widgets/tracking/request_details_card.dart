import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_shadows.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_request.dart';


/// The "Request details" section used across all tracking views.
///
/// Renders a two-column grid of Service / Location / Schedule / Submitted.
class RequestDetailsCard extends StatelessWidget {
  const RequestDetailsCard({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final serviceName = request.service?.name ?? '—';
    final locationLabel = request.location?.label ?? '—';
    final scheduleLabel = request.preferredSchedule?.displayLabel ?? '—';
    final submittedLabel = _relativeTime(request.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Request details',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.shadowLow,
          ),
          child: Column(
            children: [
              _row('Service', serviceName),
              const Divider(height: 20),
              _row('Location', locationLabel),
              const Divider(height: 20),
              _row('Schedule', scheduleLabel),
              const Divider(height: 20),
              _row('Submitted', submittedLabel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}