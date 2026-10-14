import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_verification_repository.dart';

/// One row in the left-side verification queue.
class VerificationQueueItem extends StatelessWidget {
  const VerificationQueueItem({
    super.key,
    required this.artisan,
    required this.selected,
    required this.onTap,
  });

  final PendingArtisan artisan;
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
          height: 76,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.secondary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.secondary.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(artisan.fullName),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artisan.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artisan.serviceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _submittedRelative(artisan.submittedAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _compactTimeBadge(artisan.submittedAt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactTimeBadge(DateTime? submitted) {
    if (submitted == null) return const SizedBox.shrink();
    final diff = DateTime.now().difference(submitted);
    final String label;
    if (diff.inHours < 1) {
      label = '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      label = '${diff.inHours}h';
    } else {
      label = '${diff.inDays}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  String _submittedRelative(DateTime? dt) {
    if (dt == null) return 'Submitted recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return 'Submitted ${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return 'Submitted ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return 'Submitted ${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}