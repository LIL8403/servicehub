import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_shadows.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/service_category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final ServiceCategory category;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: AppRadii.borderLg,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected ? AppShadows.shadowLow : AppShadows.shadowNone,
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cream.withValues(alpha: 0.6),
                ),
                child: Center(
                  child: Icon(
                    category.icon,
                    size: 24,
                    color: isSelected
                        ? AppColors.textInverse
                        : AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Chevron
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}