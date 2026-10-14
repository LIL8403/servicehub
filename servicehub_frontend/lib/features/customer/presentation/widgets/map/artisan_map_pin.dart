import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../domain/models/artisan_directory_entry.dart';

/// A single map pin. Renders the ServiceHUB shield glyph inside a
/// colored circle whose hue encodes the artisan's verification state.
///
/// Tap is handled internally because `MhjMapsMap` does not forward
/// marker tap events — the pin is wrapped in a GestureDetector as the
/// marker's child widget.
class ArtisanMapPin extends StatelessWidget {
  const ArtisanMapPin({
    super.key,
    required this.artisan,
    required this.isSelected,
    required this.onTap,
  });

  final ArtisanDirectoryEntry artisan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _pinColor();
    final size = isSelected ? 32.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Container(
              width: size + 12,
              height: size + 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: isSelected ? 2 : 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/brand/logo_symbol.svg',
              width: isSelected ? 16 : 12,
              height: isSelected ? 16 : 12,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _pinColor() {
    final status = (artisan.verificationStatus).toLowerCase();
    if (status == 'verified') return AppColors.secondary;
    if (status == 'unverified' || status == 'pending' || status == 'rejected') {
      return AppColors.primary;
    }
    return AppColors.textMuted;
  }
}