import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A pill showing the account status of a user.
///
/// Only two statuses exist on the backend: active and suspended.
class UserStatusPill extends StatelessWidget {
  const UserStatusPill({super.key, required this.status});

  /// Raw status string — 'active' or 'suspended'.
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _variant();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  (Color, Color, String) _variant() {
    switch (status.toLowerCase()) {
      case 'suspended':
        return (AppColors.warningTint, AppColors.warning, 'Suspended');
      case 'active':
      default:
        return (AppColors.successTint, AppColors.success, 'Active');
    }
  }
}