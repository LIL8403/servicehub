import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/earnings_summary.dart';

class EarningsBalanceCard extends StatelessWidget {
  const EarningsBalanceCard({super.key, required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadii.borderLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL EARNED',
            style: AppTypography.caption.copyWith(
              color: AppColors.textInverse.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _money(summary.paid),
                style: AppTypography.h1.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'XAF',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textInverse.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'PENDING',
                  value: summary.pending,
                  tint: AppColors.cream,
                  onTint: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: _Stat(
                  label: 'COMMISSION',
                  value: summary.lifetimeCommission,
                  tint: AppColors.textInverse.withValues(alpha: 0.1),
                  onTint: AppColors.textInverse.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _money(int amount) {
    final s = amount.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return amount < 0 ? '-${buf.toString()}' : buf.toString();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.tint,
    required this.onTint,
  });

  final String label;
  final int value;
  final Color tint;
  final Color onTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(color: tint, borderRadius: AppRadii.borderMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: onTint,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${EarningsBalanceCard._money(value)} XAF',
            style: AppTypography.bodyMedium.copyWith(
              color: onTint == AppColors.secondary ? AppColors.primary : onTint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
