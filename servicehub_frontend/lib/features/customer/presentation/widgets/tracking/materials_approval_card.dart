import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/materials_proposal.dart';
import '../../providers/materials_providers.dart';

/// The customer-side materials approval card.
///
/// Shown when the request is `payment_pending` and the artisan has
/// proposed a material list. Once approved, the card shows a
/// read-only summary with the total the customer committed to.
///
/// Never shown when there is no proposal — materials are optional,
/// and most jobs won't have any.
class MaterialsApprovalCard extends ConsumerWidget {
  const MaterialsApprovalCard({
    super.key,
    required this.requestId,
    required this.proposal,
  });

  final String requestId;
  final MaterialsProposal proposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (proposal.isEmpty) return const SizedBox.shrink();

    final action = ref.watch(materialsActionProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: proposal.isApproved
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.secondary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, proposal.isApproved),
          const SizedBox(height: AppSpacing.md),
          ..._items(proposal.items),
          const Divider(height: 24),
          _totalRow(proposal.estimatedTotal),
          const SizedBox(height: AppSpacing.md),
          if (action.errorMessage != null) ...[
            _errorBanner(action.errorMessage!),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (!proposal.isApproved) _approveButton(context, ref, action),
          if (proposal.isApproved) _approvedFooter(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, bool approved) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: approved
                ? AppColors.successTint
                : AppColors.cream,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                approved ? Icons.check : Icons.inventory_2_outlined,
                size: 12,
                color: approved
                    ? AppColors.success
                    : AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                approved ? 'MATERIALS APPROVED' : 'MATERIALS',
                style: AppTypography.caption.copyWith(
                  color: approved
                      ? AppColors.success
                      : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (approved)
          Text(
            'v${proposal.proposalVersion}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  List<Widget> _items(List<MaterialItem> items) {
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_num(item.quantity)} × ${_money(item.unitCost)} XAF',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_money(item.estimatedCost)} XAF',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _totalRow(double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Materials total',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${_money(total)} XAF',
          style: AppTypography.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _approveButton(
    BuildContext context,
    WidgetRef ref,
    MaterialsActionState action,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: action.isSubmitting
                ? null
                : () => _confirmAndApprove(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textInverse,
              disabledBackgroundColor: AppColors.disabledBg,
              disabledForegroundColor: AppColors.disabledText,
              shape: const StadiumBorder(),
            ),
            child: action.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textInverse,
                      ),
                    ),
                  )
                : Text(
                    'Approve materials',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Once approved, this amount is added to your payment.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _approvedFooter() {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: AppColors.success,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'You approved this materials list. The artisan has been notified.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndApprove(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: Text(
          'Approve materials?',
          style: AppTypography.h4.copyWith(color: AppColors.primary),
        ),
        content: Text(
          'You are approving ${_money(proposal.estimatedTotal)} XAF of '
          'materials. This amount will be added to your payment and '
          'held securely by ServiceHUB until you confirm the job is '
          'finished.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Approve',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(materialsActionProvider.notifier).approve(
          requestId: requestId,
          approvedTotal: proposal.estimatedTotal,
        );
  }

  static String _money(double amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buf.write(',');
      buf.write(rounded[i]);
    }
    return buf.toString();
  }

  static String _num(double n) {
    if (n == n.roundToDouble()) return n.round().toString();
    return n.toStringAsFixed(2);
  }
}