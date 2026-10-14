import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// Renders an events array (from a Payment or Payout) as a vertical
/// timeline. Each event has at least a `status` and `occurred_at`.
class EventTimeline extends StatelessWidget {
  const EventTimeline({super.key, required this.events});

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text(
        'No events recorded.',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < events.length; i++) ...[
          _row(events[i], isLast: i == events.length - 1),
        ],
      ],
    );
  }

  Widget _row(Map<String, dynamic> event, {required bool isLast}) {
    final status = event['status']?.toString() ?? '—';
    final occurredAt = event['occurred_at']?.toString();
    final reason =
        event['reason']?.toString() ?? event['source']?.toString();

    final dotColor = _colorFor(status);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (occurredAt != null)
                      Text(
                        _formatAbsolute(occurredAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
                if (reason != null && reason.isNotEmpty && reason != 'None')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'reason: $reason',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'initiated':
        return AppColors.secondary;
      case 'processing':
      case 'releasing':
      case 'refunding':
        return const Color(0xFF1D4ED8);
      case 'held':
        return const Color(0xFFB45309);
      case 'released':
      case 'paid':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatAbsolute(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '${local.year}-${months[local.month - 1]}-$day $h:$m:$s';
  }
}