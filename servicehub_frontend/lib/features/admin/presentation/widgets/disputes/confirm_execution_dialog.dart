import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../catalog/modal_shell.dart';

Future<bool?> showConfirmExecutionDialog(
  BuildContext context, {
  required Map<String, dynamic> pendingResolution,
}) {
  return showModalShell<bool>(
    context: context,
    title: 'Confirm resolution?',
    child: _ConfirmForm(pendingResolution: pendingResolution),
  );
}

class _ConfirmForm extends StatelessWidget {
  const _ConfirmForm({required this.pendingResolution});

  final Map<String, dynamic> pendingResolution;

  @override
  Widget build(BuildContext context) {
    final decision = pendingResolution['decision']?.toString() ?? '—';
    final refund = (pendingResolution['customer_refund_amount'] as num?)?.toInt() ?? 0;
    final gross = (pendingResolution['artisan_gross_release'] as num?)?.toInt() ?? 0;
    final commission = (pendingResolution['commission_amount'] as num?)?.toInt() ?? 0;
    final net = (pendingResolution['artisan_net_amount'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _row('Decision', _decisionLabel(decision)),
              const SizedBox(height: 8),
              _row('Customer refund', _formatXaf(refund)),
              const SizedBox(height: 8),
              _row('Artisan gross', _formatXaf(gross)),
              const SizedBox(height: 8),
              _row('Commission', _formatXaf(commission)),
              const SizedBox(height: 8),
              _row('Artisan net', _formatXaf(net)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_outlined,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This will execute the financial operations. The refund/release cannot be undone. If you need to change the decision, use Cancel resolution instead.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 40),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm and execute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(0, 40),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _decisionLabel(String key) {
    switch (key) {
      case 'refund_customer':
        return 'Refund customer';
      case 'release_artisan':
        return 'Release to artisan';
      case 'split_resolution':
        return 'Split resolution';
      case 'hold':
        return 'Hold for investigation';
      default:
        return key;
    }
  }

  String _formatXaf(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';
}