import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_platform_settings_repository.dart';

/// The main settings card for the commission rate.
class CommissionFormCard extends StatefulWidget {
  const CommissionFormCard({
    super.key,
    required this.currentSettings,
    required this.onRateChanged,
    required this.onSubmit,
    required this.isSaving,
  });

  final CommissionSettings currentSettings;

  /// Fires whenever the rate input changes (for the preview).
  final ValueChanged<double> onRateChanged;

  /// Fires when the admin clicks "Save changes".
  /// Passes (rate as decimal, reason).
  final void Function(double rate, String reason) onSubmit;

  final bool isSaving;

  @override
  State<CommissionFormCard> createState() => _CommissionFormCardState();
}

class _CommissionFormCardState extends State<CommissionFormCard> {
  final _rateController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rateController.text = widget.currentSettings.ratePercent.toStringAsFixed(
      2,
    );
    _rateController.addListener(_onRateInput);
    _reasonController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(CommissionFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync if the underlying settings change (e.g. after save)
    if (oldWidget.currentSettings.rate != widget.currentSettings.rate &&
        _rateController.text.isEmpty) {
      _rateController.text = widget.currentSettings.ratePercent.toStringAsFixed(
        2,
      );
    }
  }

  @override
  void dispose() {
    _rateController.removeListener(_onRateInput);
    _rateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// The raw value the admin typed, without clamping.
  double? get _rawRatePercent {
    final text = _rateController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// The clamped value for display purposes. Null if the raw input
  /// is not a valid number.
  double get _ratePercent {
    final raw = _rawRatePercent;
    if (raw == null) return 0.0;
    return raw.clamp(0.0, 30.0);
  }

  double get _rateDecimal => _ratePercent / 100.0;

  /// True when the raw input is a valid number AND within bounds.
  bool get _rateInBounds {
    final raw = _rawRatePercent;
    if (raw == null) return false;
    return raw >= widget.currentSettings.minPercent &&
        raw <= widget.currentSettings.maxPercent;
  }

  bool get _reasonValid => _reasonController.text.trim().length >= 5;

  bool get _rateChanged {
    final current = widget.currentSettings.ratePercent;
    return (_ratePercent - current).abs() > 0.005;
  }

  bool get _canSubmit =>
      _rateInBounds && _reasonValid && _rateChanged && !widget.isSaving;

  void _onRateInput() {
    setState(() {});
    widget.onRateChanged(_ratePercent);
  }

  void _onReset() {
    _rateController.text = widget.currentSettings.ratePercent.toStringAsFixed(
      2,
    );
    _reasonController.clear();
    widget.onRateChanged(_ratePercent);
  }

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
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
          const SizedBox(height: 20),
          _rateInput(),
          const SizedBox(height: 24),
          _warningBlock(),
          const SizedBox(height: 20),
          _reasonField(),
          const SizedBox(height: 20),
          _actionRow(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.percent, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Commission rate',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Applied to every artisan payout',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'RATE',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _rateInBounds ? AppColors.borderLight : AppColors.error,
            ),
          ),
          child: Row(
            children: [
              const Text(
                '%',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTypography.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                '%',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _rawRatePercent == null
                    ? 'Enter a number.'
                    : (_rateInBounds
                          ? 'Enter a percentage between '
                                '${widget.currentSettings.minPercent.toStringAsFixed(2)} '
                                'and '
                                '${widget.currentSettings.maxPercent.toStringAsFixed(2)}.'
                          : 'Value must be between '
                                '${widget.currentSettings.minPercent.toStringAsFixed(2)} '
                                'and '
                                '${widget.currentSettings.maxPercent.toStringAsFixed(2)}.'),
                style: AppTypography.caption.copyWith(
                  color: _rateInBounds ? AppColors.textMuted : AppColors.error,
                  fontWeight: _rateInBounds ? FontWeight.w500 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              'Current: ${widget.currentSettings.ratePercent.toStringAsFixed(2)}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _warningBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Changes affect new payments only',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The current rate is frozen on each payment at the '
                  'moment it is created. Existing payments keep their '
                  'original rate even after you change this setting.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'REASON FOR CHANGE',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'Required',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          minLines: 3,
          maxLength: 2000,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontSize: 13,
            height: 1.5,
          ),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            hintText:
                'Explain why this rate is being changed. Minimum 5 '
                'characters. This is recorded in the audit log.',
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.cardLight,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_reasonController.text.length} / 2000',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Changes are recorded in the audit log.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
        TextButton(
          onPressed: widget.isSaving ? null : _onReset,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 40),
          ),
          child: Text(
            'Reset',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _canSubmit
              ? () =>
                    widget.onSubmit(_rateDecimal, _reasonController.text.trim())
              : null,
          icon: widget.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.disabledBg,
            disabledForegroundColor: AppColors.disabledText,
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
    );
  }
}
