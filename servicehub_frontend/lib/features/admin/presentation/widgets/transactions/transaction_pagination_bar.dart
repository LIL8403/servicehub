import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// Footer pagination bar used by both Payments and Payouts tables.
class TransactionPaginationBar extends StatelessWidget {
  const TransactionPaginationBar({
    super.key,
    required this.total,
    required this.from,
    required this.to,
    required this.currentPage,
    required this.lastPage,
    required this.itemLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final int total;
  final int from;
  final int to;
  final int currentPage;
  final int lastPage;
  final String itemLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  bool get _canPrevious => currentPage > 1;
  bool get _canNext => currentPage < lastPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Text(
            total == 0
                ? 'No $itemLabel'
                : 'Showing $from to $to of $total $itemLabel',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          _navButton(
            label: 'Previous',
            icon: Icons.chevron_left,
            enabled: _canPrevious,
            onTap: onPrevious,
            iconLeading: true,
          ),
          const SizedBox(width: 16),
          Text(
            'Page $currentPage of $lastPage',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          _navButton(
            label: 'Next',
            icon: Icons.chevron_right,
            enabled: _canNext,
            onTap: onNext,
            iconLeading: false,
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required bool iconLeading,
  }) {
    final color = enabled ? AppColors.secondary : AppColors.textMuted;
    final opacity = enabled ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconLeading) ...[
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight:
                        enabled ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (!iconLeading) ...[
                  const SizedBox(width: 4),
                  Icon(icon, size: 16, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}