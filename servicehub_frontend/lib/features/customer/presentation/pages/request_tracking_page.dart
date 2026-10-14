import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/enums/service_request_status.dart';
import '../../domain/models/service_request.dart';
import '../providers/request_tracking_providers.dart';
import '../widgets/tracking/artisan_accepted_view.dart';
import '../widgets/tracking/awaiting_artisan_selection_view.dart';
import '../widgets/tracking/awaiting_confirmation_view.dart';
import '../widgets/tracking/booked_view.dart';
import '../widgets/tracking/cancelled_view.dart';
import '../widgets/tracking/completed_view.dart';
import '../widgets/tracking/disputed_view.dart';
import '../widgets/tracking/in_progress_view.dart';
import '../widgets/tracking/no_artisan_available_view.dart';
import '../widgets/tracking/payment_pending_view.dart';
import '../widgets/tracking/pending_artisan_response_view.dart';
import '../widgets/tracking/quotation_received_view.dart';

/// The customer-facing Request Tracking screen.
class RequestTrackingPage extends ConsumerWidget {
  const RequestTrackingPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serviceRequestDetailsProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: async.when(
        loading: () => const _LoadingView(),
        error: (err, _) => _ErrorView(
          message: describeTrackingError(err),
          onRetry: () =>
              ref.invalidate(serviceRequestDetailsProvider(requestId)),
        ),
        data: (request) => _TrackingBody(request: request),
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    switch (request.status) {
      case ServiceRequestStatus.pendingArtisanResponse:
        return PendingArtisanResponseView(request: request);

      case ServiceRequestStatus.awaitingArtisanSelection:
      case ServiceRequestStatus.created:
        return AwaitingArtisanSelectionView(request: request);

      case ServiceRequestStatus.noArtisanAvailable:
        return NoArtisanAvailableView(request: request);

      case ServiceRequestStatus.artisanApproved:
        return ArtisanAcceptedView(request: request);

      case ServiceRequestStatus.quotationReceived:
      case ServiceRequestStatus.quotationPending:
        return QuotationReceivedView(request: request);

      case ServiceRequestStatus.paymentPending:
        return PaymentPendingView(request: request);

      case ServiceRequestStatus.booked:
        return BookedView(request: request);

      case ServiceRequestStatus.inProgress:
        return InProgressView(request: request);

      case ServiceRequestStatus.awaitingConfirmation:
        return AwaitingConfirmationView(request: request);

      case ServiceRequestStatus.completed:
        return CompletedView(request: request);

      case ServiceRequestStatus.cancelled:
        return CancelledView(request: request);

      case ServiceRequestStatus.disputed:
        return DisputedView(request: request);

      // Only truly unknown statuses fall here now.
      default:
        return _ComingSoonView(request: request);
    }
  }
}

// ============================================================
// Loading & error shells
// ============================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _SimpleAppBar(onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textInverse,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonView extends StatelessWidget {
  const _ComingSoonView({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _SimpleAppBar(onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Status: ${request.status.label}',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'The view for this status is coming in a later batch.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleAppBar extends StatelessWidget {
  const _SimpleAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: onBack,
          ),
          Text(
            'Request',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}