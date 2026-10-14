import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class UrgencyPill extends StatelessWidget {
  const UrgencyPill({super.key, required this.urgency});

  final String? urgency;

  @override
  Widget build(BuildContext context) {
    if (urgency == null || urgency!.isEmpty) return const SizedBox.shrink();
    final (bg, fg) = _variant();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _titleCase(urgency!),
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  (Color, Color) _variant() {
    switch (urgency!.toLowerCase()) {
      case 'high':
        return (AppColors.errorTint, AppColors.error);
      case 'medium':
        return (AppColors.warningTint, AppColors.warning);
      case 'low':
        return (const Color(0xFFF1F5F9), AppColors.textMuted);
      default:
        return (const Color(0xFFF1F5F9), AppColors.textMuted);
    }
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}