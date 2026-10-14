import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_verification_providers.dart';
import '../widgets/verification/rejection_card.dart';
import '../widgets/verification/submission_section_card.dart';

class ArtisanSubmissionReviewPage extends ConsumerStatefulWidget {
  const ArtisanSubmissionReviewPage({super.key});

  @override
  ConsumerState<ArtisanSubmissionReviewPage> createState() =>
      _ArtisanSubmissionReviewPageState();
}

class _ArtisanSubmissionReviewPageState
    extends ConsumerState<ArtisanSubmissionReviewPage> {
  

  Future<void> _onSubmit() async {
    // Guard: never fire the request when we know it will fail.
    final snapshot = ref.read(artisanVerificationProvider).valueOrNull;
    if (snapshot == null) return;

    final ready = snapshot.status.sections.identityComplete &&
        snapshot.status.sections.professionalComplete;

    if (!ready) return;

    final ok = await ref
        .read(verificationActionProvider.notifier)
        .submit();

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification submitted. We will review it shortly.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/artisan-home/profile/verification');
    } else {
      final error = ref.read(verificationActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Could not submit. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artisanVerificationProvider);
    final action = ref.watch(verificationActionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(context),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(artisanVerificationProvider),
        ),
        data: (snapshot) {
          final status = snapshot.status;
          final sections = status.sections;

          final identityReady = sections.identityComplete;
          final professionalReady = sections.professionalComplete;
          final supportingCount = sections.supportingCount;
          final allRequiredReady = identityReady && professionalReady;

          

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (status.isRejected &&
                          (status.rejectionReason?.isNotEmpty ?? false)) ...[
                        RejectionCard(reason: status.rejectionReason!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _heroCard(),
                      const SizedBox(height: AppSpacing.md),
                      _sectionLabel('WHAT WILL BE SUBMITTED'),
                      const SizedBox(height: AppSpacing.sm + 2),
                      SubmissionSectionCard(
                        title: 'Identity',
                        subtitle: identityReady
                            ? 'Legal name, ID document, and selfie on file'
                            : 'Missing: legal name or ID document',
                        state: identityReady
                            ? SubmissionCardState.ready
                            : SubmissionCardState.required,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SubmissionSectionCard(
                        title: 'Professional credentials',
                        subtitle: professionalReady
                            ? 'Professional title, services, experience on file'
                            : 'Missing: professional title or services offered',
                        state: professionalReady
                            ? SubmissionCardState.ready
                            : SubmissionCardState.required,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SubmissionSectionCard(
                        title: 'Supporting documents',
                        subtitle: _supportingSubtitle(supportingCount),
                        state: supportingCount > 0
                            ? SubmissionCardState.ready
                            : SubmissionCardState.optional,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _infoCallout(),
                      
                      if (action.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _actionErrorBanner(action.errorMessage!),
                      ],
                    ],
                  ),
                ),
              ),
              _bottomActions(allRequiredReady, action.isSubmitting),
            ],
          );
        },
      ),
    );
  }

  String _supportingSubtitle(int count) {
    if (count == 0) return 'None uploaded — this is optional';
    if (count == 1) return '1 document added';
    return '$count documents added';
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Text(
            'Review & submit',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SvgPicture.asset(
              'assets/brand/logo_symbol.svg',
              width: 28,
              height: 28,
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.borderLight),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.fact_check_outlined,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to submit?',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review the sections below. Your application will be '
                  'sent to our verification team for review. This '
                  'usually takes 1 to 2 business days.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontSize: 10,
      ),
    );
  }

  Widget _infoCallout() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 6),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Once submitted, you will not be able to edit your '
              'application until the review is complete. You will be '
              'notified by email and in-app when we have an update.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _actionErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 6),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(bool ready, bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (ready && !isSubmitting) ? _onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  : Text(
                      ready
                          ? 'Submit for verification'
                          : 'Complete all required sections',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ready
                            ? AppColors.textInverse
                            : AppColors.disabledText,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: isSubmitting ? null : () => context.pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back to overview',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
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