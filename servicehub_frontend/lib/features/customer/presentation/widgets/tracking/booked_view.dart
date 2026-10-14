import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_request.dart';
import 'info_callout_card.dart';
import 'request_details_card.dart';
import 'request_glance_card.dart';
import 'status_hero_card.dart';
import 'tracking_app_bar.dart';
import 'tracking_timeline.dart';
import 'tracking_actions.dart';

/// The view shown once the customer has paid and the booking is
/// confirmed. Maps to mockup #7 ("Booking confirmed").
///
/// Note on schedule: as of this batch, the backend does not store a
/// confirmed appointment slot when transitioning to `booked`. We render
/// whatever is in `preferred_schedule` and fall back to a friendly
/// placeholder. When the backend begins writing a confirmed slot, this
/// view will display it without further changes.
class BookedView extends StatelessWidget {
  const BookedView({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final artisanName = request.selectedArtisan?.firstName ?? 'the artisan';

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          TrackingAppBar(
            onBack: () => context.pop(),
            onHelp: () {},
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RequestGlanceCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  StatusHeroCard(
                    icon: Icons.event_available,
                    tone: StatusHeroTone.success,
                    title: 'Booking confirmed',
                    body:
                        '$artisanName has been notified. You can coordinate '
                        'the exact arrival time via chat.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (request.selectedArtisan != null) ...[
                    _ArtisanCard(request: request),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _ScheduleCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  RequestDetailsCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  TrackingTimeline(request: request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'What happens next?',
                    body:
                        'Funds are held safely in escrow. When $artisanName '
                        'finishes the job, they will mark it complete and '
                        'request your confirmation.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            artisanName: artisanName,
            // Was: onChat: () {}, onReport: () {}
            onChat: () => TrackingActions.openConversation(context, request),
            onReport: () => TrackingActions.openDispute(context, request),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final schedule = request.preferredSchedule;
    final hasConfirmedDate =
        schedule?.date != null && schedule!.date!.isNotEmpty;

    final headline = hasConfirmedDate
        ? schedule.date!
        : 'Awaiting confirmed slot';
    final subline = hasConfirmedDate
        ? (schedule.window ?? '')
        : '${request.selectedArtisan?.firstName ?? "The artisan"} will '
              'confirm a specific time with you via chat.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.45),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 22,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCHEDULED',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subline,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtisanCard extends StatelessWidget {
  const _ArtisanCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final artisan = request.selectedArtisan!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              artisan.firstName.isNotEmpty
                  ? artisan.firstName[0].toUpperCase()
                  : '?',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artisan.name,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  artisan.professionalTitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.artisanName,
    required this.onChat,
    required this.onReport,
  });

  final String artisanName;
  final VoidCallback onChat;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Message $artisanName',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onReport,
            child: Text(
              'Report an issue',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
