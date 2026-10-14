import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_summary.dart';
import '../../domain/models/eligible_artisans_response.dart';
import 'artisan_avatar.dart';
import 'artisan_chip.dart';

/// A highlighted ochre-tinted card used inside the AI-recommended section.
///
/// Differs from the plain ArtisanCard in three ways:
/// 1. Renders a match score badge on the top-right corner.
/// 2. Renders a "Why this pick" rationale box under the chips.
/// 3. Uses an ochre border and a subtle warm background.
class AiRecommendedCard extends StatelessWidget {
  const AiRecommendedCard({
    super.key,
    required this.artisan,
    required this.recommendation,
    required this.onTap,
  });

  final ArtisanSummary artisan;
  final AiRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.4),
              width: 1.5,
            ),
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
                            _MatchScoreBadge(score: recommendation.matchScore),
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
                              '· ${artisan.reviewCount} reviews',
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
                    const ArtisanChip(
                      label: 'Responds fast',
                      tone: ArtisanChipTone.success,
                      animateDot: true,
                    ),
                  ArtisanChip(
                    label: artisan.jobsLabel,
                    tone: ArtisanChipTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _WhyThisPickBox(reason: recommendation.reason),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchScoreBadge extends StatelessWidget {
  const _MatchScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        '$score% MATCH',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textInverse,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _WhyThisPickBox extends StatelessWidget {
  const _WhyThisPickBox({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 15,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}