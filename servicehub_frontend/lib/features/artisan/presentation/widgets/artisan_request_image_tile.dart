import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/models/service_request.dart';
import '../providers/artisan_request_providers.dart';

/// A single photo attachment on a service request.
///
/// Fetches the image bytes through the authenticated endpoint and
/// renders a tappable thumbnail. Tapping opens a full-screen viewer.
class ArtisanRequestImageTile extends ConsumerWidget {
  const ArtisanRequestImageTile({
    super.key,
    required this.requestId,
    required this.image,
    this.size = 72,
  });

  final String requestId;
  final ImageAttachment image;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      requestImageBytesProvider(
        (requestId: requestId, imageId: image.id),
      ),
    );

    return GestureDetector(
      onTap: () => _openFullScreen(context, ref),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: AppRadii.borderMd,
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: async.when(
          loading: () => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => _placeholder(),
          data: (bytes) {
            if (bytes == null || bytes.isEmpty) return _placeholder();
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

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.broken_image_outlined,
          size: 18,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            image.name,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _openFullScreen(BuildContext context, WidgetRef ref) {
    final async = ref.read(
      requestImageBytesProvider(
        (requestId: requestId, imageId: image.id),
      ),
    );

    final bytes = async.valueOrNull;
    if (bytes == null || bytes.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
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