import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A pill-shaped filter chip that can be toggled on and off.
///
/// When [onClear] is provided and the chip is active, a small close
/// icon appears on the right for clearing the filter.
class CatalogFilterChip extends StatelessWidget {
  const CatalogFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLight,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: active
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: active
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (active && onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}