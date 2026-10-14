import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/verification_status.dart';
import '../providers/artisan_verification_providers.dart';
import '../widgets/verification/rejection_card.dart';

class ArtisanVerificationPage extends ConsumerWidget {
  const ArtisanVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(artisanVerificationProvider);
    final action = ref.watch(verificationActionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verification center',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(artisanVerificationProvider),
        ),
        data: (snapshot) {
          final status = snapshot.status;

          return Column(
            children: [
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
                      _StatusHero(status: status),
                      const SizedBox(height: AppSpacing.md),
                      if (status.isRejected &&
                          (status.rejectionReason?.isNotEmpty ?? false)) ...[
                        RejectionCard(reason: status.rejectionReason!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const _SectionLabel(text: 'SECTIONS'),
                      const SizedBox(height: AppSpacing.sm),
                      _SectionCard(
                        icon: Icons.person_outline,
                        title: 'Identity',
                        description:
                            'Legal name, date of birth, ID document, and a verification selfie.',
                        complete: status.sections.identityComplete,
                        editable: status.isEditable,
                        onTap: () =>
                            _handleSectionTap(context, status, 'identity'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SectionCard(
                        icon: Icons.badge_outlined,
                        title: 'Professional credentials',
                        description:
                            'Your professional title, services, experience, and service area.',
                        complete: status.sections.professionalComplete,
                        editable: status.isEditable,
                        onTap: () =>
                            _handleSectionTap(context, status, 'professional'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SectionCard(
                        icon: Icons.folder_outlined,
                        title: 'Supporting documents',
                        description:
                            'Optional certificates, trade qualifications, and business registration.',
                        complete: status.sections.supportingComplete,
                        editable: status.isEditable,
                        onTap: () =>
                            _handleSectionTap(context, status, 'supporting'),
                        pillOverride: status.sections.supportingComplete
                            ? null
                            : _optionalPill(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (action.errorMessage != null) ...[
                        _ErrorBanner(message: action.errorMessage!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const _SubmissionRulesCard(),
                    ],
                  ),
                ),
              ),
              if (status.isEditable)
                _BottomActions(
                  enabled:
                      true, // Always allow navigation to the review screen.
                  isSubmitting: false,
                  onSubmit: () {
                    context.push('/artisan-home/profile/verification/review');
                  },
                )
              else
                _ReadOnlyFooter(status: status),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, tone, title, body, pillLabel) = _variant();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: tone.fg),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: tone.pillBg,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  pillLabel,
                  style: AppTypography.caption.copyWith(
                    color: tone.fg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, _Tone, String, String, String) _variant() {
    if (status.isVerified) {
      return (
        Icons.verified_user,
        _Tone(
          bg: AppColors.successTint.withValues(alpha: 0.5),
          border: AppColors.success.withValues(alpha: 0.3),
          iconBg: AppColors.successTint,
          fg: AppColors.success,
          pillBg: AppColors.successTint,
        ),
        'You are a verified artisan',
        'Your profile is visible to customers and you can receive new requests.',
        'VERIFIED',
      );
    }
    if (status.isPending) {
      return (
        Icons.schedule,
        _Tone(
          bg: AppColors.warningTint.withValues(alpha: 0.5),
          border: AppColors.warning.withValues(alpha: 0.3),
          iconBg: AppColors.warningTint,
          fg: AppColors.warning,
          pillBg: AppColors.warningTint,
        ),
        'Verification in review',
        'We are reviewing your documents. This usually takes 1 to 2 business days.',
        'PENDING',
      );
    }
    if (status.isRejected) {
      return (
        Icons.error_outline,
        _Tone(
          bg: AppColors.errorTint.withValues(alpha: 0.5),
          border: AppColors.error.withValues(alpha: 0.3),
          iconBg: AppColors.errorTint,
          fg: AppColors.error,
          pillBg: AppColors.errorTint,
        ),
        'Verification needs attention',
        'Please review the feedback below, correct the indicated sections, and resubmit.',
        'ACTION NEEDED',
      );
    }
    return (
      Icons.lock_outline,
      _Tone(
        bg: AppColors.cream.withValues(alpha: 0.55),
        border: AppColors.secondary.withValues(alpha: 0.3),
        iconBg: AppColors.cream,
        fg: AppColors.secondary,
        pillBg: AppColors.cream,
      ),
      'Become a verified artisan',
      'Submit your identity and professional details to unlock more jobs and build customer trust.',
      'START HERE',
    );
  }
}

class _Tone {
  const _Tone({
    required this.bg,
    required this.border,
    required this.iconBg,
    required this.fg,
    required this.pillBg,
  });

  final Color bg;
  final Color border;
  final Color iconBg;
  final Color fg;
  final Color pillBg;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.complete,
    required this.editable,
    required this.onTap,
    this.pillOverride,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool complete;
  final bool editable;
  final VoidCallback onTap;

  /// When provided, this widget replaces the default COMPLETE/TODO
  /// pill. Used by the supporting documents card, which is optional
  /// and should display "OPTIONAL" instead of "TODO" when empty.
  final Widget? pillOverride;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: complete ? AppColors.successTint : AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  complete ? Icons.check : icon,
                  size: 20,
                  color: complete ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        pillOverride ?? _defaultPill(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: editable
                    ? AppColors.primary
                    : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultPill() {
    if (complete) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.successTint,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          'COMPLETE',
          style: AppTypography.caption.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 0.4,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        'TODO',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SubmissionRulesCard extends StatelessWidget {
  const _SubmissionRulesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Before you submit',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _bullet('Complete the identity and professional sections.'),
          _bullet('Supporting documents are optional.'),
          _bullet('You cannot edit your application while it is under review.'),
          _bullet(
            'If your application is rejected, you will be able to correct '
            'the indicated sections and resubmit.',
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
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
    required this.enabled,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool enabled;
  final bool isSubmitting;
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
          onPressed: (enabled && !isSubmitting) ? onSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
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
              : Text(
                  'Review & submit',
                  // Disabled state when not all sections are complete.
                  style: AppTypography.bodyLarge.copyWith(
                    color: enabled
                        ? AppColors.textInverse
                        : AppColors.disabledText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReadOnlyFooter extends StatelessWidget {
  const _ReadOnlyFooter({required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final message = status.isVerified
        ? 'Your profile is visible to customers.'
        : 'Your application is under review. We will notify you when it is processed.';

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
      child: Row(
        children: [
          Icon(
            status.isVerified ? Icons.verified_user : Icons.lock_clock,
            size: 18,
            color: status.isVerified ? AppColors.success : AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
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

void _handleSectionTap(
  BuildContext context,
  VerificationStatus status,
  String section,
) {
  // Professional credentials is a live view of the public profile
  // and can be updated any time — always navigate, regardless of
  // verification status.
  if (section == 'professional') {
    context.push('/artisan-home/profile/verification/professional');
    return;
  }

  // Other sections navigate only when the artisan can edit them.
  if (status.isEditable) {
    switch (section) {
      case 'identity':
        context.push('/artisan-home/profile/verification/identity');
        return;
      case 'supporting':
        context.push('/artisan-home/profile/verification/documents');
        return;
    }
  }

  // Otherwise, explain why the section is locked.
  final String message;
  if (status.isVerified) {
    message =
        'Your verification is complete. Contact support if you need to update your details.';
  } else if (status.isPending) {
    message =
        'Your verification is under review. You will be notified when it is processed.';
  } else if (status.isRejected) {
    message = 'Please review the feedback and update your application.';
  } else {
    message = 'This section is not available right now.';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
    ),
  );
}

Widget _optionalPill() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(9999),
    ),
    child: Text(
      'OPTIONAL',
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 9,
        letterSpacing: 0.4,
      ),
    ),
  );
}
