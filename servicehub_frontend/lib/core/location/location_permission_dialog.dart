import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_radii.dart';
import '../../ui/core/theme/app_typography.dart';

/// Shows a friendly explanation before the OS permission prompt fires.
/// Returns true when the user taps "Allow", false on cancel.
Future<bool> showLocationPrePermissionDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
      title: Text(
        'Find artisans near you',
        style: AppTypography.h4.copyWith(color: AppColors.primary),
      ),
      content: Text(
        'ServiceHUB uses your location to show verified artisans close to '
        'you and sort results by distance. We never share your exact '
        'position with anyone.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Not now',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Allow',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shown when the user has permanently denied permission — the only
/// recovery path is the OS settings screen.
Future<void> showLocationSettingsDialog(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
      title: Text(
        'Location is off',
        style: AppTypography.h4.copyWith(color: AppColors.primary),
      ),
      content: Text(
        'To sort artisans by distance, enable location for ServiceHUB in '
        'your device settings.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Open settings',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  if (go == true) {
    await openAppSettings();
  }
}