import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A white card with a small header row and free-form content below.
///
/// Matches the ServiceHUB card style: 12px radius, 1px border
/// #E2E8F0, 16px padding, subtle shadow.
class VerificationInfoCard extends StatelessWidget {
  const VerificationInfoCard({
    super.key,
    required this.headerIcon,
    required this.headerLabel,
    required this.child,
    this.trailing,
    this.headerColor,
  });

  final IconData headerIcon;
  final String headerLabel;
  final Widget child;
  final Widget? trailing;
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
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
              Icon(
                headerIcon,
                size: 18,
                color: headerColor ?? AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  headerLabel.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: headerColor ?? AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          child,
        ],
      ),
    );
  }
}

/// A 1px divider used between blocks inside cards.
class VerificationHairline extends StatelessWidget {
  const VerificationHairline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      color: AppColors.borderLight,
    );
  }
}