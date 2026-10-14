import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_dashboard_repository.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key, required this.days});

  final List<DashboardDay> days;

  @override
  Widget build(BuildContext context) {
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
          _header(),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: days.isEmpty
                ? const Center(
                    child: Text(
                      'No data yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : _chart(),
          ),
          const SizedBox(height: 8),
          _xAxisLabels(),
          const SizedBox(height: 20),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: 16),
          _kpiStrip(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue & requests',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Last ${days.length} days',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        _legend(),
      ],
    );
  }

  Widget _legend() {
    return Row(
      children: [
        _legendEntry(
          line: Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          label: 'Revenue (XAF)',
        ),
        const SizedBox(width: 16),
        _legendEntry(
          line: SizedBox(
            width: 16,
            height: 2,
            child: CustomPaint(
              painter: _DashedLinePainter(color: AppColors.primary),
            ),
          ),
          label: 'Requests',
        ),
      ],
    );
  }

  Widget _legendEntry({required Widget line, required String label}) {
    return Row(
      children: [
        SizedBox(width: 16, height: 12, child: Center(child: line)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _chart() {
    // Compute bounds from the data.
    var maxRevenue = 0.0;
    var maxRequests = 0.0;
    for (final d in days) {
      if (d.revenue > maxRevenue) maxRevenue = d.revenue.toDouble();
      if (d.requests > maxRequests) maxRequests = d.requests.toDouble();
    }
    // Add 20% headroom, avoid zero.
    final revenueMax = maxRevenue == 0 ? 100.0 : maxRevenue * 1.2;
    final requestsMax = maxRequests == 0 ? 5.0 : maxRequests * 1.2;

    // Map requests onto the same Y range as revenue for overlay.
    final scale = revenueMax / requestsMax;

    final revenueSpots = <FlSpot>[
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].revenue.toDouble()),
    ];
    final requestSpots = <FlSpot>[
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].requests.toDouble() * scale),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (days.length - 1).toDouble(),
        minY: 0,
        maxY: revenueMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: revenueMax / 5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.borderLight.withValues(alpha: 0.6),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: revenueMax / 5,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _compactXaf(value.toInt()),
                    textAlign: TextAlign.right,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: revenueSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.secondary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.secondary.withValues(alpha: 0.18),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: requestSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 1.5,
            dashArray: const [4, 4],
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _xAxisLabels() {
    if (days.isEmpty) return const SizedBox.shrink();
    // Show ~7 labels evenly across the range.
    final total = days.length;
    final step = (total / 6).ceil();
    final labels = <String>[];
    for (var i = 0; i < total; i += step) {
      final d = days[i].date;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      labels.add('${months[d.month - 1]} ${d.day}');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final label in labels)
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _kpiStrip() {
    final totalRevenue =
        days.fold<int>(0, (sum, d) => sum + d.revenue);
    final totalRequests =
        days.fold<int>(0, (sum, d) => sum + d.requests);
    final avgRevenue =
        totalRequests == 0 ? 0 : (totalRevenue / totalRequests).round();
    final avgPerDay = days.isEmpty ? 0 : (totalRequests / days.length);

    return Row(
      children: [
        Expanded(
          child: _kpiTile('AVG REVENUE / REQUEST', _formatXaf(avgRevenue)),
        ),
        Expanded(
          child: _kpiTile(
            'AVG REQUESTS / DAY',
            avgPerDay.toStringAsFixed(1),
          ),
        ),
        Expanded(
          child: _kpiTile('TOTAL REQUESTS', '$totalRequests'),
        ),
      ],
    );
  }

  Widget _kpiTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  String _compactXaf(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return '$value';
  }

  String _formatXaf(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dash = 3.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dash).clamp(0, size.width), size.height / 2),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color;
}