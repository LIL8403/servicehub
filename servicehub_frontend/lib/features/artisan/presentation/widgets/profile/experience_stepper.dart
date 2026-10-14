import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A large numeric display with minus/plus buttons for adjusting
/// years of experience. Bounded to [min]–[max].
class ExperienceStepper extends StatelessWidget {
  const ExperienceStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 60,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  bool get _canDecrement => value > min;
  bool get _canIncrement => value < max;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 32,
            height: 1.0,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'years',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const Spacer(),
        _StepButton(
          icon: Icons.remove,
          onPressed: _canDecrement ? () => onChanged(value - 1) : null,
          primary: false,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StepButton(
          icon: Icons.add,
          onPressed: _canIncrement ? () => onChanged(value + 1) : null,
          primary: true,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
    required this.primary,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final bg = primary
        ? AppColors.primary
        : AppColors.cardLight;
    final fg = primary
        ? AppColors.textInverse
        : (enabled ? AppColors.primary : AppColors.textMuted);

    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: primary
                  ? null
                  : Border.all(color: AppColors.borderLight),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: fg),
          ),
        ),
      ),
    );
  }
}