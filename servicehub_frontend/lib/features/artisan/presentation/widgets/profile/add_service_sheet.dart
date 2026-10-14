import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../../customer/presentation/providers/service_catalog_providers.dart';

/// Bottom sheet that lets the artisan pick a service to add.
///
/// Shows the full catalog minus whatever is already selected. Returns
/// the chosen [ServiceRef] via Navigator.pop, or null if cancelled.
Future<ServiceRef?> showAddServiceSheet(
  BuildContext context, {
  required List<ServiceRef> catalog,
  required Set<String> alreadySelected,
}) {
  final available = catalog
      .where((s) => !alreadySelected.contains(s.id))
      .toList(growable: false);

  return showModalBottomSheet<ServiceRef>(
    context: context,
    backgroundColor: AppColors.cardLight,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add a service',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick the trade you offer to customers.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: Text(
                    'You have added every available service.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: available.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final service = available[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, service),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm + 4,
                            horizontal: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.cream,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.work_outline,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(
                                width: AppSpacing.sm + AppSpacing.xs,
                              ),
                              Expanded(
                                child: Text(
                                  service.name.isEmpty
                                      ? 'Unknown service'
                                      : service.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
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
                ),
              ),
          ],
        ),
      ),
    ),
  );
}