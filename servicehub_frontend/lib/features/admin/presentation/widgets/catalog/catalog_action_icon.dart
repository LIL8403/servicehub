import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';

/// A small icon button used in the Actions column of catalog tables.
///
/// When [disabled] is true, the icon renders muted and shows a tooltip
/// with [disabledReason] on hover.
class CatalogActionIcon extends StatelessWidget {
  const CatalogActionIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.disabled = false,
    this.disabledReason,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final bool disabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final fg = disabled
        ? AppColors.textMuted.withValues(alpha: 0.4)
        : (color ?? AppColors.textMuted);

    final button = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: fg),
    );

    final effectiveTooltip =
        disabled ? (disabledReason ?? tooltip) : tooltip;

    if (disabled) {
      return Tooltip(
        message: effectiveTooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: button,
      );
    }

    return Tooltip(
      message: effectiveTooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: AppColors.bgLight,
          onTap: onTap,
          child: button,
        ),
      ),
    );
  }
}