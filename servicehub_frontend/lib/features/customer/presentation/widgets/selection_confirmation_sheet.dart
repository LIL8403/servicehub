import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_summary.dart';

/// Returns true if the customer confirmed.
Future<bool> showSelectionConfirmationSheet(
  BuildContext context, {
  required ArtisanSummary artisan,
  required String serviceTitle,
  required String locationLabel,
  required String preferredDateLabel,
  required bool isSubmitting,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.primaryDark.withValues(alpha: 0.6),
    builder: (context) => _SelectionConfirmationSheet(
      artisan: artisan,
      serviceTitle: serviceTitle,
      locationLabel: locationLabel,
      preferredDateLabel: preferredDateLabel,
      isSubmitting: isSubmitting,
    ),
  );

  return result ?? false;
}

class _SelectionConfirmationSheet extends StatelessWidget {
  const _SelectionConfirmationSheet({
    required this.artisan,
    required this.serviceTitle,
    required this.locationLabel,
    required this.preferredDateLabel,
    required this.isSubmitting,
  });

  final ArtisanSummary artisan;
  final String serviceTitle;
  final String locationLabel;
  final String preferredDateLabel;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cream.withValues(alpha: 0.6),
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Text(
              l10n.selectionConfirmationTitle(artisan.firstName),
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.selectionConfirmationBody,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: AppRadii.borderLg,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _row(
                    l10n.selectionConfirmationRequestLabel,
                    '$serviceTitle · $locationLabel',
                  ),
                  const Divider(height: 18),
                  _row(
                    l10n.selectionConfirmationDateLabel,
                    preferredDateLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textInverse,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.selectionConfirmationSend,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textInverse,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: AppColors.textInverse,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  l10n.selectionConfirmationCancel,
                  style: AppTypography.bodyLarge.copyWith(
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

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}