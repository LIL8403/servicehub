import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// Photo section for the create-request wizard.
///
/// Shows the two upload buttons and, when photos are selected, a
/// horizontal thumbnail strip with remove buttons.
///
/// Enforces a max of 5 photos (matches `images` => max:5 in
/// StoreServiceRequestRequest).
class PhotoUploadSection extends StatelessWidget {
  const PhotoUploadSection({
    super.key,
    required this.photos,
    required this.onTakePhoto,
    required this.onPickFromGallery,
    required this.onRemove,
    required this.takePhotoLabel,
    required this.galleryLabel,
    required this.maxPhotos,
    this.inlineError,
  });

  final List<XFile> photos;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFromGallery;
  final void Function(XFile photo) onRemove;
  final String takePhotoLabel;
  final String galleryLabel;
  final int maxPhotos;
  final String? inlineError;

  bool get _atLimit => photos.length >= maxPhotos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _UploadButton(
                icon: Icons.photo_camera_outlined,
                label: takePhotoLabel,
                onTap: _atLimit ? null : onTakePhoto,
                disabled: _atLimit,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: _UploadButton(
                icon: Icons.photo_library_outlined,
                label: galleryLabel,
                onTap: _atLimit ? null : onPickFromGallery,
                disabled: _atLimit,
              ),
            ),
          ],
        ),

        if (photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => _ThumbnailTile(
                photo: photos[i],
                onRemove: () => onRemove(photos[i]),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.createRequestStep1PhotoCount(photos.length, maxPhotos),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),

        if (inlineError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  inlineError!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback onRemove;

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(photo.path, fit: BoxFit.cover);
    }
    return Image.file(File(photo.path), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppRadii.borderMd,
          child: SizedBox(width: 92, height: 92, child: _buildImage()),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.textInverse,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Small helper so we don't import dart:io unconditionally on web.
// ignore: prefer_void_to_null

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? AppColors.textMuted : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: AppRadii.borderLg,
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
