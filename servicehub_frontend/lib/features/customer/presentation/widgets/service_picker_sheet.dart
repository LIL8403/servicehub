import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/service_catalog_providers.dart';

/// Shows a bottom sheet listing all services that belong to the given
/// category. Returns the chosen `ServiceRef`, or null if the user
/// dismissed the sheet.
///
/// Used from the Discover tab and from the request wizard when the
/// customer needs to pick a specific service (not just a category).
Future<ServiceRef?> showServicePickerSheet(
  BuildContext context, {
  required String categorySlug,
  ServiceRef? current,
}) {
  return showModalBottomSheet<ServiceRef>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        _ServicePickerSheet(categorySlug: categorySlug, current: current),
  );
}

class _ServicePickerSheet extends ConsumerWidget {
  const _ServicePickerSheet({required this.categorySlug, this.current});

  final String categorySlug;
  final ServiceRef? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(serviceCatalogProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Which service do you need?',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Flexible(
              child: catalogAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Could not load services. Please try again.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                data: (catalog) {
                  final matches = catalog
                      .where((s) => s.categorySlug == categorySlug)
                      .toList();

                  if (matches.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'No services are currently configured for this '
                        'category. Please try another category.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final service = matches[index];
                      final selected = current?.id == service.id;

                      return Material(
                        color: selected
                            ? AppColors.cream.withValues(alpha: 0.5)
                            : AppColors.cardLight,
                        borderRadius: AppRadii.borderLg,
                        child: InkWell(
                          borderRadius: AppRadii.borderLg,
                          onTap: () => Navigator.of(context).pop(service),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              borderRadius: AppRadii.borderLg,
                              border: Border.all(
                                color: selected
                                    ? AppColors.secondary
                                    : AppColors.borderLight,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    service.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: AppColors.secondary,
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
