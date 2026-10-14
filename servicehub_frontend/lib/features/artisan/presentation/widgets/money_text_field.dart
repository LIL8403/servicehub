import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

/// A form field for entering a XAF amount. Formats the number with
/// thousand separators as the user types and returns the parsed double.
///
/// Stateful because the text controller must persist across rebuilds —
/// creating a new one in build() would wipe the input on every keystroke.
class MoneyTextField extends StatefulWidget {
  const MoneyTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.initialValue,
    this.helperText,
  });

  final String label;
  final String hint;
  final ValueChanged<double> onChanged;
  final double? initialValue;
  final String? helperText;

  @override
  State<MoneyTextField> createState() => _MoneyTextFieldState();
}

class _MoneyTextFieldState extends State<MoneyTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.initialValue != null && widget.initialValue! > 0)
          ? _format(widget.initialValue!.round().toString())
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'XAF',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (value) {
            final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
            final parsed = double.tryParse(digits) ?? 0;
            widget.onChanged(parsed);

            // Re-format with separators, preserving the cursor at the end.
            final formatted = digits.isEmpty ? '' : _format(digits);
            if (formatted != value) {
              _controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(
                  offset: formatted.length,
                ),
              );
            }
          },
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.cardLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.borderLg,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.borderLg,
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  String _format(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}