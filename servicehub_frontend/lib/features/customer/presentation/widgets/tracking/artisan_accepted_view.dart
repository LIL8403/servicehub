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

/// The view shown after the artisan has accepted the request but before
/// they've sent a quotation. Maps to mockup #4 ("Artisan Accepted").
class ArtisanAcceptedView extends StatelessWidget {
  const ArtisanAcceptedView({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final artisanName = request.selectedArtisan?.firstName ?? 'The artisan';

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
                    icon: Icons.task_alt,
                    tone: StatusHeroTone.success,
                    title: '$artisanName accepted your request',
                    body:
                        '$artisanName is reviewing the job details and '
                        'preparing your quotation.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (request.selectedArtisan != null) ...[
                    _ArtisanCard(request: request),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const _NextStepBanner(),
                  const SizedBox(height: AppSpacing.md),
                  RequestDetailsCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  TrackingTimeline(request: request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'What happens next?',
                    body:
                        '$artisanName may propose a short on-site inspection '
                        'before issuing the final quote. Standard quotes are '
                        'delivered directly in-app.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            artisanName: request.selectedArtisan?.firstName,
            // Was: onChat: () {}, onViewProfile: () {}
            onChat: () => TrackingActions.openConversation(context, request),
            onViewProfile: () =>
                TrackingActions.openPublicProfile(context, request),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              artisan.firstName.isNotEmpty
                  ? artisan.firstName[0].toUpperCase()
                  : '?',
              style: AppTypography.h3.copyWith(
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      artisan.ratingAverage.toStringAsFixed(1),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· ${artisan.reviewCount} reviews',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepBanner extends StatelessWidget {
  const _NextStepBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.45),
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next step: Quotation',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You will receive an itemised quote with a labour and '
                  'materials breakdown. All pricing is agreed in advance.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
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
    required this.onViewProfile,
  });

  final String? artisanName;
  final VoidCallback onChat;
  final VoidCallback onViewProfile;

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
                  Text(
                    artisanName != null
                        ? 'Chat with $artisanName'
                        : 'Chat with artisan',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: AppColors.textInverse,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'View Artisan Profile',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}