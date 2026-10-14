import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A single-line text input matching the ServiceHUB design system:
/// 48px tall, leading icon, helper text below, navy focus border,
/// red error border + error tint when [errorText] is non-null.
class VerificationTextField extends StatelessWidget {
  const VerificationTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.leadingIcon,
    this.trailingIcon,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: _hasError ? AppColors.error : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          maxLength: maxLength,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: leadingIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md - 4,
                      right: AppSpacing.sm,
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 20,
                      color: _hasError
                          ? AppColors.error
                          : (controller.text.isEmpty
                              ? AppColors.textMuted
                              : AppColors.primary),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: trailingIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(
                      trailingIcon,
                      size: 20,
                      color: _hasError
                          ? AppColors.error
                          : AppColors.textMuted,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: _hasError
                ? AppColors.errorTint
                : (enabled ? AppColors.cardLight : AppColors.bgLight),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.borderLight,
                width: _hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.primary,
                width: _hasError ? 1.5 : 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ] else if (helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              helperText!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}