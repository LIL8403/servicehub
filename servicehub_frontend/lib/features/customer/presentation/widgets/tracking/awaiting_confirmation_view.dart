import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/api/api_exception.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
// ignore: unused_import
import '../../../data/repositories/service_request_repository.dart';
import '../../../domain/models/service_request.dart';
import '../../providers/request_tracking_providers.dart';
import 'info_callout_card.dart';
import 'request_details_card.dart';
import 'request_glance_card.dart';
import 'status_hero_card.dart';
import 'tracking_app_bar.dart';
import 'tracking_timeline.dart';
import 'tracking_actions.dart';

/// The view shown once the artisan has marked the job complete and
/// the customer needs to inspect and confirm. Maps to mockup #9.
class AwaitingConfirmationView extends ConsumerStatefulWidget {
  const AwaitingConfirmationView({super.key, required this.request});

  final ServiceRequest request;

  @override
  ConsumerState<AwaitingConfirmationView> createState() =>
      _AwaitingConfirmationViewState();
}

class _AwaitingConfirmationViewState
    extends ConsumerState<AwaitingConfirmationView> {
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _onConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: Text(
          'Confirm completion?',
          style: AppTypography.h4.copyWith(color: AppColors.primary),
        ),
        content: Text(
          'This will release the escrow payment to the artisan. Only '
          'confirm after you have inspected the work yourself.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Confirm & release',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(requestTrackingRepositoryProvider)
          .confirmCompletion(widget.request.id);

      if (!mounted) return;

      ref.invalidate(serviceRequestDetailsProvider(widget.request.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.firstErrorMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final artisanName =
        widget.request.selectedArtisan?.firstName ?? 'the artisan';
    final completion = widget.request.completion;

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
                  RequestGlanceCard(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  StatusHeroCard(
                    icon: Icons.task_alt,
                    tone: StatusHeroTone.success,
                    title: '$artisanName marked this work as complete',
                    body:
                        'Please inspect the completed job before releasing '
                        'the escrow payment.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (completion != null && completion.notes != null) ...[
                    _CompletionNotesCard(notes: completion.notes!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const _InspectionChecklistCard(),
                  const SizedBox(height: AppSpacing.md),
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  RequestDetailsCard(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  TrackingTimeline(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'What happens next?',
                    body:
                        'Confirming releases the funds to $artisanName '
                        'immediately. If anything is unfinished or defective, '
                        'report an issue to keep funds on hold.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            submitting: _submitting,
            onConfirm: _onConfirm,
            onReport: () =>
                TrackingActions.openDispute(context, widget.request),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _CompletionNotesCard extends StatelessWidget {
  const _CompletionNotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, size: 18, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'Artisan sign-off note',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: AppColors.secondary, width: 3),
              ),
            ),
            child: Text(
              '"$notes"',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionChecklistCard extends StatelessWidget {
  const _InspectionChecklistCard();

  static const _items = [
    'Inspect the work area for cleanliness',
    'Test that everything operates as described',
    'Confirm no damage was done during the job',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSPECTION CHECKLIST',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _items[i],
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (i < _items.length - 1) const SizedBox(height: 8),
          ],
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
    required this.submitting,
    required this.onConfirm,
    required this.onReport,
  });

  final bool submitting;
  final VoidCallback onConfirm;
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
              onPressed: submitting ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
              ),
              child: submitting
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
                          Icons.check_circle_outline,
                          size: 20,
                          color: AppColors.textInverse,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Confirm completion',
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
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: submitting ? null : onReport,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.report_problem_outlined,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Report an issue',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
