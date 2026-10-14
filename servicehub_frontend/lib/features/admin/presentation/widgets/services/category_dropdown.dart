import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../providers/admin_category_providers.dart';

/// A dropdown selector for choosing a service category.
///
/// Renders as a bordered selector with the currently selected
/// category name and a chevron. Tapping opens a Material dropdown
/// menu with all categories.
class CategoryDropdown extends ConsumerWidget {
  const CategoryDropdown({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return categoriesAsync.when(
      loading: () => _shell(
        child: Text(
          'Loading categories...',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ),
      error: (_, _) => _shell(
        child: Text(
          'Could not load categories',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.error,
            fontSize: 14,
          ),
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return _shell(
            child: Text(
              'No categories available — create one first',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          );
        }

        final selected = categories.firstWhere(
          (c) => c.id == selectedId,
          orElse: () => categories.first,
        );
        final effectiveId = selectedId ?? selected.id;

        return PopupMenuButton<String>(
          tooltip: '',
          color: AppColors.cardLight,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          offset: const Offset(0, 48),
          onSelected: onChanged,
          itemBuilder: (ctx) => [
            for (final c in categories)
              PopupMenuItem<String>(
                value: c.id,
                height: 40,
                child: Text(
                  c.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: c.id == effectiveId
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
          child: _shell(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}