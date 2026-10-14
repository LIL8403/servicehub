import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_typography.dart';

/// Accent tints for quick action tiles. Determines the icon-circle
/// background and the icon color so tiles carry meaning, not just
/// decoration.
enum QuickActionAccent {
  /// Neutral actions (nav, browse, discover). Navy icon on cream.
  primary,

  /// Positive actions (payments received, completed). Green on green tint.
  success,

  /// Attention actions (verification, pending). Amber on amber tint.
  warning,

  /// Featured actions (book a service, upgrade). Ochre on cream.
  secondary,
}

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.accent = QuickActionAccent.primary,
  });

  /// A Lucide icon (from `LucideIcons`). Do NOT pass a Material icon —
  /// the design system uses Lucide for all interactive surfaces.
  final IconData icon;

  final String label;

  /// Optional one-line context below the label. Keep it short — the
  /// tile is narrow, and long text gets truncated.
  final String? subtitle;

  final QuickActionAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _accentTint(accent);

    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderLg,
        splashColor: tint.fg.withValues(alpha: 0.08),
        highlightColor: tint.fg.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tint.fg.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: tint.fg),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _AccentTint _accentTint(QuickActionAccent accent) {
    switch (accent) {
      case QuickActionAccent.primary:
        return const _AccentTint(bg: AppColors.cream, fg: AppColors.primary);
      case QuickActionAccent.secondary:
        return const _AccentTint(bg: AppColors.cream, fg: AppColors.secondary);
      case QuickActionAccent.success:
        return const _AccentTint(
          bg: AppColors.successTint,
          fg: AppColors.success,
        );
      case QuickActionAccent.warning:
        return const _AccentTint(
          bg: AppColors.warningTint,
          fg: AppColors.warning,
        );
    }
  }
}

class _AccentTint {
  const _AccentTint({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}
