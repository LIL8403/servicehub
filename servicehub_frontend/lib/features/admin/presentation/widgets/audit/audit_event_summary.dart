import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_audit_log_repository.dart';

/// Renders a one-line summary of an audit event's metadata, tailored
/// to the event type. Falls back to a key-value summary for unknown
/// event types.
class AuditEventSummary extends StatelessWidget {
  const AuditEventSummary({super.key, required this.log});

  final AdminAuditLog log;

  @override
  Widget build(BuildContext context) {
    final summary = _buildSummary();
    return Text(
      summary,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  String _buildSummary() {
    final m = log.metadata;
    switch (log.eventType) {
      case 'platform.commission_rate_updated':
        return '${_percent(m['old_rate'])} → ${_percent(m['new_rate'])}';
      case 'account.status_changed':
        return '${m['previous_status'] ?? '—'} → ${m['status'] ?? '—'}';
      case 'dispute.resolution_initiated':
        final decision = m['decision'] ?? 'resolution';
        final refund = m['customer_refund_amount'];
        return refund != null
            ? '$decision (${_xaf(refund)} refund)'
            : '$decision';
      case 'dispute.resolution_cancelled':
        return 'cancelled: ${m['reason'] ?? 'no reason'}';
      case 'dispute.resolution_executed':
        return 'executed (${m['decision'] ?? 'resolution'})';
      case 'payment.status_checked':
        return 'provider: ${m['provider'] ?? '—'}';
      default:
        final keys = m.keys.take(2).join(', ');
        return keys.isEmpty ? '—' : keys;
    }
  }

  String _percent(dynamic v) {
    if (v is num) return '${(v * 100).toStringAsFixed(2)}%';
    return '—';
  }

  String _xaf(dynamic v) {
    if (v is num) {
      return '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';
    }
    return '—';
  }
}