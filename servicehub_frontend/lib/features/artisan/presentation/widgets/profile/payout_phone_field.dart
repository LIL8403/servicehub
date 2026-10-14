import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A specialized phone input for the artisan's payout number.
///
/// The backend requires `2376XXXXXXXX` — Cameroon country code,
/// the digit 6, then 8 more digits. Artisans will type the local
/// form (`6XXXXXXXX`), so this widget:
///   - Auto-prefixes `237` when the user hasn't typed it
///   - Shows the prefix as a non-editable chip
///   - Only accepts digits for the local part
///   - Returns the full E.164-style string on change
class PayoutPhoneField extends StatefulWidget {
  const PayoutPhoneField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  /// The current stored value, e.g. `237677123456` or null.
  final String? initialValue;

  /// Emits the full `2376XXXXXXXX` string, or null when cleared.
  final ValueChanged<String?> onChanged;

  @override
  State<PayoutPhoneField> createState() => _PayoutPhoneFieldState();
}

class _PayoutPhoneFieldState extends State<PayoutPhoneField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Strip the country code + network digit so the user only
    // sees the 8 digits they need to enter.
    _controller = TextEditingController(text: _localPart(widget.initialValue));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extracts the 8 digits after `2376`. Returns an empty string
  /// when the input doesn't match the expected shape.
  String _localPart(String? value) {
    if (value == null || value.isEmpty) return '';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('2376')) {
      return digits.substring(4);
    }
    // Fallback: strip anything longer than 8 digits.
    return digits.length > 8 ? digits.substring(digits.length - 8) : digits;
  }

  void _emit() {
    final local = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (local.isEmpty) {
      widget.onChanged(null);
      return;
    }
    if (local.length != 8) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged('2376$local');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+237 6',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  onChanged: (_) {
                    _emit();
                    setState(() {});
                  },
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '77 123 456',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cameroon mobile number. Earnings will be transferred here via '
          'MTN Mobile Money or Orange Money.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
