import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A clickable preview tile for a document image.
///
/// If [hasImage] is false, shows a "not uploaded" placeholder and the
/// tap is disabled.
class VerificationImageTile extends StatelessWidget {
  const VerificationImageTile({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    required this.hasImage,
    required this.onTap,
    this.filename,
  });

  final String label;
  final double width;
  final double height;
  final bool hasImage;
  final VoidCallback onTap;
  final String? filename;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: hasImage ? onTap : null,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              alignment: Alignment.center,
              child: hasImage
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Click to view',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        if (filename != null && filename!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            filename!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Not uploaded',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}