import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_dashboard_repository.dart';

class StatusDonut extends StatelessWidget {
  const StatusDonut({
    super.key,
    required this.segments,
    required this.topServices,
  });

  final List<DashboardDonutSegment> segments;
  final List<({String name, int count})> topServices;

  static const _palette = <Color>[
    Color(0xFF166534), // completed
    AppColors.secondary, // in progress
    Color(0xFFB45309), // awaiting confirmation
    Color(0xFFB91C1C), // cancelled
    Color(0xFF64748B), // other
  ];

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.value);

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Requests by status',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'All time',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: total == 0 ? _emptyChart() : _donut(total),
          ),
          const SizedBox(height: 20),
          _legend(total),
          if (topServices.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
            ),
            const SizedBox(height: 16),
            _topServicesBlock(),
          ],
        ],
      ),
    );
  }

  Widget _emptyChart() {
    return Center(
      child: Text(
        'No requests yet',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _donut(int total) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 58,
            startDegreeOffset: -90,
            sections: [
              for (var i = 0; i < segments.length; i++)
                if (segments[i].value > 0)
                  PieChartSectionData(
                    value: segments[i].value.toDouble(),
                    color: _palette[i % _palette.length],
                    radius: 18,
                    showTitle: false,
                  ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$total',
              style: AppTypography.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'TOTAL',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(int total) {
    return Column(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _palette[i % _palette.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  segments[i].label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                total == 0
                    ? '0%'
                    : '${((segments[i].value / total) * 100).round()}%',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (i < segments.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _topServicesBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TOP SERVICES',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        for (final s in topServices) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  s.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${s.count} requests',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (s != topServices.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}