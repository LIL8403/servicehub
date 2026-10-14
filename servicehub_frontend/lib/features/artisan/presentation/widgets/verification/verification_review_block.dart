import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A single "label + value" block used inside a review card.
///
/// Layout:
///   [icon] LABEL                                        [pill]
///          Value rendered below with 26px left padding to
///          align under the label text (matching the mockup).
class VerificationReviewBlock extends StatelessWidget {
  const VerificationReviewBlock({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.trailing,
    this.todo = false,
    this.placeholder = 'Not provided yet',
  });

  final IconData icon;
  final String label;
  final String? value;
  final TextStyle? valueStyle;
  final Widget? trailing;
  final bool todo;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: hasValue
              ? Text(
                  value!,
                  style: valueStyle ??
                      AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontSize: 14,
                      ),
                )
              : Text(
                  placeholder,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }
}

/// The small pill used to mark a section COMPLETE or TODO.
class ReviewStatusPill extends StatelessWidget {
  const ReviewStatusPill.complete({super.key})
      : _variant = _PillVariant.complete;

  const ReviewStatusPill.todo({super.key}) : _variant = _PillVariant.todo;

  final _PillVariant _variant;

  @override
  Widget build(BuildContext context) {
    final isComplete = _variant == _PillVariant.complete;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.successTint : AppColors.cream,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        isComplete ? 'COMPLETE' : 'TODO',
        style: AppTypography.caption.copyWith(
          color: isComplete ? AppColors.success : AppColors.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

enum _PillVariant { complete, todo }