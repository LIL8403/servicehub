import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_service_request_repository.dart';
import 'service_request_status_pill.dart';

Future<void> showServiceRequestDetailDialog(
  BuildContext context, {
  required AdminServiceRequest request,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.5),
    useRootNavigator: false,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.cardLight,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 700,
        ),
        child: _Body(request: request),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.request});

  final AdminServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borderLight,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summary(),
                const SizedBox(height: 24),
                _sectionLabel('SPECIFICATION & ALLOCATION'),
                const SizedBox(height: 8),
                _detailsGrid(),
                const SizedBox(height: 24),
                _sectionLabel('STATUS HISTORY'),
                const SizedBox(height: 12),
                _timeline(),
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borderLight,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderLight),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.assignment_outlined,
              size: 18,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Request details',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'REQ #${request.shortId}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ServiceRequestStatusPill(status: request.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsGrid() {
    final schedule = request.preferredSchedule ?? const {};
    final preferredDate = schedule['date']?.toString();
    final preferredWindow = schedule['window']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _kv('Customer', request.customerName ?? '—'),
          _kv('Service', request.serviceName ?? '—'),
          _kv('Assigned artisan', request.artisanName ?? '—'),
          _kv('Location',
              request.locationLabel ?? request.formattedAddress ?? '—'),
          _kv('Preferred date',
              preferredDate != null && preferredDate.isNotEmpty
                  ? _formatDate(preferredDate)
                  : '—'),
          _kv('Preferred window',
              preferredWindow ?? '—'),
          _kv('Urgency', request.urgency ?? '—'),
          _kv('Matching attempts', '${request.matchingAttempts}',
              isLast: true),
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline() {
    final history = request.statusHistory;
    if (history.isEmpty) {
      return Text(
        'No status history recorded.',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++)
            _timelineRow(history[i], isLast: i == history.length - 1),
        ],
      ),
    );
  }

  Widget _timelineRow(Map<String, dynamic> event, {required bool isLast}) {
    final status = event['status']?.toString() ?? '—';
    final occurredAt = event['occurred_at']?.toString();
    final eventName = event['event']?.toString();
    final reason = event['reason']?.toString();

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
                color: _colorFor(status),
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
                        _formatDateTime(occurredAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
                if (eventName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'event: $eventName'
                    '${reason != null && reason.isNotEmpty ? ' · reason: $reason' : ''}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'disputed':
      case 'no_artisan_available':
        return AppColors.error;
      case 'booked':
      case 'in_progress':
      case 'awaiting_confirmation':
        return const Color(0xFF1D4ED8);
      case 'pending_artisan_response':
      case 'awaiting_artisan_selection':
      case 'artisan_approved':
        return const Color(0xFFB45309);
      default:
        return AppColors.textMuted;
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 0.6,
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateTime(String iso) {
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
    return '${local.year}-${months[local.month - 1]}-$day $h:$m';
  }
}