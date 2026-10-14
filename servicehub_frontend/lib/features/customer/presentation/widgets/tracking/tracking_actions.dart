import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servicehub_frontend/core/api/api_exception.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../providers/request_tracking_providers.dart';
import '../../providers/service_request_tracking_providers.dart';
import '../../../domain/models/service_request.dart';

/// Centralised helper for the tracking views' CTAs. Each method reads
/// the current tab from the route and pushes a sub-route scoped to
/// that tab, so "back" returns to the tab the user came from.
class TrackingActions {
  TrackingActions._();

  /// The current tab's prefix. Defaults to the Home tab when the
  /// route doesn't match a known shell branch.
  static String _prefix(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/customer-home/requests')) {
      return '/customer-home/requests';
    }
    return '/customer-home';
  }

  static void openConversation(BuildContext context, ServiceRequest request) {
    final artisan = request.selectedArtisan;
    final prefix = _prefix(context);
    final uri = Uri(
      path: '$prefix/request/${request.id}/conversation',
      queryParameters: {
        if (artisan != null && artisan.name.isNotEmpty)
          'artisanName': artisan.name,
        if (artisan != null && artisan.professionalTitle.isNotEmpty)
          'artisanTitle': artisan.professionalTitle,
      },
    );
    context.push(uri.toString());
  }

  static void openPublicProfile(BuildContext context, ServiceRequest request) {
    final artisan = request.selectedArtisan;
    if (artisan == null || artisan.id.isEmpty) return;
    final uri = Uri(
      path: '/artisans/${artisan.id}',
      queryParameters: {'requestId': request.id},
    );
    context.push(uri.toString());
  }

  static void openReview(BuildContext context, ServiceRequest request) {
    final artisan = request.selectedArtisan;
    final prefix = _prefix(context);
    final uri = Uri(
      path: '$prefix/request/${request.id}/review',
      queryParameters: {
        if (artisan != null && artisan.name.isNotEmpty)
          'artisanName': artisan.name,
        if (artisan != null && artisan.professionalTitle.isNotEmpty)
          'artisanTitle': artisan.professionalTitle,
      },
    );
    context.push(uri.toString());
  }

  /// Prompts the customer for a cancellation reason, calls the backend,
  /// and refreshes the tracking view. Safe to call from any ConsumerWidget
  static Future<void> cancelRequest(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reason = await _promptCancelReason(context, l10n);
    if (reason == null) return;

    try {
      await ref
          .read(serviceRequestTrackingRepositoryProvider)
          .cancel(request.id, reason);

      if (!context.mounted) return;

      // Refresh the tracking page so it re-renders as CancelledView.
      // The detail provider is what the tracking page actually watches.
      ref.invalidate(serviceRequestDetailsProvider(request.id));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.firstErrorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.trackingCancelFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// The dialog that collects a mandatory cancellation reason.
  /// Returns the trimmed reason, or null if the user backed out.
  static Future<String?> _promptCancelReason(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController();
    String? validationError;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
          title: Text(
            l10n.trackingCancelDialogTitle,
            style: AppTypography.h4.copyWith(color: AppColors.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.trackingCancelDialogBody,
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
                  hintText: l10n.trackingCancelReasonHint,
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
                l10n.commonKeepIt,
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
                    validationError = l10n.trackingCancelReasonRequired;
                  });
                  return;
                }
                Navigator.of(ctx).pop(trimmed);
              },
              child: Text(
                l10n.trackingCancelConfirm,
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

  static void openDispute(BuildContext context, ServiceRequest request) {
    final prefix = _prefix(context);
    final uri = Uri(
      path: '$prefix/request/${request.id}/dispute',
      queryParameters: {
        if (request.service?.name != null) 'serviceName': request.service!.name,
        if (request.location?.label != null)
          'locationLabel': request.location!.label!,
      },
    );
    context.push(uri.toString());
  }

  static void openArtisanSelection(
    BuildContext context,
    ServiceRequest request,
  ) {
    final prefix = _prefix(context);
    context.push('$prefix/request/${request.id}/artisans');
  }
}
