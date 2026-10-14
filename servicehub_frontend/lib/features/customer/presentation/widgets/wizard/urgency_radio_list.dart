import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/enums/urgency_level.dart';

class UrgencyRadioList extends StatelessWidget {
  const UrgencyRadioList({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final UrgencyLevel? selected;
  final List<UrgencyOption> options;
  final ValueChanged<UrgencyLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _UrgencyRow(
            option: options[i],
            isSelected: selected == options[i].value,
            onTap: () => onChanged(options[i].value),
          ),
          if (i < options.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class UrgencyOption {
  const UrgencyOption({
    required this.value,
    required this.label,
    required this.description,
  });

  final UrgencyLevel value;
  final String label;
  final String description;
}

class _UrgencyRow extends StatelessWidget {
  const _UrgencyRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final UrgencyOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cream.withValues(alpha: 0.40)
              : AppColors.cardLight,
          borderRadius: AppRadii.borderLg,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}