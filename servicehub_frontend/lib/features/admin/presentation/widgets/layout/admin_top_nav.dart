import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class AdminTopNav extends StatelessWidget {
  const AdminTopNav({
    super.key,
    required this.adminName,
    required this.adminEmail,
    required this.currentPath,
  });

  final String adminName;
  final String adminEmail;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _breadcrumb(),
          const Spacer(),
          _languagePill(),
          const SizedBox(width: 24),
          _notificationButton(),
          const SizedBox(width: 24),
          Container(
            width: 1,
            height: 24,
            color: AppColors.borderLight,
          ),
          const SizedBox(width: 24),
          _profileBlock(),
        ],
      ),
    );
  }

  Widget _breadcrumb() {
    final crumbs = _crumbsForPath(currentPath);
    return Row(
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            crumbs[i],
            style: AppTypography.bodySmall.copyWith(
              color: i == crumbs.length - 1
                  ? AppColors.primary
                  : AppColors.textMuted,
              fontWeight:
                  i == crumbs.length - 1 ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  List<String> _crumbsForPath(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty || parts.first != 'admin') {
      return const ['Admin'];
    }

    final crumbs = <String>['Admin'];
    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      final label = part
          .split('-')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
      crumbs.add(label);
    }
    return crumbs;
  }

  Widget _languagePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          Text(
            'EN',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '|',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.borderLight,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            'FR',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.expand_more,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _notificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_outlined,
          size: 24,
          color: AppColors.primary,
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileBlock() {
    final initials = _initials(adminName);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              adminName,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              adminEmail,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.expand_more,
          size: 16,
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.isEmpty
          ? 'A'
          : parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}