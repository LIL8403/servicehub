import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/customer/presentation/widgets/tracking/quotation_analysis_card.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_request.dart';
import '../../providers/quotation_providers.dart';
import '../../providers/request_tracking_providers.dart';
import 'info_callout_card.dart';
import 'request_glance_card.dart';
import 'tracking_app_bar.dart';
import 'tracking_timeline.dart';
import 'tracking_actions.dart';

/// The view shown when the artisan has sent a quotation and the
/// customer needs to accept or reject. Maps to mockups #5 and #6.
class QuotationReceivedView extends ConsumerWidget {
  const QuotationReceivedView({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(quotationActionProvider);
    final artisanName = request.selectedArtisan?.firstName ?? 'the artisan';
    final quotation = request.quotation;

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
                  RequestGlanceCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  if (quotation != null)
                    _QuotationCard(quotation: quotation, requestId: request.id)
                  else
                    const _QuotationMissingCard(),
                  const SizedBox(height: AppSpacing.md),
                  if (actionState.errorMessage != null) ...[
                    _ErrorBanner(message: actionState.errorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (request.selectedArtisan != null) ...[
                    _ArtisanCard(request: request),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TrackingTimeline(request: request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'What happens next?',
                    body:
                        'When you accept, the amount is held securely by '
                        'ServiceHUB until you confirm the job is finished. '
                        'If anything is unclear, message $artisanName before deciding.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            artisanName: artisanName,
            isSubmitting: actionState.isSubmitting,
            onAccept: () => _onAccept(context, ref),
            onReject: () => _onReject(context, ref),
            // Was: onMessage: () {}
            onMessage: () => TrackingActions.openConversation(context, request),
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Accept this quotation?',
      body:
          'The agreed amount will be held securely by ServiceHUB. '
          'It is only released to the artisan after you confirm '
          'the work is complete.',
      confirmLabel: 'Accept & continue',
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(quotationActionProvider.notifier)
        .accept(request.id);

    if (!ok) return;

    ref.invalidate(serviceRequestDetailsProvider(request.id));
  }

  Future<void> _onReject(BuildContext context, WidgetRef ref) async {
    final reason = await _promptRejectReason(context);
    if (reason == null) return;

    final ok = await ref
        .read(quotationActionProvider.notifier)
        .reject(request.id, reason: reason);

    if (!ok) return;

    ref.invalidate(serviceRequestDetailsProvider(request.id));
  }

  /// Shows a dialog that collects a mandatory rejection reason.
  /// Returns the reason, or null if the user cancelled.
  Future<String?> _promptRejectReason(BuildContext context) {
    final controller = TextEditingController();
    String? validationError;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
          title: Text(
            'Reject this quotation?',
            style: AppTypography.h4.copyWith(color: AppColors.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The artisan will be notified and the request will return '
                'to artisan selection.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: 'Reason for rejecting (required)',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  errorText: validationError,
                  filled: true,
                  fillColor: AppColors.bgLight,
                  contentPadding: const EdgeInsets.all(AppSpacing.sm + 2),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.borderMd,
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.borderMd,
                    borderSide: BorderSide(
                      color: validationError != null
                          ? AppColors.error
                          : AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  setState(() {
                    validationError = 'Please provide a reason.';
                  });
                  return;
                }
                Navigator.of(ctx).pop(trimmed);
              },
              child: Text(
                'Reject quotation',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: Text(
          title,
          style: AppTypography.h4.copyWith(color: AppColors.primary),
        ),
        content: Text(
          body,
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
              confirmLabel,
              style: AppTypography.bodyMedium.copyWith(
                color: destructive ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({required this.quotation, required this.requestId});

  final Quotation quotation;
  final String requestId;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 12,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'QUOTATION',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (quotation.validUntil != null)
                Text(
                  'Valid until ${_dateLabel(quotation.validUntil!)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (quotation.scope != null && quotation.scope!.isNotEmpty) ...[
            Text(
              'SCOPE OF WORK',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              quotation.scope!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _lineItem('Labour', quotation.labourTotal),
          const SizedBox(height: AppSpacing.sm),
          _lineItem('Materials', quotation.materialsTotal),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_money(quotation.grandTotal)} XAF',
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          QuotationAnalysisCard(requestId: requestId),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'The amount stays held securely by ServiceHUB until you '
                    'confirm the job is finished.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineItem(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${_money(amount)} XAF',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _money(double amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buf.write(',');
      buf.write(rounded[i]);
    }
    return buf.toString();
  }

  String _dateLabel(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _QuotationMissingCard extends StatelessWidget {
  const _QuotationMissingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'The quotation details are being finalised. Pull to refresh '
              'in a moment.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
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
    required this.artisanName,
    required this.isSubmitting,
    required this.onAccept,
    required this.onReject,
    required this.onMessage,
  });

  final String artisanName;
  final bool isSubmitting;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMessage;

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
              onPressed: isSubmitting ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
              ),
              child: isSubmitting
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
                          Icons.shield_outlined,
                          size: 20,
                          color: AppColors.textInverse,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Accept quotation',
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
              onPressed: isSubmitting ? null : onMessage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Message $artisanName',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: isSubmitting ? null : onReject,
            child: Text(
              'Reject quotation',
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
