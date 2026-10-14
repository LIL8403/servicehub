import 'package:flutter/material.dart';
import 'package:servicehub_frontend/l10n/app_localizations.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_category.dart';

class MapFilterChips extends StatelessWidget {
  const MapFilterChips({
    super.key,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  /// `null` means "All".
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: l10n.mapFilterAll,
            active: selectedCategoryId == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final category in ServiceCategories.all) ...[
            _Chip(
              label: _labelForSlug(l10n, category.id),
              active: selectedCategoryId == category.id,
              onTap: () => onChanged(category.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _labelForSlug(AppLocalizations l10n, String slug) {
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
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: active ? AppColors.textInverse : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
