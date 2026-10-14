import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

class TrustBlock extends StatelessWidget {
  const TrustBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            l10n.landingTrustTitle,
            textAlign: TextAlign.center,
            style: AppTypography.overline.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TrustRow(
            icon: _TrustIcons.verified,
            label: l10n.landingTrustVerified,
          ),
          const SizedBox(height: AppSpacing.md),
          _TrustRow(
            icon: _TrustIcons.protected,
            label: l10n.landingTrustPayments,
          ),
          const SizedBox(height: AppSpacing.md),
          _TrustRow(
            icon: _TrustIcons.local,
            label: l10n.landingTrustLocal,
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    required this.icon,
    required this.label,
  });

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardLight,
            border: Border.all(
              color: AppColors.primary,
              width: 1,
            ),
          ),
          child: Center(child: icon),
        ),
        const SizedBox(width: AppSpacing.md - AppSpacing.xs / 2),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustIcons {
  static Widget get verified => SizedBox(
        width: 14,
        height: 14,
        child: CustomPaint(painter: _CheckmarkPainter()),
      );

  static Widget get protected => SizedBox(
        width: 14,
        height: 14,
        child: CustomPaint(painter: _ShieldPainter()),
      );

  static Widget get local => SizedBox(
        width: 14,
        height: 14,
        child: CustomPaint(painter: _LocationPainter()),
      );
}

class _CheckmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final checkPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final shield = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..lineTo(size.width * 0.85, size.height * 0.28)
      ..lineTo(size.width * 0.85, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.85,
        size.width * 0.5,
        size.height * 0.95,
      )
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.85,
        size.width * 0.15,
        size.height * 0.55,
      )
      ..lineTo(size.width * 0.15, size.height * 0.28)
      ..close();

    canvas.drawPath(shield, strokePaint);

    final check = Path()
      ..moveTo(size.width * 0.35, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.62)
      ..lineTo(size.width * 0.65, size.height * 0.4);

    canvas.drawPath(check, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final pin = Path()
      ..moveTo(size.width * 0.5, size.height * 0.15)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.15,
        size.width * 0.15,
        size.height * 0.4,
        size.width * 0.15,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.8,
        size.width * 0.5,
        size.height * 0.95,
        size.width * 0.5,
        size.height * 0.95,
      )
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.95,
        size.width * 0.85,
        size.height * 0.8,
        size.width * 0.85,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.4,
        size.width * 0.75,
        size.height * 0.15,
        size.width * 0.5,
        size.height * 0.15,
      )
      ..close();

    canvas.drawPath(pin, strokePaint);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.12,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}