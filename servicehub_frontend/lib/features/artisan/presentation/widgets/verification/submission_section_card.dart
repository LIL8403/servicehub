import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// The three states a submission summary card can render.
enum SubmissionCardState { ready, required, optional }

/// A single summary row on the Review & submit screen.
///
/// Mirrors the layout of the three "What will be submitted" cards
/// shown on the submission review screen.
class SubmissionSectionCard extends StatelessWidget {
  const SubmissionSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final SubmissionCardState state;

  @override
  Widget build(BuildContext context) {
    final (circleBg, icon, iconColor) = _leadingIcon();
    final (pillBg, pillFg, pillText) = _pill();

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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: state == SubmissionCardState.required
                        ? AppColors.error
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              pillText,
              style: AppTypography.caption.copyWith(
                color: pillFg,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, Color) _leadingIcon() {
    switch (state) {
      case SubmissionCardState.ready:
        return (AppColors.successTint, Icons.check, AppColors.success);
      case SubmissionCardState.required:
        return (AppColors.cream, Icons.person_outline, AppColors.primary);
      case SubmissionCardState.optional:
        return (AppColors.cream, Icons.folder_open, AppColors.primary);
    }
  }

  (Color, Color, String) _pill() {
    switch (state) {
      case SubmissionCardState.ready:
        return (AppColors.successTint, AppColors.success, 'READY');
      case SubmissionCardState.required:
        return (AppColors.errorTint, AppColors.error, 'REQUIRED');
      case SubmissionCardState.optional:
        return (const Color(0xFFF1F5F9), AppColors.textMuted, 'OPTIONAL');
    }
  }
}