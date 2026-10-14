import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/artisan/presentation/providers/artisan_profile_providers.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/presentation/providers/service_catalog_providers.dart';
import '../providers/artisan_verification_providers.dart';
import '../widgets/verification/verification_day_chips.dart';
import '../widgets/verification/verification_info_card.dart';
import '../widgets/verification/verification_review_block.dart';
import '../widgets/verification/verification_step_indicator.dart';
import '../widgets/verification/rejection_card.dart';

class ArtisanProfessionalReviewPage extends ConsumerWidget {
  const ArtisanProfessionalReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(artisanVerificationProvider);
    final catalogAsync = ref.watch(serviceCatalogProvider);

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
          // The profile itself comes from artisanProfileProvider — we
          // don't have a strongly-typed model yet, so we treat it as a
          // dynamic map. Resolve services once the catalog arrives.
          final profileAsync = ref.watch(artisanProfileProvider);

          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(artisanProfileProvider),
            ),
            data: (profile) {
              final catalog = catalogAsync.maybeWhen(
                data: (list) => list,
                orElse: () => const <ServiceRef>[],
              );

              final complete = snapshot.status.sections.professionalComplete;

              return Column(
                children: [
                  const VerificationStepIndicator(
                    activeStep: 1,
                    completedSteps: {0},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (snapshot.status.isRejected &&
                              (snapshot.status.rejectionReason?.isNotEmpty ??
                                  false)) ...[
                            RejectionCard(
                              reason: snapshot.status.rejectionReason!,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          _introCard(),
                          const SizedBox(height: AppSpacing.md),
                          _profileSummaryCard(profile, complete),
                          const SizedBox(height: AppSpacing.md),
                          _servicesOfferedCard(profile, catalog, complete),
                          const SizedBox(height: AppSpacing.md),
                          _availabilityCard(profile, complete),
                          const SizedBox(height: AppSpacing.md),
                          _infoCallout(complete),
                        ],
                      ),
                    ),
                  ),
                  _bottomActions(context, complete),
                ],
              );
            },
          );
        },
      ),
    );
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
          Flexible(
            child: Text(
              'Professional credentials',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
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

  Widget _introCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.badge_outlined,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  'Professional profile',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            'This is what customers will see. Confirm it is accurate '
            'before submitting your verification.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSummaryCard(Map<String, dynamic> profile, bool complete) {
    final title = profile['professional_title']?.toString();
    final about = profile['professional_description']?.toString() ??
        profile['bio']?.toString();
    final years = profile['experience_years'];
    final languages = (profile['languages'] as List?)
        ?.whereType<String>()
        .toList(growable: false) ??
        const <String>[];

    final pill = complete
        ? const ReviewStatusPill.complete()
        : const ReviewStatusPill.todo();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerificationReviewBlock(
            icon: Icons.work_outline,
            label: 'Professional title',
            value: title,
            valueStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            todo: !complete,
            trailing: pill,
          ),
          const VerificationHairline(),
          VerificationReviewBlock(
            icon: Icons.description_outlined,
            label: 'About',
            value: about,
            todo: !complete,
            trailing: complete
                ? null
                : const ReviewStatusPill.todo(),
          ),
          const VerificationHairline(),
          VerificationReviewBlock(
            icon: Icons.timeline_outlined,
            label: 'Experience',
            value: years != null ? '$years' : null,
            valueStyle: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            todo: !complete,
            trailing: complete
                ? null
                : const ReviewStatusPill.todo(),
          ),
          const VerificationHairline(),
          _languagesBlock(languages, complete),
        ],
      ),
    );
  }

  Widget _languagesBlock(List<String> languages, bool complete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.language,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'LANGUAGES',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ),
            if (!complete) const ReviewStatusPill.todo(),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: languages.isEmpty
              ? Text(
                  'Not provided yet',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: languages
                      .map((lang) => _languagePill(lang))
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _languagePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        _titleCase(label),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _servicesOfferedCard(
    Map<String, dynamic> profile,
    List<ServiceRef> catalog,
    bool complete,
  ) {
    final offerings = (profile['service_offerings'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];

    final resolved = offerings
        .map((o) {
          final ref = o['service_reference']?.toString() ?? '';
          final isActive = o['is_active'] == true;
          final match = catalog.firstWhere(
            (s) => s.id == ref,
            orElse: () => ServiceRef(
              id: ref,
              name: '',
              categoryId: '',
              categorySlug: '',
              slug: '',
            ),
          );
          return (name: match.name, active: isActive, ref: ref);
        })
        .toList(growable: false);

    return VerificationInfoCard(
      headerIcon: Icons.handyman_outlined,
      headerLabel: 'Services offered',
      trailing: complete
          ? const ReviewStatusPill.complete()
          : const ReviewStatusPill.todo(),
      child: resolved.isEmpty
          ? Text(
              'No services configured',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < resolved.length; i++) ...[
                  _serviceRow(resolved[i].name, resolved[i].active),
                  if (i < resolved.length - 1) const VerificationHairline(),
                ],
              ],
            ),
    );
  }

  Widget _serviceRow(String name, bool active) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.work_outline,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Expanded(
          child: Text(
            name.isEmpty ? 'Unknown service' : name,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (active)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'Active',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _availabilityCard(Map<String, dynamic> profile, bool complete) {
    final availability = profile['availability'] as Map<String, dynamic>?;
    final days = <String>{};
    String? hoursLine;

    if (availability != null) {
      const weekdays = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      for (final day in weekdays) {
        final slots = availability[day];
        if (slots is List && slots.isNotEmpty) {
          days.add(day);
        }
      }

      // Build a simple "Monday to Friday, 08:00 – 18:00" line from the
      // first slot we find.
      final firstDay = weekdays.firstWhere(
        days.contains,
        orElse: () => '',
      );
      if (firstDay.isNotEmpty) {
        final slot = availability[firstDay] as List;
        final first = slot.first as Map<String, dynamic>;
        final start = first['start']?.toString() ?? '';
        final end = first['end']?.toString() ?? '';
        if (start.isNotEmpty && end.isNotEmpty) {
          hoursLine = 'Monday to Friday, $start – $end';
        }
      }
    }

    return VerificationInfoCard(
      headerIcon: Icons.schedule_outlined,
      headerLabel: 'Availability',
      trailing: complete
          ? const ReviewStatusPill.complete()
          : const ReviewStatusPill.todo(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerificationDayChips(availableDays: days),
          if (hoursLine != null) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                hoursLine,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'No working hours set',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCallout(bool complete) {
    final message = complete
        ? 'To edit any of these details, use the Edit profile option below.'
        : 'Complete your professional profile before submitting your verification.';

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
              message,
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

  Widget _bottomActions(BuildContext context, bool complete) {
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
              onPressed: complete ? () => context.pop() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Looks good',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: complete
                      ? AppColors.textInverse
                      : AppColors.disabledText,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton.icon(
              onPressed: () => context.push('/artisan-home/profile/edit'),
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              label: Text(
                'Edit profile',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
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