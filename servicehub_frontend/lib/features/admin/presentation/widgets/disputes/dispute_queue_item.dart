import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_dispute_repository.dart';
import 'status_pill.dart';

class DisputeQueueItem extends StatelessWidget {
  const DisputeQueueItem({
    super.key,
    required this.dispute,
    required this.selected,
    required this.onTap,
  });

  final DisputeSummary dispute;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.cream : AppColors.cardLight,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.bgLight,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.secondary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dispute.reporterName ?? 'Unknown reporter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DisputeStatusPill(status: dispute.status, compact: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dispute.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.handyman_outlined,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dispute.serviceName ?? 'Service',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _timeBadge(dispute.createdAt),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeBadge(DateTime? dt) {
    if (dt == null) return const SizedBox.shrink();
    final diff = DateTime.now().difference(dt);
    final String label;
    final Color bg;
    final Color fg;

    if (diff.inDays >= 1) {
      label = '${diff.inDays}d';
      bg = const Color(0xFFF1F5F9);
      fg = AppColors.textMuted;
    } else if (diff.inHours >= 1) {
      label = '${diff.inHours}h';
      bg = const Color(0xFFF1F5F9);
      fg = AppColors.textMuted;
    } else {
      label = '${diff.inMinutes}m';
      bg = AppColors.warningTint;
      fg = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
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
}