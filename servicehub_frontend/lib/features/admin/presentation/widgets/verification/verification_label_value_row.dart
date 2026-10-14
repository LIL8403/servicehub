import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A single label-value row used inside verification detail cards.
///
/// Renders an uppercase fixed-width label on the left, and either a
/// Text, a list of chips, or a custom widget on the right.
class VerificationLabelValueRow extends StatelessWidget {
  const VerificationLabelValueRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.labelWidth = 160,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: valueWidget ??
              Text(
                value ?? '—',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
        ),
      ],
    );
  }
}