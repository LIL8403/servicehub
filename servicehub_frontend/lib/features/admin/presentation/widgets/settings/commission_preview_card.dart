import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// The live preview calculator card.
///
/// Given a rate (percent) and a test amount, shows how the
/// commission splits.
class CommissionPreviewCard extends StatefulWidget {
  const CommissionPreviewCard({
    super.key,
    required this.ratePercent,
  });

  /// The current rate, expressed as a percentage (e.g. 5.0).
  final double ratePercent;

  @override
  State<CommissionPreviewCard> createState() => _CommissionPreviewCardState();
}

class _CommissionPreviewCardState extends State<CommissionPreviewCard> {
  final _amountController = TextEditingController(text: '10000');

  static const _presets = <int>[5000, 10000, 50000, 150000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _amount {
    final parsed = int.tryParse(_amountController.text.trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  int get _commission => ((_amount * widget.ratePercent) / 100).round();
  int get _net => _amount - _commission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
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
          const SizedBox(height: 20),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: 20),
          _testAmountSection(),
          const SizedBox(height: 20),
          _breakdown(),
          const SizedBox(height: 20),
          _reassuranceBadge(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.calculate_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live preview',
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'See how the current rate affects a hypothetical '
                'payout.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _testAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'TEST AMOUNT',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            for (final p in _presets) ...[
              _presetChip(p),
              if (p != _presets.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                'XAF',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetChip(int value) {
    final label = value >= 1000
        ? '${value ~/ 1000}k'
        : value.toString();
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          setState(() {
            _amountController.text = value.toString();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _breakdown() {
    return Column(
      children: [
        _row('Customer pays (escrow)', _formatXaf(_amount)),
        const SizedBox(height: 12),
        _row(
          'ServiceHUB commission (${widget.ratePercent.toStringAsFixed(2)}%)',
          _formatXaf(_commission),
          valueColor: AppColors.secondary,
          valueWeight: FontWeight.w700,
        ),
        const SizedBox(height: 12),
        _row('Artisan gross release', _formatXaf(_amount)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            height: 1,
            color: AppColors.borderLight.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        _netRow(),
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
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
            color: valueColor ?? AppColors.primary,
            fontWeight: valueWeight ?? FontWeight.w600,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _netRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Artisan net payout',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mobile Money / Bank Transfer',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatXaf(_net),
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _reassuranceBadge() {
    final isZero = widget.ratePercent == 0;
    final bg = isZero ? AppColors.warningTint : AppColors.successTint;
    final fg = isZero ? AppColors.warning : AppColors.success;
    final text = isZero
        ? 'Zero commission mode (0.00%)'
        : 'Calculated using ${widget.ratePercent.toStringAsFixed(2)}% live rate';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isZero ? Icons.info_outline : Icons.check_circle_outline,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatXaf(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';
}