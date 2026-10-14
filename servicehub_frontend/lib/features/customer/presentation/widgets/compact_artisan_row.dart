import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_directory_entry.dart';
import '../providers/artisan_selection_providers.dart';

class CompactArtisanRow extends ConsumerWidget {
  const CompactArtisanRow({
    super.key,
    required this.artisan,
    required this.onTap,
    this.distanceLabel,
    this.locationLabel,
  });

  final ArtisanDirectoryEntry artisan;
  final VoidCallback onTap;
  final String? distanceLabel;
  final String? locationLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleParts = [
      ?distanceLabel,
      ?locationLabel,
    ].where((s) => s.isNotEmpty).toList();

    return Material(
      color: AppColors.cardLight,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _Avatar(artisan: artisan),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            size: 13,
                            color: AppColors.secondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artisan.professionalTitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 11,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitleParts.join(' · '),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.star,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        artisan.ratingAverage.toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.textMuted,
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

class _Avatar extends ConsumerWidget {
  const _Avatar({required this.artisan});
  final ArtisanDirectoryEntry artisan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = _initials(artisan);

    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: artisan.isVerified
              ? AppColors.secondary.withValues(alpha: 0.35)
              : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.bodyMedium.copyWith(
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
        width: 48,
        height: 48,
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
