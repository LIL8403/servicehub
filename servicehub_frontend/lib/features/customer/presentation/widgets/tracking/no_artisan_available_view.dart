import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/customer/presentation/widgets/tracking/tracking_actions.dart';

import '../../../../../core/api/api_exception.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_request.dart';
import '../../providers/request_tracking_providers.dart';
import 'info_callout_card.dart';
import 'request_details_card.dart';
import 'request_glance_card.dart';
import 'status_hero_card.dart';
import 'tracking_app_bar.dart';
import 'tracking_timeline.dart';

/// The view shown when no artisans are available for the request.
/// Maps to mockup #3 ("No eligible artisans" / "Matching paused").
class NoArtisanAvailableView extends ConsumerStatefulWidget {
  const NoArtisanAvailableView({super.key, required this.request});

  final ServiceRequest request;

  @override
  ConsumerState<NoArtisanAvailableView> createState() =>
      _NoArtisanAvailableViewState();
}

class _NoArtisanAvailableViewState
    extends ConsumerState<NoArtisanAvailableView> {
  bool _retrying = false;
  String? _errorMessage;

  Future<void> _onRetry() async {
    setState(() {
      _retrying = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(requestTrackingRepositoryProvider)
          .retryMatching(widget.request.id);

      if (!mounted) return;

      ref.invalidate(serviceRequestDetailsProvider(widget.request.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.firstErrorMessage;
        _retrying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _retrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.request.noArtisanReason;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          TrackingAppBar(onBack: () => context.pop(), onHelp: () {}),
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
                  RequestGlanceCard(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  StatusHeroCard(
                    icon: Icons.construction_outlined,
                    tone: StatusHeroTone.warning,
                    title: 'No eligible artisans available',
                    body:
                        'We checked verified artisans near your location, but '
                        'none are currently accepting new jobs for this '
                        'service. This is temporary — availability changes '
                        'throughout the day.',
                    trailing: reason != null && reason.isNotEmpty
                        ? _ReasonBox(reason: reason)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ReassuranceBox(),
                  const SizedBox(height: AppSpacing.md),
                  RequestDetailsCard(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  TrackingTimeline(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const InfoCalloutCard(
                    icon: Icons.explore_outlined,
                    title: 'What happens next?',
                    body:
                        'You can try matching again now, or cancel this '
                        'request and submit a new one later when more '
                        'artisans are available.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            retrying: _retrying,
            onRetry: _onRetry,
            onCancel: () => TrackingActions.cancelRequest(context, ref, widget.request),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReassuranceBox extends StatelessWidget {
  const _ReassuranceBox();

  @override
  Widget build(BuildContext context) {
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
            Icons.verified_user_outlined,
            size: 20,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your request is safe',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nothing has been cancelled or lost. When artisans become '
                  'available, you can retry matching with one tap.',
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.retrying,
    required this.onRetry,
    required this.onCancel,
  });

  final bool retrying;
  final VoidCallback onRetry;
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
              onPressed: retrying ? null : onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
              ),
              child: retrying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textInverse,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh,
                          size: 20,
                          color: AppColors.textInverse,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Try matching again',
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
