import 'package:flutter/material.dart';
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


/// The view shown for a cancelled request.
class CancelledView extends StatelessWidget {
  const CancelledView({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
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
                    icon: Icons.cancel_outlined,
                    tone: StatusHeroTone.error,
                    title: 'This request was cancelled',
                    body:
                        'No work will be performed. If any funds were '
                        'captured, they will be refunded according to the '
                        'platform policy.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RequestDetailsCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  TrackingTimeline(request: request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'Want to start again?',
                    body:
                        'You can book a fresh request from the home screen. '
                        'Your previous details will not be reused automatically.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            onBookAgain: () => context.go('/service-categories'),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onBookAgain});

  final VoidCallback onBookAgain;

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
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onBookAgain,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Book a new service',
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
    );
  }
}