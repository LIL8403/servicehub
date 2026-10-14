import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_typography.dart';

enum ArtisanChipTone { neutral, success, warning }

class ArtisanChip extends StatelessWidget {
  const ArtisanChip({
    super.key,
    required this.label,
    this.tone = ArtisanChipTone.neutral,
    this.icon,
    this.animateDot = false,
  });

  final String label;
  final ArtisanChipTone tone;
  final IconData? icon;
  final bool animateDot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ArtisanChipTone.success => (
          const Color(0xFFDCFCE7),
          const Color(0xFF166534),
        ),
      ArtisanChipTone.warning => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
        ),
      ArtisanChipTone.neutral => (
          const Color(0xFFF1F5F9),
          AppColors.primary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animateDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}