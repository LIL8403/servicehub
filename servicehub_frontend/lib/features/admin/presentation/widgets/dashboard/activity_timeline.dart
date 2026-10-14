import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_dashboard_repository.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({
    super.key,
    required this.activity,
    required this.onViewAll,
  });

  final List<DashboardActivity> activity;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Recent activity',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            Text(
              'Last 24 hours',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: activity.isEmpty
              ? Text(
                  'No recent activity.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < activity.length; i++) ...[
                      _itemRow(activity[i]),
                      if (i < activity.length - 1)
                        const SizedBox(height: 16),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onViewAll,
            iconAlignment: IconAlignment.end,
            icon: const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.secondary,
            ),
            label: Text(
              'View all activity',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemRow(DashboardActivity a) {
    final (icon, bg, fg) = _iconFor(a.eventType);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: fg),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _describe(a),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _relativeTime(a.occurredAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (IconData, Color, Color) _iconFor(String eventType) {
    if (eventType.contains('artisan') &&
        eventType.contains('approved')) {
      return (Icons.check, const Color(0xFFDCFCE7), const Color(0xFF166534));
    }
    if (eventType.contains('artisan') &&
        eventType.contains('rejected')) {
      return (Icons.close, const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
    }
    if (eventType.startsWith('dispute')) {
      return (Icons.gavel_outlined, const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
    }
    if (eventType.startsWith('payment')) {
      return (Icons.payments_outlined, const Color(0xFFDCFCE7), const Color(0xFF166534));
    }
    if (eventType.startsWith('account')) {
      return (Icons.person_outline, AppColors.cream, AppColors.primary);
    }
    if (eventType.startsWith('platform')) {
      return (Icons.settings_outlined, const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
    }
    return (Icons.history, AppColors.cream, AppColors.primary);
  }

  String _describe(DashboardActivity a) {
    final actor = a.actorName ?? 'System';
    switch (a.eventType) {
      case 'platform.commission_rate_updated':
        final old = a.metadata['old_rate'];
        final neu = a.metadata['new_rate'];
        return '$actor changed commission rate from '
            '${_percent(old)} to ${_percent(neu)}';
      case 'account.status_changed':
        final status = a.metadata['status']?.toString() ?? 'updated';
        return '$actor set an account to "$status"';
      case 'payment.status_checked':
        final provider = a.metadata['provider']?.toString() ?? 'provider';
        return '$actor checked a $provider payment status';
      case 'dispute.resolution_executed':
        return '$actor executed a dispute resolution';
      case 'dispute.opened':
        return '$actor opened a dispute';
      case 'artisan.verified':
        return '$actor approved an artisan';
      default:
        return '$actor performed ${_humanizeEvent(a.eventType)}';
    }
  }

  String _humanizeEvent(String event) {
    final parts = event.split('.');
    if (parts.length == 2) {
      return '${parts[1].replaceAll('_', ' ')} on ${parts[0]}';
    }
    return event.replaceAll('_', ' ');
  }

  String _percent(dynamic value) {
    if (value is num) {
      return '${(value * 100).toStringAsFixed(2)}%';
    }
    return '—';
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inMinutes} min ago';
  }
}