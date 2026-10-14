import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_shadows.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_request.dart';


/// Renders the request's [ServiceRequest.statusHistory] as a vertical
/// timeline. Completed events are shown in the primary navy; the final
/// (current) event is highlighted in ochre.
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final events = request.statusHistory;
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Activity',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < events.length; i++)
                _TimelineRow(
                  event: events[i],
                  isLast: i == events.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final StatusHistoryEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = isLast ? AppColors.secondary : AppColors.primary;
    final dotBg = isLast ? AppColors.cream : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: dotBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eventLabel(event),
                    style: AppTypography.bodyMedium.copyWith(
                      color: accent,
                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (event.occurredAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(event.occurredAt!),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _eventLabel(StatusHistoryEvent e) {
    // Prefer the human-friendly event name if it's known.
    switch (e.event) {
      case 'submitted':
        return 'Request submitted';
      case 'artisan_selected':
        return 'Artisan selected';
      case 'artisan_approved':
        return 'Artisan accepted';
      case 'artisan_declined':
        return 'Artisan declined';
      case 'artisan_timeout':
        return 'Artisan response timed out';
      case 'artisan_changed_by_customer':
        return 'Artisan changed';
      case 'ai_ranked':
        return 'AI recommendations ready';
      case 'ai_ranking_empty':
        return 'AI recommendations unavailable';
      case 'matching_failed':
        return 'No artisans matched';
      case 'retry_succeeded':
        return 'Matching retry succeeded';
      case 'retry_failed':
        return 'Matching retry failed';
      default:
        return e.status.label;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}