import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../providers/create_request_providers.dart';
import 'review_card.dart';

class Step4Review extends ConsumerWidget {
  const Step4Review({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createRequestProvider);
    final notifier = ref.read(createRequestProvider.notifier);
    final draft = state.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            l10n.createRequestStep4Heading,
            style: AppTypography.h2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.createRequestStep4Subheading,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Card 1 — JOB
          ReviewCard(
            label: l10n.createRequestStep4JobLabel,
            onEdit: () => notifier.goToStep(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryLabel(l10n, draft.categoryId) ?? '',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  draft.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (draft.urgency != null) ...[
                  const SizedBox(height: AppSpacing.sm + 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      _urgencyLabel(l10n, draft.urgency!.name),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),

          // Card 2 — LOCATION
          ReviewCard(
            label: l10n.createRequestStep4LocationLabel,
            onEdit: () => notifier.goToStep(1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Text(
                    draft.formattedAddress ??
                        l10n.createRequestStep4LocationMissing,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),

          // Card 3 — SCHEDULE
          ReviewCard(
            label: l10n.createRequestStep4ScheduleLabel,
            onEdit: () => notifier.goToStep(2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scheduleHeadline(l10n, draft),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!draft.isFlexible &&
                          draft.preferredStartTime != null &&
                          draft.preferredEndTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.createRequestStep4PreferredWindow}: '
                          '${draft.preferredStartTime} – ${draft.preferredEndTime}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),

          // Card 4 — AI-ASSISTED MATCHING
          ReviewCard(
            label: l10n.createRequestStep4AiLabel,
            onEdit: () => notifier.goToStep(0),
            highlighted: draft.aiAssistEnabled,
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    draft.aiAssistEnabled
                        ? l10n.createRequestStep4AiEnabled
                        : l10n.createRequestStep4AiDisabled,
                    style: AppTypography.bodySmall.copyWith(
                      color: draft.aiAssistEnabled
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: draft.aiAssistEnabled
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: draft.aiAssistEnabled
                        ? AppColors.secondary
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    draft.aiAssistEnabled
                        ? l10n.createRequestStep4AiOn
                        : l10n.createRequestStep4AiOff,
                    style: AppTypography.bodySmall.copyWith(
                      color: draft.aiAssistEnabled
                          ? AppColors.textInverse
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Legal note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.createRequestStep4LegalNote,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _categoryLabel(AppLocalizations l10n, String? slug) {
    switch (slug) {
      case 'plumbing':
        return l10n.categoryPlumbing;
      case 'electrical':
        return l10n.categoryElectrical;
      case 'carpentry':
        return l10n.categoryCarpentry;
      case 'painting':
        return l10n.categoryPainting;
      case 'masonry':
        return l10n.categoryMasonry;
      case 'mechanics':
        return l10n.categoryMechanics;
      default:
        return slug;
    }
  }

  String _urgencyLabel(AppLocalizations l10n, String urgency) {
    switch (urgency) {
      case 'low':
        return '${l10n.createRequestStep1UrgencyLow} · ${l10n.createRequestStep1UrgencyLowDesc}';
      case 'medium':
        return '${l10n.createRequestStep1UrgencyMedium} · ${l10n.createRequestStep1UrgencyMediumDesc}';
      case 'high':
        return '${l10n.createRequestStep1UrgencyHigh} · ${l10n.createRequestStep1UrgencyHighDesc}';
      default:
        return urgency;
    }
  }

  String _scheduleHeadline(
    AppLocalizations l10n,
    dynamic draft,
  ) {
    if (draft.isFlexible) {
      return l10n.createRequestStep4ScheduleFlexible;
    }
    if (draft.preferredDate != null) {
      return DateFormat.yMMMMEEEEd(l10n.localeName)
          .format(draft.preferredDate as DateTime);
    }
    return l10n.createRequestStep4ScheduleMissing;
  }
}