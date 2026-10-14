import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_shadows.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';


/// The large status card below the glance card.
///
/// Renders an icon in a tinted circle, a bold title, and a short body
/// message. The `tone` controls the accent colour of the icon circle.
enum StatusHeroTone { neutral, waiting, success, warning, error }

class StatusHeroCard extends StatelessWidget {
  const StatusHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.tone = StatusHeroTone.neutral,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final StatusHeroTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (circleBg, iconColor) = _toneColors(tone);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }

  (Color, Color) _toneColors(StatusHeroTone tone) {
    switch (tone) {
      case StatusHeroTone.waiting:
        return (AppColors.cream, AppColors.secondary);
      case StatusHeroTone.success:
        return (AppColors.successTint, AppColors.success);
      case StatusHeroTone.warning:
        return (AppColors.warningTint, AppColors.warning);
      case StatusHeroTone.error:
        return (AppColors.errorTint, AppColors.error);
      case StatusHeroTone.neutral:
        return (AppColors.neutralBadgeBg, AppColors.primary);
    }
  }
}