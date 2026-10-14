import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

enum MetricDeltaTone { positive, warning, negative }

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    required this.delta,
    required this.deltaTone,
    required this.sparklinePoints,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String delta;
  final MetricDeltaTone deltaTone;

  /// Seven points, values in 0..1 normalized to the card's height.
  final List<double> sparklinePoints;

  Color get _deltaColor {
    switch (deltaTone) {
      case MetricDeltaTone.positive:
        return AppColors.success;
      case MetricDeltaTone.warning:
        return AppColors.warning;
      case MetricDeltaTone.negative:
        return AppColors.error;
    }
  }

  IconData get _deltaIcon {
    switch (deltaTone) {
      case MetricDeltaTone.positive:
        return Icons.arrow_upward;
      case MetricDeltaTone.warning:
        return Icons.arrow_upward;
      case MetricDeltaTone.negative:
        return Icons.priority_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 64),
                      child: Text(
                        label.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: value,
                            style: AppTypography.h2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              height: 1.0,
                            ),
                          ),
                          if (unit != null) ...[
                            TextSpan(
                              text: ' ',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: unit,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _deltaIcon,
                          size: 14,
                          color: _deltaColor,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            delta,
                            style: AppTypography.caption.copyWith(
                              color: _deltaColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 60,
              height: 24,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: sparklinePoints,
                  color: AppColors.secondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dx = size.width / (points.length - 1);
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height - (points[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.color != color;
}