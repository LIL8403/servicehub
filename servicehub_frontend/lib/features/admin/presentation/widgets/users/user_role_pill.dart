import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A small pill representing one role a user has.
///
/// Colors are role-specific:
/// - customer: grey background, muted text
/// - artisan: cream background, navy text
/// - admin: light blue background, deep blue text
class UserRolePill extends StatelessWidget {
  const UserRolePill({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  (Color, Color) _colors(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case 'artisan':
        return (AppColors.cream, AppColors.primary);
      case 'customer':
      default:
        return (const Color(0xFFF1F5F9), AppColors.textSecondary);
    }
  }
}