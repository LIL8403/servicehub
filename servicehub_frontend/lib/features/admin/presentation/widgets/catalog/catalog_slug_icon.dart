import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';

/// A small square icon chip that picks a Material icon based on the
/// entity's slug. Falls back to a generic icon for unknown slugs.
///
/// The map is hardcoded because the admin doesn't choose icons in the
/// MVP. When we later add an icon picker, this widget will read the
/// `icon` field instead.
class CatalogSlugIcon extends StatelessWidget {
  const CatalogSlugIcon({
    super.key,
    required this.slug,
    this.size = 32,
    this.iconSize = 18,
  });

  final String slug;
  final double size;
  final double iconSize;

  static const _iconMap = <String, IconData>{
    'plumbing': Icons.plumbing_outlined,
    'electrical': Icons.bolt_outlined,
    'carpentry': Icons.carpenter_outlined,
    'painting': Icons.format_paint_outlined,
    'masonry': Icons.foundation_outlined,
    'mechanics': Icons.car_repair_outlined,
    // Common alternate slugs
    'electricity': Icons.bolt_outlined,
    'woodwork': Icons.carpenter_outlined,
    'auto': Icons.car_repair_outlined,
    'automotive': Icons.car_repair_outlined,
    'repair': Icons.build_outlined,
    'cleaning': Icons.cleaning_services_outlined,
    'moving': Icons.local_shipping_outlined,
  };

  IconData get _icon =>
      _iconMap[slug.toLowerCase()] ?? Icons.handyman_outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(_icon, size: iconSize, color: AppColors.primary),
    );
  }
}