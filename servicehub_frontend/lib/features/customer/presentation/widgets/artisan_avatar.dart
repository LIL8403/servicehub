
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_selection_providers.dart';
import '../../domain/models/artisan_summary.dart';

class ArtisanAvatar extends ConsumerWidget {
  const ArtisanAvatar({
    super.key,
    required this.artisan,
    this.size = 56,
    this.showVerifiedBadge = true,
  });

  final ArtisanSummary artisan;
  final double size;
  final bool showVerifiedBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: _buildImage(ref),
            ),
          ),
          if (showVerifiedBadge)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cardLight,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.verified,
                  size: 14,
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(WidgetRef ref) {
    if (!artisan.hasPhoto || artisan.userId.isEmpty) {
      return _initials();
    }

    final asyncBytes = ref.watch(artisanPhotoProvider(artisan.userId));

    return asyncBytes.when(
      loading: () => _initials(),
      error: (_, _) => _initials(),
      data: (bytes) {
        if (bytes == null || bytes.isEmpty) return _initials();
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }

  Widget _initials() {
    final initials = _initialString();
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }

  String _initialString() {
    final f = artisan.firstName.isNotEmpty
        ? artisan.firstName[0]
        : (artisan.name.isNotEmpty ? artisan.name[0] : '?');
    final l = artisan.lastName.isNotEmpty ? artisan.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}