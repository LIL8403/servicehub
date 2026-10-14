import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_request_providers.dart';

class ArtisanReportCompletionPage extends ConsumerStatefulWidget {
  const ArtisanReportCompletionPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ArtisanReportCompletionPage> createState() =>
      _ArtisanReportCompletionPageState();
}

class _ArtisanReportCompletionPageState
    extends ConsumerState<ArtisanReportCompletionPage> {
  final TextEditingController _notesController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final notes = _notesController.text.trim();

    final ok = await ref
        .read(artisanActionProvider.notifier)
        .reportCompletion(
          widget.requestId,
          notes: notes.isEmpty ? null : notes,
        );

    if (!mounted) return;

    if (ok) {
      ref.invalidate(artisanRequestDetailsProvider(widget.requestId));
      ref.invalidate(artisanRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completion reported. The customer will confirm shortly.',
          ),
        ),
      );
      context.pop();
    } else {
      setState(() {
        _errorMessage = ref.read(artisanActionProvider).errorMessage ??
            'Could not report completion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(artisanActionProvider);
    final async =
        ref.watch(artisanRequestDetailsProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(
              artisanRequestDetailsProvider(widget.requestId),
            ),
          ),
          data: (request) {
            final serviceName = request.service?.name ?? 'Service';
            final location = request.location?.label ?? 'Location not set';
            final shortRef = widget.requestId.length <= 6
                ? widget.requestId.toUpperCase()
                : widget.requestId
                    .substring(widget.requestId.length - 6)
                    .toUpperCase();

            return Column(
              children: [
                _AppBar(onBack: () => context.pop()),
                _ReferenceStrip(
                  serviceName: serviceName,
                  location: location,
                  shortRef: shortRef,
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
                        const _IntroCard(),
                        const SizedBox(height: AppSpacing.md),
                        _NotesCard(controller: _notesController),
                        const SizedBox(height: AppSpacing.md),
                        const _ReassuranceCard(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: _errorMessage!),
                        ],
                      ],
                    ),
                  ),
                ),
                _BottomActions(
                  submitting: action.isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: onBack,
          ),
          Text(
            'Report completion',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceStrip extends StatelessWidget {
  const _ReferenceStrip({
    required this.serviceName,
    required this.location,
    required this.shortRef,
  });

  final String serviceName;
  final String location;
  final String shortRef;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.cream.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.build_outlined,
            size: 14,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$serviceName · $location · Ref: $shortRef',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.4),
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to hand off the job?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reporting completion notifies the customer to inspect '
                  'the work and release the escrow payment. Make sure '
                  'everything is finished before you submit.',
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

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'COMPLETION NOTES',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          TextField(
            controller: controller,
            maxLines: 5,
            maxLength: 1000,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Describe the work performed, any parts replaced, and '
                  'the condition of the site when you left. The customer '
                  'will see this note.',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.all(AppSpacing.sm + 2),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderMd,
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderMd,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReassuranceCard extends StatelessWidget {
  const _ReassuranceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The payment stays in escrow until the customer confirms. '
              'If they don\'t respond within 48 hours, the payment releases '
              'automatically.',
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
          const Icon(
            Icons.error_outline,
            size: 20,
            color: AppColors.error,
          ),
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
    required this.onSubmit,
  });

  final bool submitting;
  final VoidCallback onSubmit;

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
          onPressed: submitting ? null : onSubmit,
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
                      'Mark as complete',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}