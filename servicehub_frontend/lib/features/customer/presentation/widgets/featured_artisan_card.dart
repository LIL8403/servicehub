import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:servicehub_frontend/ui/core/theme/app_spacing.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_directory_entry.dart';
import '../providers/artisan_selection_providers.dart';

class FeaturedArtisanCard extends ConsumerWidget {
  const FeaturedArtisanCard({
    super.key,
    required this.artisan,
    required this.onTap,
    this.width = 240,
  });

  final ArtisanDirectoryEntry artisan;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      child: Material(
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
                color: artisan.isVerified
                    ? AppColors.secondary.withValues(alpha: 0.35)
                    : AppColors.borderLight,
                width: artisan.isVerified ? 1.2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Avatar + name + title ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Avatar(artisan: artisan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  artisan.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (artisan.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.badgeCheck,
                                  size: 14,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artisan.professionalTitle,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm + 2),

                // ── Rating row ──
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        LucideIcons.star,
                        size: 13,
                        color: i < artisan.ratingAverage.round()
                            ? AppColors.secondary
                            : AppColors.borderLight,
                        fill: i < artisan.ratingAverage.round() ? 1.0 : 0.0,
                      ),
                    const SizedBox(width: 5),
                    Text(
                      artisan.ratingAverage.toStringAsFixed(1),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${artisan.reviewCount})',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Trust pills ──
                Row(
                  children: [
                    _TrustPill(label: '${artisan.completedJobs} jobs'),
                    const SizedBox(width: 6),
                    _TrustPill(
                      label:
                          '${(artisan.responseRate * 100).round()}% response',
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Location line ──
                if (artisan.serviceAreas.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          artisan.serviceAreas.first,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.sm + 2),

                // ── CTA hint ──
                Container(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View profile',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _Avatar extends ConsumerWidget {
  const _Avatar({required this.artisan});
  final ArtisanDirectoryEntry artisan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = _initials(artisan);

    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: artisan.isVerified
              ? AppColors.secondary.withValues(alpha: 0.4)
              : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (!artisan.hasPhoto || artisan.userId.isEmpty) {
      return placeholder;
    }

    final asyncBytes = ref.watch(artisanPhotoProvider(artisan.userId));

    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: asyncBytes.when(
          loading: () => placeholder,
          error: (_, _) => placeholder,
          data: (bytes) {
            if (bytes == null || bytes.isEmpty) return placeholder;
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            );
          },
        ),
      ),
    );
  }

  String _initials(ArtisanDirectoryEntry a) {
    final f = a.firstName.isNotEmpty
        ? a.firstName[0]
        : (a.name.isNotEmpty ? a.name[0] : '?');
    final l = a.lastName.isNotEmpty ? a.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}
