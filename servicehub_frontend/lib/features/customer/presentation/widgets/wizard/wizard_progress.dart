import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class WizardProgress extends StatelessWidget {
  const WizardProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
  });

  final int currentStep;
  final int totalSteps;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm + AppSpacing.xs,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isActive = index == currentStep;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < totalSteps - 1 ? AppSpacing.sm : 0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : isActive
                              ? AppColors.secondary
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(9999),
                      border: (isCompleted || isActive)
                          ? null
                          : Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stepLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}