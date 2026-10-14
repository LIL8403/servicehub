import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../ui/core/theme/app_colors.dart';
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

/// The view shown while a request is waiting for the selected artisan
/// to respond. Maps to mockup #1 ("Waiting for Pauline").
class PendingArtisanResponseView extends ConsumerWidget {
  const PendingArtisanResponseView({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artisanName = request.selectedArtisan?.firstName ?? 'the artisan';
    final elapsedLabel = _elapsedLabel(request.pendingSince);

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
                    icon: Icons.schedule,
                    tone: StatusHeroTone.waiting,
                    title: 'Waiting for $artisanName',
                    body:
                        "$artisanName has been notified and will respond within 24 hours.",
                    trailing: _WaitingProgress(elapsedLabel: elapsedLabel),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (request.selectedArtisan != null) ...[
                    _SelectedArtisanSummary(
                      name: request.selectedArtisan!.name,
                      title: request.selectedArtisan!.professionalTitle,
                      rating: request.selectedArtisan!.ratingAverage,
                      reviewCount: request.selectedArtisan!.reviewCount,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  RequestDetailsCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  TrackingTimeline(request: request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'What happens next?',
                    body:
                        "$artisanName will review your request and either accept it or send you a quotation. You'll be notified the moment they respond.",
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            artisanName: request.selectedArtisan?.firstName,
            // Was: onChat: () {}, onViewProfile: () {}, onCancel: () {}
            onChat: () => TrackingActions.openConversation(context, request),
            onViewProfile: () =>
                TrackingActions.openPublicProfile(context, request),
                        onCancel: () => TrackingActions.cancelRequest(context, ref, request),// Cancel flow is out of scope for this batch
          ),
        ],
      ),
    );
  }

  String _elapsedLabel(DateTime? pendingSince) {
    if (pendingSince == null) return 'Just sent';
    final diff = DateTime.now().difference(pendingSince);
    if (diff.inMinutes < 1) return 'Just sent';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m elapsed';
    return '${diff.inHours}h elapsed';
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _WaitingProgress extends StatelessWidget {
  const _WaitingProgress({required this.elapsedLabel});

  final String elapsedLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: 0.2,
            minHeight: 6,
            backgroundColor: AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              elapsedLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '24h timeout',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectedArtisanSummary extends StatelessWidget {
  const _SelectedArtisanSummary({
    required this.name,
    required this.title,
    required this.rating,
    required this.reviewCount,
  });

  final String name;
  final String title;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                  name,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· $reviewCount reviews',
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.artisanName,
    required this.onChat,
    required this.onViewProfile,
    required this.onCancel,
  });

  final String? artisanName;
  final VoidCallback onChat;
  final VoidCallback onViewProfile;
  final VoidCallback onCancel;

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
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel request',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}