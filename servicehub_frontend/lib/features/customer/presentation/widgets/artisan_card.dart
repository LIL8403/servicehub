import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_summary.dart';
import 'artisan_avatar.dart';
import 'artisan_chip.dart';

class ArtisanCard extends StatelessWidget {
  const ArtisanCard({
    super.key,
    required this.artisan,
    required this.onTap,
  });

  final ArtisanSummary artisan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderLg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArtisanAvatar(artisan: artisan, size: 56),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                artisan.name,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artisan.professionalTitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              artisan.ratingAverage.toStringAsFixed(1),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '· ${artisan.reviewCount} ${l10n.artisanReviewsSuffix}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (artisan.distanceLabel != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '· ${artisan.distanceLabel}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ArtisanChip(
                    label: artisan.experienceLabel,
                    tone: ArtisanChipTone.neutral,
                  ),
                  if (artisan.respondsFast)
                    ArtisanChip(
                      label: l10n.artisanChipRespondsFast,
                      tone: ArtisanChipTone.success,
                      animateDot: true,
                    ),
                  ArtisanChip(
                    label: artisan.jobsLabel,
                    tone: ArtisanChipTone.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}