import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class EvidenceTile extends StatelessWidget {
  const EvidenceTile({
    super.key,
    required this.evidence,
    required this.onTap,
  });

  final Map<String, dynamic> evidence;
  final VoidCallback onTap;

  bool get _isImage {
    final mime = evidence['mime_type']?.toString() ?? '';
    return mime.startsWith('image/');
  }

  String get _filename => evidence['name']?.toString() ?? 'file';

  String get _sizeLabel {
    final size = evidence['size'];
    if (size is num) {
      final bytes = size.toInt();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Container(
                width: 200,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isImage
                          ? Icons.image_outlined
                          : Icons.description_outlined,
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _sizeLabel,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}