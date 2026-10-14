import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

class EarningsSummaryCard extends StatelessWidget {
  const EarningsSummaryCard({
    super.key,
    this.thisWeekAmount = 0,
    this.jobsDone = 0,
    this.rating = 0,
    this.dailyAmounts = const [],
  });

  final double thisWeekAmount;
  final int jobsDone;
  final double rating;

  /// Seven values for Monday through Sunday. Empty uses a neutral
  /// placeholder.
  final List<double> dailyAmounts;

  @override
  Widget build(BuildContext context) {
    final values = dailyAmounts.isEmpty
        ? const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        : dailyAmounts;
    final maxValue =
        values.fold<double>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'THIS WEEK',
                    value: _money(thisWeekAmount),
                    suffix: 'XAF',
                  ),
                ),
                const VerticalDivider(
                  color: AppColors.borderLight,
                  width: 1,
                  thickness: 1,
                ),
                Expanded(
                  child: _Stat(
                    label: 'JOBS DONE',
                    value: jobsDone.toString(),
                  ),
                ),
                const VerticalDivider(
                  color: AppColors.borderLight,
                  width: 1,
                  thickness: 1,
                ),
                Expanded(
                  child: _Stat(
                    label: 'RATING',
                    value: rating.toStringAsFixed(1),
                    showStar: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(
            height: 1,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  Expanded(
                    child: _Bar(
                      value: values[i],
                      maxValue: maxValue,
                      label: _dayLabels[i],
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

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _money(double amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buf.write(',');
      buf.write(rounded[i]);
    }
    return buf.toString();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.suffix,
    this.showStar = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTypography.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 3),
              Text(
                suffix!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (showStar) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.star,
                size: 15,
                color: AppColors.secondary,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.maxValue,
    required this.label,
  });

  final double value;
  final double maxValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isPeak = maxValue > 0 && value == maxValue;
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
    final height = (fraction * 40).clamp(4.0, 44.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 18,
          height: height,
          decoration: BoxDecoration(
            color: isPeak
                ? AppColors.secondary
                : AppColors.primary.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isPeak ? AppColors.secondary : AppColors.textMuted,
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}