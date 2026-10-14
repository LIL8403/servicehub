import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// The 3-step progress indicator shown at the top of every verification
/// sub-screen (Identity, ID document, Selfie).
///
/// [activeStep] is 0-based: 0 = Identity, 1 = Professional, 2 = Documents.
class VerificationStepIndicator extends StatelessWidget {
  const VerificationStepIndicator({
    super.key,
    required this.activeStep,
    this.completedSteps = const {},
    this.labels = const ['Identity', 'Professional', 'Documents'],
  });

  final int activeStep;
  final Set<int> completedSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(labels.length, (i) {
              final isActive = i == activeStep;
              final isComplete = completedSteps.contains(i);
              return Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isComplete) ...[
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            labels[i],
                            style: AppTypography.bodySmall.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.secondary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 4,
              child: Row(
                children: List.generate(labels.length, (i) {
                  final isFilled = i <= activeStep;
                  return Expanded(
                    child: Container(
                      color: isFilled
                          ? AppColors.secondary
                          : AppColors.borderLight,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
