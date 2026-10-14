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

/// The view shown once the job is complete and payment released.
class CompletedView extends StatelessWidget {
  const CompletedView({super.key, required this.request});

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
                    icon: Icons.check_circle,
                    tone: StatusHeroTone.success,
                    title: 'Job completed',
                    body:
                        'Payment has been released to $artisanName. Thank '
                        'you for using ServiceHUB.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReviewPromptCard(artisanName: artisanName),
                  const SizedBox(height: AppSpacing.md),
                  RequestDetailsCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  TrackingTimeline(request: request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'Anything wrong?',
                    body:
                        'You can still report an issue within 48 hours of '
                        'completion if you discover a problem with the '
                        'work.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            artisanName: artisanName,
            // Was: onReview: () {}, onReport: () {}
            onReview: () => TrackingActions.openReview(context, request),
            onReport: () => TrackingActions.openDispute(context, request),
          ),
        ],
      ),
    );
  }
}

class _ReviewPromptCard extends StatelessWidget {
  const _ReviewPromptCard({required this.artisanName});

  final String artisanName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_outline,
                size: 22,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leave a review',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your feedback helps other customers pick the right artisan '
            'and rewards $artisanName for a job well done.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
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
    required this.onReview,
    required this.onReport,
  });

  final String artisanName;
  final VoidCallback onReview;
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
              onPressed: onReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    size: 20,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Leave a review',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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