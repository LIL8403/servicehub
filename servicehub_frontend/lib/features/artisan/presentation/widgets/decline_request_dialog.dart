import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

/// Shows a bottom sheet that collects an optional reason for declining a
/// request. Returns the trimmed reason string, empty string for "no reason",
/// or null if the user cancelled.
Future<String?> showDeclineRequestDialog(BuildContext context) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.primaryDark.withValues(alpha: 0.6),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _DeclineRequestSheet(controller: controller),
    ),
  ).then((value) {
    controller.dispose();
    return value;
  });
}

class _DeclineRequestSheet extends StatelessWidget {
  const _DeclineRequestSheet({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Decline this request?',
              style: AppTypography.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The customer will be notified and can choose another artisan. '
              'A short reason helps them understand, but is optional.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 500,
              autofocus: true,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                counterText: '',
                filled: true,
                fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.all(AppSpacing.sm + 2),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadii.borderMd,
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadii.borderMd,
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  controller.text.trim(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Decline request',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Keep request',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}