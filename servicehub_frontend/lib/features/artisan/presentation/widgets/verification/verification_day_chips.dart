import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A 7-day availability strip: M T W T F S S.
///
/// [availableDays] is a set of lowercase weekday names: "monday",
/// "tuesday", etc. Days in the set render with a success tint; days
/// not in the set render muted.
class VerificationDayChips extends StatelessWidget {
  const VerificationDayChips({super.key, required this.availableDays});

  final Set<String> availableDays;

  static const _order = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_order.length, (i) {
        final isActive = availableDays.contains(_order[i]);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.successTint
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _initials[i],
                  style: AppTypography.caption.copyWith(
                    color: isActive
                        ? AppColors.success
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}